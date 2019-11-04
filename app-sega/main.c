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

// Tile grid constants
#define TILEGRID_WIDTH 30
#define TILEGRID_HEIGHT 20

// Tileset indices for SEGA
#define SEGA_VERTICAL_POS 	8
#define SEGA_HORIZONTAL_POS 3
#define TILE_SEGA_ROW1 		0x00
#define TILE_SEGA_ROW2 		TILE_SEGA_ROW1+0x40
#define TILE_WHITE 			TILE_SEGA_ROW1+0x38 // Reusing a tile from "P" in "SUPERCON" that happens to be all white.
#define TILE_SEGA_CYAN 		TILE_SEGA_ROW2+0x08
#define PAL_SEGA_CYAN 		0 // Warning: palette index may shift as tileset picks up additional elements and colors.

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
	uint8_t x_offset = 0;
	uint8_t y_offset = 0;
	uint8_t tile_index = 0;

	// Fill top tilelayer B with opaque white tiles, some will be overwritten soon.
	for (uint8_t x=0; x<TILEGRID_WIDTH; x++) {
		for (uint8_t y=0; y<TILEGRID_HEIGHT; y++) {
			__tile_b_set(x,y,TILE_WHITE);
		}
	}

	// Top tilelayer B transparent "SUPERCON" replace some of the opaque white tiles
	for (uint8_t y=0; y<4; y++) {
		y_offset = SEGA_VERTICAL_POS+y;
		// A full row of tiles in the tileset has "SUPER" and a bit of "C"
		//  spread across 16 tiles wide and 4 tiles high.
		for (uint8_t x=0; x<0x10; x++) {
			x_offset = SEGA_HORIZONTAL_POS+x;
			tile_index = TILE_SEGA_ROW1+x+0x10*y;
			__tile_b_set(x_offset, y_offset, tile_index);
		}

		// Following half row (8 tiles wide, 4 high) has the rest of "C" and "ON"
		for (uint8_t x=0; x<0x8; x++) {
			x_offset = SEGA_HORIZONTAL_POS+0x10+x;
			tile_index = TILE_SEGA_ROW2+x+0x10*y;
			__tile_b_set(x_offset, y_offset, tile_index);
		}
	}

	// Draw animated tilelayer A with items to show through transparent parts

	// Top 4 rows to white, center will receive cyan bar shortly.
	for (uint8_t x=0; x<64; x++) {
		for (uint8_t y=0; y<4; y++) {
			__tile_a_set(x,y,TILE_WHITE);
		}	
	}

	// Vertical cyan bar in middle of top two (now white) rows
	for (uint8_t y=0; y<4; y++) {
		__tile_a_set(31,y,TILE_SEGA_CYAN);
		__tile_a_set(32,y,TILE_SEGA_CYAN);
	}

	// After vertical cyan bar sweeps, use this horizontal cyan bar to fade in
	// blue via palette animation.
	for (uint8_t x=0; x<64; x++) {
		// Rows 4-7 to 25% blue
		for (uint8_t y=4; y<8; y++) {
			__tile_a_set(x,y,TILE_SEGA_CYAN);
		}
	}

	// Move tile layer A in place for horizontal sweep of vertical cyan bar
	int16_t x_translate= 64 * 16 * TILEGRID_WIDTH;
	int16_t y_translate=-64 * 16 * SEGA_VERTICAL_POS;
	__tile_a_translate(x_translate,y_translate);

	// Tiles are set up, we can now enable layers
	 GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_TILEA|GFX_LAYEREN_TILEB;

	// Wait a bit before starting the sweep
	__INEFFICIENT_delay(250);

	int16_t step_size = 64;
	// Cyan bar sweeps right
	for (uint16_t count=0; count<(64*16*TILEGRID_WIDTH); count+=step_size) {
		__tile_a_translate(x_translate-count,y_translate);
		__INEFFICIENT_delay(1);
	}

	// Palette color appears to be in AABBGGRR format:
	//	0xFFFFFFFF White
	//	0xFF00FF00 Green
	//	0xFFFF0000 Blue
	//  0xFFFF00FF Magenta
	//  0xFF0000FF Red
	//  0xFF00FFFF Yellow

	// Modify palette so cyan is now white
	GFXPAL[PAL_SEGA_CYAN] = 0xFFFFFFFF;

	// Wait to start fading in blue
	__INEFFICIENT_delay(100);

	// Move in the solid cyan (now palette changed to white) horizontal bar for palette animation
	__tile_a_translate(x_translate,y_translate+64*16*4);

	// Palette animation from 0xFFFFFFFF to 0xFFFF0000
	uint32_t color = 0xFFFF0000;
	for (uint8_t fade=0xFF; fade > 0; fade--) {
		color = 0xFFFF0000;
		color |= fade;
		color |= fade << 8;
		GFXPAL[PAL_SEGA_CYAN] = color;
		__INEFFICIENT_delay(1);
	}

	// Logo complete, allow admiration for a short time before exiting.
	__INEFFICIENT_delay(750);
}