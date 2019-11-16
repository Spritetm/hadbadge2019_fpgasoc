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

#define BORDER_LEFT 1
#define BORDER_RIGHT 28
#define BORDER_TOP 4
#define BORDER_BOTTOM 15

#define AUDIENCE_TOP 11
#define AUDIENCE_HEIGHT 2
#define AUDIENCE_LEFT 6
#define AUDIENCE_WIDTH 18

#define COVER_TILE_PINK  0x01
#define PALETTE_INDEX_PINK 2

#define COVER_TILE_RED   0x10
#define PALETTE_INDEX_RED 1

#define COVER_TILE_GREEN 0x11
#define PALETTE_INDEX_GREEN 4

#define AUDIENCE_TILE_ROW_HEIGHT 2
#define AUDIENCE_TILE_ROW1 0x02
#define AUDIENCE_TILE_ROW1_WIDTH 14
#define AUDIENCE_TILE_ROW2 0x20
#define AUDIENCE_TILE_ROW2_WIDTH 4

#define HAD_TOP 7
#define HAD_LEFT 7
#define HAD_WIDTH 16

#define SUPERCON_TOP HAD_TOP+1
#define SUPERCON_HEIGHT 4
#define SUPERCON_LEFT HAD_LEFT
#define SUPERCON_WIDTH HAD_WIDTH

#define SOUND_SYSTEM_TOP SUPERCON_TOP+4
#define SOUND_SYSTEM_LEFT HAD_LEFT
#define SOUND_SYSTEM_WIDTH HAD_WIDTH

