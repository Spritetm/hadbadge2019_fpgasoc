#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "mach_defines.h"
#include "sdk.h"
#include "gfx_load.h"
#include "cache.h"

//The bgnd.png image got linked into the binary of this app, and these two chars are the first
//and one past the last byte of it.
extern char _binary_sega_tileset_png_start;
extern char _binary_sega_tileset_png_end;

//Pointer to the framebuffer memory.
uint8_t *fbmem;

#define FB_WIDTH 512
#define FB_HEIGHT 320

#define FB_PAL_OFFSET 256

extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]
extern volatile uint32_t GFXREG[];
#define GFX_REG(i) GFXREG[(i)/4]

uint32_t *GFXSPRITES = (uint32_t *)0x5000C000;

//Used to debounce buttons
#define BUTTON_READ_DELAY		15

//Borrowed this from lcd.c until a better solution comes along :/
static void __INEFFICIENT_delay(int n) {
	for (int i=0; i<n; i++) {
		for (volatile int t=0; t<(1<<11); t++);
	}
}

//Wait until all buttons are released
static inline void __button_wait_for_press() {
	while (MISC_REG(MISC_BTN_REG) == 0);
}

//Wait until all buttons are released
static inline void __button_wait_for_release() {
	while (MISC_REG(MISC_BTN_REG));
}

static inline void __sprite_set(int index, int x, int y, int size_x, int size_y, int tile_index, int palstart) {
	x+=64;
	y+=64;
	GFXSPRITES[index*2]=(y<<16)|x;
	GFXSPRITES[index*2+1]=size_x|(size_y<<8)|(tile_index<<16)|((palstart/4)<<25);
}

//Helper function to set a tile on layer a
static inline void __tile_a_set(uint8_t x, uint8_t y, uint32_t index) {
	GFXTILEMAPA[y*GFX_TILEMAP_W+x] = index;
}

//Helper function to set a tile on layer b
static inline void __tile_b_set(uint8_t x, uint8_t y, uint32_t index) {
	GFXTILEMAPB[y*GFX_TILEMAP_W+x] = index;
}

//Helper function to move tile layer 1
static inline void __tile_a_translate(int dx, int dy) {
	GFX_REG(GFX_TILEA_OFF)=(dy<<16)+(dx &0xffff);
}

//Helper function to move tile layer b
static inline void __tile_b_translate(int dx, int dy) {
	GFX_REG(GFX_TILEB_OFF)=(dy<<16)+(dx &0xffff);
}

uint32_t counter60hz(void) {
	return GFX_REG(GFX_VBLCTR_REG);
}

