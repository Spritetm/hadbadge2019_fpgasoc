/////////////////////////////////////////////////////////////////////////////
//
//	2019 Hackaday Supercon badge sound system showoff app
//
//  Inspired by the THX Deep Note intro sequence, this shows off the badge
//  audio frequency synthesis system.
//

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "mach_defines.h"
#include "sdk.h"
#include "gfx_load.h"
#include "cache.h"
#include "badgetime.h"

//The background image got linked into the binary of this app, and these two chars are the first
//and one past the last byte of it.
extern char _binary_deepnote_bg_png_start;
extern char _binary_deepnote_bg_png_end;

// Followed by the tileset
extern char _binary_deepnote_tileset_png_start;
extern char _binary_deepnote_tileset_png_end;

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

/////////////////////////////////////////////////////////////////////////////
//
//	Constants for tile positions and offsets



//	End constants
//
/////////////////////////////////////////////////////////////////////////////

//Helper function to set a tile on layer a
static inline void __tile_a_set(uint8_t x, uint8_t y, uint32_t index) {
	GFXTILEMAPA[y*GFX_TILEMAP_W+x] = index;
}

//Helper function to set a tile on layer b
static inline void __tile_b_set(uint8_t x, uint8_t y, uint32_t index) {
	GFXTILEMAPB[y*GFX_TILEMAP_W+x] = index;
}

/////////////////////////////////////////////////////////////////////////////
//
//	Badge sound showoff app inspired by THX Deep Note
//
//	Art and Code by Roger Cheng (Twitter @Regorlas)
//	Sound by (TBD)
//
void main() {
	/////////////////////////////////////////////////////////////////////////
	//	Generic badge app boilerplate

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
	int gfx_tiles_err = gfx_load_tiles_mem(GFXTILES, &GFXPAL[0], &_binary_deepnote_tileset_png_start, (&_binary_deepnote_tileset_png_end-&_binary_deepnote_tileset_png_start));
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

	//we tell it to start writing from entry 0.
	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//PAL offset changes the colors that the 16-bit png maps to?
	gfx_load_fb_mem(fbmem, &GFXPAL[FB_PAL_OFFSET], 4, 512, &_binary_deepnote_bg_png_start, (&_binary_deepnote_bg_png_end-&_binary_deepnote_bg_png_start));

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	//Copied from IPL not sure why yet
	GFXPAL[FB_PAL_OFFSET+0x100]=0x00ff00ff; //Note: For some reason, the sprites use this as default bgnd. ToDo: fix this...
	GFXPAL[FB_PAL_OFFSET+0x1ff]=0x40ff00ff; //so it becomes this instead.

	//This makes sure not to read button still pressed from badge menu selection
	wait_for_button_release();

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

	/////////////////////////////////////////////////////////////////////////
	//	Code specific to Deep Note app

	/*

	uint8_t tile_index = 0;

	// Place tiles for waves
	for (uint8_t x = 0; x < 0x10; x++) {
		for (uint8_t y = 0; y < 3; y++) {
			__tile_a_set(x,      PS_WAVE_Y + y, TILE_PS_WAVE1 + x + 0x10*y);
			__tile_a_set(x+0x10, PS_WAVE_Y + y, TILE_PS_WAVE2 + x + 0x10*y);
		}
	}

	// Place tiles that block the logo for fading effect
	for (uint8_t x = 0; x < 18; x++) {
		__tile_a_set(x+14, PS_TEXT_Y  , TILE_PS_WAVE1+1);
		__tile_a_set(x+14, PS_TEXT_Y+1, TILE_PS_WAVE1+1);
	}

	// Tiles are set up, we can now enable layers
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEA;

	uint32_t color = GFXPAL[3];
	uint32_t color_mask = 0x00FFFFFF;
	uint16_t steps = 64*16*2;

	for (int16_t dx = 0; dx < steps; dx++) {
		if (dx < 0xFF) {
			// Text fade-in accomplished by fading out the tiles blocking it.
			GFXPAL[3] = color & (color_mask | (0xFF-dx)<<24);
		} else if (steps-dx < 0xFF) {
			// Text fade-out accomplished by fading in the tiles blocking it.
			GFXPAL[3] = color & (color_mask | (0xFF-(steps-dx))<<24);
		}
		__tile_a_translate(dx,0);
		// more delay for audio: this was 1 (per cycle)
		__INEFFICIENT_delay(2);
	}
	*/
	// Tiles are set up, we can now enable layers
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEA;

	wait_for_button_press(BUTTON_A);	
}
