#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

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
static FILE *console;

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

	// Turn off top row LEDs
	MISC_REG(MISC_LED_REG)=0;

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

	/********************************************************************************
	 * Put your user code in there, return when it's time to exit back to bage menu *
	 * *****************************************************************************/
	uint8_t tilegrid_width = 30;
	uint8_t tilegrid_height = 20;

	uint8_t horizontal_pos = 3;
	uint8_t vertical_pos = 8;
	uint8_t x_offset = 0;

	// Fill top tilelayer with blank white, some will be overwritten layer.
	for (uint8_t x=0; x<30; x++) {
		for (uint8_t y=0; y<20; y++) {
			__tile_b_set(x,y,200); // Tile 200 = white
		}
	}

	// Draw top tilelayer transparency elements
	for (uint8_t x=0; x<16; x++) {
		x_offset = x+horizontal_pos;
		__tile_b_set(x_offset,vertical_pos,128+x);
		__tile_b_set(x_offset,vertical_pos+1,144+x);
		__tile_b_set(x_offset,vertical_pos+2,160+x);
		__tile_b_set(x_offset,vertical_pos+3,176+x);
	}
	for (uint8_t x=0; x<8; x++) {
		x_offset = x+16+horizontal_pos;
		__tile_b_set(x_offset,vertical_pos,192+x);
		__tile_b_set(x_offset,vertical_pos+1,208+x);
		__tile_b_set(x_offset,vertical_pos+2,224+x);
		__tile_b_set(x_offset,vertical_pos+3,240+x);
	}

	// Draw animated tilelayer with items to show through transparent parts

	// Top 4 rows to white, center will receive teal bar shortly.
	for (uint8_t x=0; x<64; x++) {
		for (uint8_t y=0; y<4; y++) {
			__tile_a_set(x,y,200); // Tile 200 = white
		}	
	}

	// Teal bar in middle of top two (now white) rows
	for (uint8_t y=0; y<4; y++) {
		__tile_a_set(31,y,202); // Tile 202 = Teal gradient left
		__tile_a_set(32,y,203); // Tile 203 = Teal gradient right
	}

	// After teal bar sweeps, use these bars to fade in/out blue.
	for (uint8_t x=0; x<64; x++) {
		// Rows 4-7 to 25% blue
		for (uint8_t y=4; y<8; y++) {
			__tile_a_set(x,y,216); // 216 = 25% blue
		}
		// Rows 8-11 to 50% blue
		for (uint8_t y=8; y<12; y++) {
			__tile_a_set(x,y,217); // 217 = 50% blue
		}
		// Rows 12-15 to 75% blue
		for (uint8_t y=12; y<16; y++) {
			__tile_a_set(x,y,218); // 218 = 75% blue
		}
		// Rows 16-19 to 100% blue
		for (uint8_t y=16; y<20; y++) {
			__tile_a_set(x,y,218); // 219 = 100% blue
		}
	}

	int16_t x_translate= 64 * 16 * tilegrid_width;
	int16_t y_translate=-64 * 16 * vertical_pos;
	__tile_a_translate(x_translate,y_translate);

	// Tiles are set up, we can now enable.
	 GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_TILEA|GFX_LAYEREN_TILEB;

	// Wait a bit before starting the show
	__INEFFICIENT_delay(500);

	int16_t step_size = 64;
	// Teal bar sweeps right
	for (uint16_t count=0; count<(64*16*tilegrid_width); count+=step_size) {
		__tile_a_translate(x_translate-count,y_translate);
		__INEFFICIENT_delay(1);
	}
	// Wait...
	__INEFFICIENT_delay(100);

	// Then fade in blue bars
	for (uint8_t fade=1; fade <= 4; fade++) {
		__tile_a_translate(x_translate,y_translate+64*16*4*fade);
		__INEFFICIENT_delay(50);
	}
	__INEFFICIENT_delay(1000);
}