void main(int argc, char **argv) {
	//Allocate framebuffer memory
	fbmem=malloc(320*512/2);

	for (uint8_t i=0; i<16;i++) {
		MISC_REG(MISC_LED_REG)=(i<<i);
		__INEFFICIENT_delay(100);
	}


	//Set up the framebuffer address.
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)fbmem)&0xFFFFFF;
	//We're going to use a pitch of 512 pixels, and the fb palette will start at 256.
	GFX_REG(GFX_FBPITCH_REG)=(FB_PAL_OFFSET<<GFX_FBPITCH_PAL_OFF)|(512<<GFX_FBPITCH_PITCH_OFF);
	//Blank out fb while we're loading stuff.
	GFX_REG(GFX_LAYEREN_REG)=0;

	//Load up the default tileset and font.
	//ToDo: loading pngs takes a long time... move over to pcx instead.
	printf("Loading tiles...\n");
	int gfx_tiles_err = gfx_load_tiles_mem(GFXTILES, &GFXPAL[0], &_binary_sega_tileset_png_start, (&_binary_sega_tileset_png_end-&_binary_sega_tileset_png_start));
	printf("Tiles initialized err=%d\n", gfx_tiles_err);


	//The IPL leaves us with a tileset that has tile 0 to 127 map to ASCII characters, so we do not need to
	//load anything specific for this. In order to get some text out, we can use the /dev/console device
	//that will use these tiles to put text in a tilemap. It uses escape codes to do so, see
	//ipl/gloss/console_out.c for more info.
	//Note that without the setvbuf command, no characters would be printed until 1024 characters are
	//buffered.
	console=fopen("/dev/console", "w");
	setvbuf(console, NULL, _IOLBF, 1024); //make console line buffered
	if (console==NULL) {
		printf("Error opening console!\n");
	}

	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//we tell it to start writing from entry 0.
	//PAL offset changes the colors that the 16-bit png maps to?
	//gfx_load_fb_mem(fbmem, &GFXPAL[FB_PAL_OFFSET], 4, 512, &_binary_badgetris_bgnd_png_start, (&_binary_badgetris_bgnd_png_end-&_binary_badgetris_bgnd_png_start));

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	//Copied from IPL not sure why yet
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEB|GFX_LAYEREN_TILEA|GFX_LAYEREN_SPR;
	GFXPAL[FB_PAL_OFFSET+0x100]=0x00ff00ff; //Note: For some reason, the sprites use this as default bgnd. ToDo: fix this...
	GFXPAL[FB_PAL_OFFSET+0x1ff]=0x40ff00ff; //so it becomes this instead.

	//This makes sure not to read button still pressed from badge menu selection
	__button_wait_for_release();

	//Set map to tilemap B, clear tilemap, set attr to 0
	//Not sure yet what attr does, but tilemap be is important as it will have the effect of layering
	//on top of our scrolling game
	fprintf(console, "\0331M\033C\0330A\n");
	//Note that without the newline at the end, all printf's would stay in the buffer.


	//Clear both tilemaps
	memset(GFXTILEMAPA,0,0x4000);
	memset(GFXTILEMAPB,0,0x4000);
	//Clear sprites that IPL may have loaded
	memset(GFXSPRITES,0,0x4000);

	//The user can still see nothing of this graphics goodness, so let's re-enable the framebuffer and
	//tile layer A (the default layer for the console).
	//Normal FB enabled (vice 8 bit) because background is loaded into the framebuffer above in 4 bit mode.
	//TILEA is where text is printed by default
	 GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEA|GFX_LAYEREN_TILEB|GFX_LAYEREN_SPR;

	/********************************************************************************
	 * Put your user code in there, return when it's time to exit back to bage menu *
	 * *****************************************************************************/
	uint8_t tilegrid_width = 30;
	uint8_t tilegrid_height = 20;

	uint8_t horizontal_index = 15;
	uint8_t vertical_index = 10;

	//Draw top tilelayer
	for (uint8_t x=0; x<30; x++) {
		for (uint8_t y=0; y<20; y++) {
			__tile_b_set(x,y,235);
		}
	}
	for (uint8_t x=0; x<16; x++) {
		__tile_b_set(x+1,5,128+x);
		__tile_b_set(x+1,6,144+x);
		__tile_b_set(x+1,7,160+x);
		__tile_b_set(x+1,8,176+x);
	}
	for (uint8_t x=0; x<12; x++) {
		__tile_b_set(x+17,5,192+x);
		__tile_b_set(x+17,6,208+x);
		__tile_b_set(x+17,7,224+x);
		__tile_b_set(x+17,8,240+x);
	}
	//14 9 Supercon location
	for (uint8_t x=0; x<11; x++) {
		__tile_b_set(x+9,14,256+x);
		__tile_b_set(x+9,15,272+x);
	}

	//Set tilelayers for color animation
	//64 wide isn't enough so we'll make two rows,
	//one with white, one with blue, and swap them midway through
	//Colortiles: 235, 204, 205, 206, 207, 220
	for (uint8_t i=0; i<64; i++) {
		for (uint8_t y=0; y<4; y++) {
			__tile_a_set(i,y+5,220);
			__tile_a_set(i,y+9,235);
		}
	}
	for (uint8_t i=0; i<4; i++) {
		for (uint8_t y=0; y<4; y++) {
			__tile_a_set(51-i,y+5,207);
			__tile_a_set(55-i,y+5,206);
			__tile_a_set(59-i,y+5,205);
			__tile_a_set(63-i,y+5,204);

			__tile_a_set(51-i,y+9,207);
			__tile_a_set(55-i,y+9,206);
			__tile_a_set(59-i,y+9,205);
			__tile_a_set(63-i,y+9,204);
		}
	}
	for (uint8_t i=32; i<48; i++) {
		for (uint8_t y=0; y<4; y++) {
			__tile_a_set(i,y+9,220);
		}
	}

	uint32_t x_layera = 0;
	uint32_t y_layera = 4096;
	uint16_t loopcounter = 0;
	__tile_a_translate(x_layera,4096);
	while(1)
	{
		__INEFFICIENT_delay(600);

		while(loopcounter++ < 736) {
			if (loopcounter > 480) {
				//Move to blue array as white is no longer showing
				y_layera = 0;
			}
			x_layera -= 64;
			__tile_a_translate(x_layera,y_layera);
			if ((MISC_REG(MISC_BTN_REG) & BUTTON_SELECT)) {	return;	}
			__INEFFICIENT_delay(1);
		}

		__INEFFICIENT_delay(800);
		return;
	}
}