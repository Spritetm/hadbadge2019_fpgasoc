/*
 * Copyright 2019 Jeroen Domburg <jeroen@spritesmods.com>
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software.  If not, see <https://www.gnu.org/licenses/>.
 */
#include <stdlib.h>
#include <stdio.h>
#include "lodepng/lodepng.h"
#include "gfx_load.h"
#include "user_memfn.h"
#include "yxml/yxml.h"
#include "mach_defines.h"

static void set_tmx_tilemap_ent(uint32_t *tilemap, int tilemaph, int tilemapw, int tx, int ty, int tileval, int palstart) {
	if (tx<tilemapw && ty<tilemaph) {
		int tileno=tileval&0xfffffff;
		//Note: tiled stores tiles starting from 1; 0 is an empty tile. We start from 0, and
		//map an empty (or invalid) tile to tile 0.
		if (tileno>1 || tileno<=512) {
			tileno=tileno-1;
		} else {
			tileno=0;
		}
		//Set palette offset and map tiled flip/rotate bits to hw flip/rotate bits.
		int attr=(palstart>>3)<<GFX_TILEMAP_ENT_PAL_OFF;
		if (tileval&(1<<31)) attr|=GFX_TILEMAP_ENT_FLIP_X;
		if (tileval&(1<<30)) attr|=GFX_TILEMAP_ENT_FLIP_Y;
		if (tileval&(1<<29)) attr|=GFX_TILEMAP_ENT_SWAP_XY;
		if (attr!=0) printf("attr %x\n", attr);
		//Set the tile.
		tilemap[ty*tilemaph+tx]=tileno|attr;
	}
}


#define YXML_BUF_SIZE 2048

int gfx_load_tilemap_mem(uint32_t *tilemap, int tilemaph, int tilemapw, int layerid, const char *tilemapstr, int tilemaplen, int palstart) {
	void *buf=malloc(YXML_BUF_SIZE);
	char attrval[128];
	if (buf==NULL) return 0;
	yxml_t yx;
	yxml_init(&yx, buf, YXML_BUF_SIZE);
	yxml_ret_t r;
	int curr_layer=-1;
	int tmapfilew, tmapfileh, tx, ty;
	int getting_data=0;
	int curtile;
	int tmpos;
	for (const char *p=tilemapstr; (*p!=0 && (tilemaplen<0 || p<tilemapstr+tilemaplen)); p++) {
		r=yxml_parse(&yx, *p);
		if (r<0) {
			fprintf(stderr, "yxml_parse: error %d at character %d\n", r, p-tilemapstr);
			break; //error
		}
		if (r==YXML_ATTRSTART) {
			attrval[0]=0;
		} else if (r==YXML_ATTRVAL) {
			strncat(attrval, yx.data, sizeof(attrval)-1);
			attrval[sizeof(attrval)-1]=0;
		} else if (r==YXML_ATTREND) {
			//sprintf(stderr, "Element %s attr %s val %s\n", yx.elem, yx.attr, attrval);
			if ((strcmp(yx.elem, "layer")==0) && strcmp(yx.attr, "id")==0) {
				curr_layer=atoi(attrval);
			} else if ((strcmp(yx.elem, "layer")==0) && strcmp(yx.attr, "width")==0) {
				tmapfilew=atoi(attrval);
			} else if ((strcmp(yx.elem, "layer")==0) && strcmp(yx.attr, "height")==0) {
				tmapfileh=atoi(attrval);
			} else if ((strcmp(yx.elem, "data")==0) && strcmp(yx.attr, "encoding")==0) {
				if (strcmp(attrval, "csv")==0) {
					getting_data=1;
					curtile=0;
					tx=0; ty=0;
				} else {
					fprintf(stderr, "gfx_load_tiles: tilemap has encoding %s, should be csv!\n", attrval);
				}
			}
		} else if (r==YXML_CONTENT && strcmp(yx.elem, "data")==0) {
			if (getting_data) {
				for (char *c=yx.data; *c!=0; c++) {
					if (*c<='9' && *c>='0') {
						curtile=(curtile*10)+(*c-'0');
					} else if (*c==',') {
						set_tmx_tilemap_ent(tilemap, tilemaph, tilemapw, tx, ty, curtile, palstart);
						curtile=0;
						tx++;
						if (tx>=tmapfilew) {
							tx=0;
							ty++;
						}
					}
				}
			}
		} else if (r==YXML_ELEMEND && strcmp(yx.elem, "data")==0) {
			if (getting_data) {
				//final entry of csv does not have comma appended, so it's not written yet.
				set_tmx_tilemap_ent(tilemap, tilemaph, tilemapw, tx, ty, curtile, palstart);
				getting_data=0;
			}
		}
	}
	free(buf);
	return (r>=0);
}