#define FADE_DELAY_BORDER 10		// * 256 ~= 2.5 seconds
#define FADE_DELAY_AUDIENCE 6		// * 256 ~= 1.5 seconds
#define FADE_DELAY_SUPERCON 12		// * 256 ~= 3 seconds
#define FADE_DELAY_SOUND_SYSTEM 10  // * 256 ~= 2.5 seconds
#define FADE_DELAY_FINAL 4			// * 256 ~= 1 second

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
//	All-important sound by (TBD)
//	Art and Code by Roger Cheng (Twitter @Regorlas)
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

	// Change PINK, RED, and GREEN all to black for fading effect.
	// Comment these lines out to see behind-the-scenes on how fading effect works.
	GFXPAL[PALETTE_INDEX_PINK]  = 0XFF000000;
	GFXPAL[PALETTE_INDEX_RED]   = 0XFF000000;
	GFXPAL[PALETTE_INDEX_GREEN] = 0XFF000000;

	// Cover border with PINK for fade in/out effect
	for (uint8_t x = BORDER_LEFT; x <= BORDER_RIGHT; x++) {
		// Cover top and bottom bars of border
		__tile_b_set(x, BORDER_TOP, COVER_TILE_PINK);
		__tile_b_set(x, BORDER_BOTTOM, COVER_TILE_PINK);
	}
	for (uint8_t y = BORDER_TOP+1; y < BORDER_BOTTOM; y++) {
		// Cover left and right bars of border
		__tile_b_set(BORDER_LEFT, y, COVER_TILE_PINK);
		__tile_b_set(BORDER_RIGHT, y, COVER_TILE_PINK);
	}

	// Cover RED over sections that are only used by background
	for (uint8_t x = SOUND_SYSTEM_LEFT; x<SOUND_SYSTEM_LEFT+SOUND_SYSTEM_WIDTH; x++) {
		for (uint8_t y = HAD_TOP; y < AUDIENCE_TOP; y++) {
			__tile_b_set(x,y,COVER_TILE_RED);
		}
	}

	// Place tiles for "The Audience is Hacking"
	for (uint8_t y = 0; y < AUDIENCE_HEIGHT; y++) {
		for (uint8_t x = 0; x < AUDIENCE_TILE_ROW1_WIDTH; x++) {
			__tile_a_set(AUDIENCE_LEFT+x, AUDIENCE_TOP+y, AUDIENCE_TILE_ROW1+x+(y*0x10));
		}
		for (uint8_t x = 0; x < AUDIENCE_TILE_ROW2_WIDTH; x++) {
			__tile_a_set(AUDIENCE_LEFT+AUDIENCE_TILE_ROW1_WIDTH+x, AUDIENCE_TOP+y, AUDIENCE_TILE_ROW2+x+(y*0x10));
		}
	}

	// Place GREEN tiles to cover "The Audience is Hacking" for fade
	for (uint8_t y = 0; y < AUDIENCE_HEIGHT; y++) {
		for (uint8_t x = 0; x < AUDIENCE_TILE_ROW1_WIDTH; x++) {
			__tile_b_set(AUDIENCE_LEFT+x, AUDIENCE_TOP+y, COVER_TILE_GREEN);
		}
		for (uint8_t x = 0; x < AUDIENCE_TILE_ROW2_WIDTH; x++) {
			__tile_b_set(AUDIENCE_LEFT+AUDIENCE_TILE_ROW1_WIDTH+x, AUDIENCE_TOP+y, COVER_TILE_GREEN);
		}
	}

	// Tiles are set up, we can now enable layers
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEB|GFX_LAYEREN_TILEA;

	// Fade in border by fading out "PINK" tiles
	uint32_t fadecolor = 0;
	for (uint8_t fade = 0xFF; fade > 0; fade--) {
		fadecolor = fade << 24;
		GFXPAL[PALETTE_INDEX_PINK] = fadecolor;
		delay(FADE_DELAY_BORDER);
	}

	// Wait one second...
	delay(1000);

	// Fade in "The Audience is Hacking" by fading out "GREEN" tiles
	for (uint8_t fade = 0xFF; fade > 0; fade--) {
		fadecolor = fade << 24;
		GFXPAL[PALETTE_INDEX_GREEN] = fadecolor;
		delay(FADE_DELAY_AUDIENCE);
	}

	// Hold "The Audience is Hacking"
	delay(3000);

	// Fade out "The Audience is Hacking" by fading in "GREEN" tiles
	for (uint8_t fade = 0; fade < 0xFF; fade++) {
		fadecolor = fade << 24;
		GFXPAL[PALETTE_INDEX_GREEN] = fadecolor;
		delay(FADE_DELAY_AUDIENCE);
	}

	// Disable tile layer A where "The Audience is Hacking" lives
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEB;

	// Switch around the masks so we could fade in final screen

	// GREEN now covers the top and bottom bars
	for (uint x = HAD_LEFT; x < HAD_LEFT+HAD_WIDTH; x++ ) {
		__tile_b_set(x,HAD_TOP, COVER_TILE_GREEN);
	}
	for (uint8_t x = SOUND_SYSTEM_LEFT; x < SOUND_SYSTEM_LEFT+SOUND_SYSTEM_WIDTH; x++ ) {
		__tile_b_set(x,SOUND_SYSTEM_TOP, COVER_TILE_GREEN);
	}

	// And RED covers SUPERCON
	for (uint x = SUPERCON_LEFT; x < SUPERCON_LEFT+SUPERCON_WIDTH; x++ ) {
		for (uint y = SUPERCON_TOP; y < SUPERCON_TOP+SUPERCON_HEIGHT; y++ ) {
			__tile_b_set(x,y,COVER_TILE_RED);
		}
	}

	// Hold black for 4 seconds
	delay(4000);

	// Fade in "SUPERCON" by fading out "RED" tiles
	for (uint8_t fade = 0xFF; fade > 0; fade--) {
		fadecolor = fade << 24;
		GFXPAL[PALETTE_INDEX_RED] = fadecolor;
		delay(FADE_DELAY_SUPERCON);
	}

	// Hold SUPERCON and border for 4 seconds
	delay(4000);

	// Fade out blue border simultaneously with fading in "2019 Hackaday"/"Badge Sound System"
	for (uint8_t fade = 0xFF; fade > 0; fade--) {
		fadecolor = fade << 24;
		GFXPAL[PALETTE_INDEX_GREEN] = fadecolor;
		fadecolor = (0xFF-fade) << 24;
		GFXPAL[PALETTE_INDEX_PINK] = fadecolor;
		delay(FADE_DELAY_SOUND_SYSTEM);
	}

	// TODO: shiny  effect

	// Hold until button press OR delay the correct amount to match end of audio
	wait_for_button_press(BUTTON_A|BUTTON_B|BUTTON_SELECT|BUTTON_START|BUTTON_UP|BUTTON_DOWN|BUTTON_LEFT|BUTTON_RIGHT);

	// Fade to black. Enjoy your feature presentation.
	for (uint8_t fade = 0; fade < 0xFF; fade++) {
		fadecolor = fade << 24;
		GFXPAL[PALETTE_INDEX_GREEN] = fadecolor;
		GFXPAL[PALETTE_INDEX_RED] = fadecolor;
		delay(FADE_DELAY_FINAL);
	}	
}
