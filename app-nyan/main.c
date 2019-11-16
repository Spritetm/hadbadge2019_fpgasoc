#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "mach_defines.h"
#include "sdk.h"
#include "gfx_load.h"
#include "cache.h"
#include "libsynth.h"
#include "synth_utils.h"
#include "libmidi.h"
#include "ID-Nyan_Cat.h"

//The bgnd.png image got linked into the binary of this app, and these two chars are the first
//and one past the last byte of it.
extern char _binary_nyan_png_start;
extern char _binary_nyan_png_end;

extern uint32_t GFXSPRITES[];


void set_sprite(int no, int x, int y, int sx, int sy, int tileno, int palstart) {
	x+=64;
	y+=64;
	GFXSPRITES[no*2]=(y<<16)|x;
	GFXSPRITES[no*2+1]=sx|(sy<<8)|(tileno<<16)|((palstart/4)<<25);
}


#define NO_STARS 64
typedef struct {
	int pos;
	int ctr;
} star_t;


void main(int argc, char **argv) {
	//Blank out fb while we're loading stuff by disabling all layers. This just shows the background color.
	GFX_REG(GFX_BGNDCOL_REG)=0x202020; //a soft gray
	GFX_REG(GFX_LAYEREN_REG)=0; //disable all gfx layers
	
	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//we tell it to start writing from entry 128.
	int png_size=(&_binary_nyan_png_end-&_binary_nyan_png_start);
	int i=gfx_load_tiles_mem(GFXTILES, &GFXPAL[0], &_binary_nyan_png_start, png_size);
	if (i) printf("gfx_load_tiles_mem: error %d\n", i);
	
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_TILEB|GFX_LAYEREN_SPR;
	GFXPAL[0x1ff]=0x00ff00ff; //Color the sprite layer uses when no sprites are drawn - 100% transparent.

	while (MISC_REG(MISC_BTN_REG)) ;

	//Erase tilemap
	for (int x=0; x<64*64; x++) GFXTILEMAPB[x]=190;

	star_t star[NO_STARS];
	for (int i=0; i<NO_STARS; i++) {
		star[i].pos=rand()&4095;
		star[i].ctr=rand()%5;
	}

	//Scale tile layer 3 to embiggen it
	GFX_REG(GFX_TILEB_INC_COL)=(0<<16)+((64/2)&0xffff);
	GFX_REG(GFX_TILEB_INC_ROW)=((64/2)<<16)+(0&0xffff);

	synth_init(4);

	//Loop until button A is pressed
	while ((MISC_REG(MISC_BTN_REG) & BUTTON_A)==0) {
		uint32_t cur_vbl_ctr=GFX_REG(GFX_VBLCTR_REG);

		GFX_REG(GFX_TILEB_OFF)=(cur_vbl_ctr*128)&0xffff;

		if ((cur_vbl_ctr&7)==0) {
			for (int i=0; i<NO_STARS; i++) {
				star[i].ctr++;
				if (star[i].ctr>=5) star[i].ctr=0;
				const int star_tile[5]={124, 125, 126, 127, 190};
				GFXTILEMAPB[star[i].pos]=star_tile[star[i].ctr];
			}
		}

		int nyan_fr=(cur_vbl_ctr/4)%12;
		int twiddle_fr=(cur_vbl_ctr/32)%12;
		int i=0;

		for (int y=0; y<2; y++) {
			for (int x=0; x<5; x++) {
				set_sprite(i++, x*16*3, y*16*4+100, 16*3, 16*4, 60+y+((twiddle_fr+x)&1)*2, 0);
			}
		}
		for (int y=0; y<3; y++) {
			for (int x=0; x<5; x++) {
				set_sprite(i++, x*16*3+150, y*16*3+100, 16*3, 16*3, nyan_fr*5+x+64*y, 0);
			}
		}

		// Add in music:
		midi_play_song(nyan, sizeof(nyan)/sizeof(uint16_t)/3 , BPM(120));

		while (GFX_REG(GFX_VBLCTR_REG) <= cur_vbl_ctr);
	}
	midi_reset();
}
