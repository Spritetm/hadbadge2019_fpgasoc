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
#include "lodepng/lodepng.h"
#include "gfx_load.h"


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
	free(decoded);
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
	free(decoded);
	return 0;
}