int gfx_load_fb_mem(uint8_t *fbmem, uint32_t *palmem, int fbbpp, int pitch, char *pngstart, int pnglen) {
	unsigned char *decoded=NULL;
	unsigned int w=0, h=0;
	if (fbbpp!=8 && fbbpp!=4) return -1;
	LodePNGState st={0};
	lodepng_state_init(&st);
	st.decoder.color_convert=0;
	st.info_raw.colortype=LCT_PALETTE;
	st.info_raw.bitdepth=fbbpp;
	st.info_raw.palette=NULL;
	st.info_raw.palettesize=0;
	int i=lodepng_decode(&decoded, &w, &h, &st, pngstart, pnglen);
	if (i!=0) return i;
	unsigned char *p=decoded;
	for (int i=0; i<st.info_png.color.palettesize; i++) {
		int p=0;
		p=st.info_png.color.palette[i*4];
		p|=st.info_png.color.palette[i*4+1]<<8;
		p|=st.info_png.color.palette[i*4+2]<<16;
		p|=st.info_png.color.palette[i*4+3]<<24;
		palmem[i]=p;
	}
	if (fbbpp==8) {
		for (int y=0; y<h; y++) {
			for (int x=0; x<w; x++) {
				fbmem[x+y*pitch]=png_resolve_pixel(decoded, x,y,w,h,st.info_png.color.bitdepth);
			}
		}
	} else { //bpp=4
		for (int y=0; y<h; y++) {
			for (int x=0; x<w; x+=2) {
				int v;
				v=png_resolve_pixel(decoded, x,y,w,h,st.info_png.color.bitdepth);
				v|=png_resolve_pixel(decoded, x+1,y,w,h,st.info_png.color.bitdepth)<<4;
				fbmem[(x+y*pitch)/2]=v;
			}
		}
	}
	lodepng_state_cleanup(&st);
	user_memfn_free(decoded);
	return 0;
}

int gfx_load_tiles_mem(uint32_t *tilemem, uint32_t *palettemem, char *pngstart, int pnglen) {
	unsigned char *decoded;
	unsigned int w, h;
	LodePNGState st={0};
	lodepng_state_init(&st);
	st.decoder.color_convert=0;
	st.info_raw.colortype=LCT_PALETTE;
	st.info_raw.bitdepth=8;
	st.info_raw.palette=NULL;
	st.info_raw.palettesize=0;
	int i=lodepng_decode(&decoded, &w, &h, &st, pngstart, pnglen);
	if (i!=0) return i;
	int palct=st.info_png.color.palettesize;
	for (int i=0; i<palct; i++) {
		int p=0;
		p=st.info_png.color.palette[i*4];
		p|=st.info_png.color.palette[i*4+1]<<8;
		p|=st.info_png.color.palette[i*4+2]<<16;
		p|=st.info_png.color.palette[i*4+3]<<24;
		palettemem[i]=p;
	}
	//Loop over all the tiles and dump the 16x16 pictures in tilemem.
	int tx=0, ty=0;
	int t=0;
	while (ty+15<h) {
		for (int y=0; y<16; y++) {
			uint64_t tp;
			for (int x=0; x<16; x++) {
				int c=png_resolve_pixel(decoded, x+tx,y+ty,w,h,st.info_png.color.bitdepth);;
				if (c>15) c=0;
				tp=(tp>>4)|((uint64_t)c<<60UL);
			}
			tilemem[t++]=tp;
			tilemem[t++]=tp>>32;
		}
		tx+=16;
		if (tx+15>w) {
			tx=0;
			ty+=16;
		}
	}
	lodepng_state_cleanup(&st);
	user_memfn_free(decoded);
	return 0;
}
