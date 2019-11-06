#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "mach_defines.h"
#include "sdk.h"
#include "gfx_load.h"
#include "cache.h"

//The background image got linked into the binary of this app, and these two chars are the first
//and one past the last byte of it.
extern char _binary_gameboybackground_png_start;
extern char _binary_gameboybackground_png_end;

// Followed by the tileset
extern char _binary_gameboytiles_png_start;
extern char _binary_gameboytiles_png_end;

extern char _binary_switch_bg_png_start;
extern char _binary_switch_bg_png_end;

extern char _binary_switch_tileset_png_start;
extern char _binary_switch_tileset_png_end;

extern char _binary_xbox_bg_png_start;
extern char _binary_xbox_bg_png_end;

extern char _binary_xbox_tiles_png_start;
extern char _binary_xbox_tiles_png_end;

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

/////////////////////////////////////////////////////////////////////////////
//
//  Constants for splash screen inspired by Nintendo Gameboy (Monochrome)

#define GBM_X 5
#define GBM_Y 8

#define TILE_GBM    0x0

/////////////////////////////////////////////////////////////////////////////
//
//  Constants for splash screen inspired by Nintendo Switch

#define SWITCH_LEFT_X 11
#define SWITCH_LEFT_Y 3
#define SWITCH_RIGHT_X 15
#define SWITCH_RIGHT_Y 3
#define SWITCH_SUPERCON_X 9
#define SWITCH_SUPERCON_Y 15

#define TILE_SWITCH_LEFT    0x20
#define TILE_SWITCH_RIGHT   0x24
#define TILE_SWITCH_SUPERCON 0X01
#define TILE_SWITCH_RED     0x10

/////////////////////////////////////////////////////////////////////////////
//
//  Constants for splash screen inspired by Xbox One

#define XBOX_X 7
#define XBOX_Y 0

#define TILE_XBOX    0x0

//  End splash screen constants
//
/////////////////////////////////////////////////////////////////////////////

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

void gfx_set_xlate_val(int layer, int xcenter, int ycenter, float scale, float rot) {
	float scale_inv=(1.0/scale);
	float dx_x=cos(rot)*scale_inv;
	float dx_y=-sin(rot)*scale_inv;
	float dy_x=sin(rot)*scale_inv;
	float dy_y=cos(rot)*scale_inv;
	float start_x=-xcenter;
	float start_y=-ycenter;

	int i_dx_x=64.0*dx_x;
	int i_dx_y=64.0*dx_y;
	int i_dy_x=64.0*dy_x;
	int i_dy_y=64.0*dy_y;
	int i_start_x=(-start_x+start_x*dx_x-start_y*dx_y)*64.0;
	int i_start_y=(-start_y+start_y*dy_y-start_x*dy_x)*64.0;

	GFX_REG(GFX_TILEA_OFF)=(i_start_y<<16)+(i_start_x&0xffff);
	GFX_REG(GFX_TILEA_INC_COL)=(i_dx_y<<16)+(i_dx_x&0xffff);
	GFX_REG(GFX_TILEA_INC_ROW)=(i_dy_y<<16)+(i_dy_x&0xffff);
}

/////////////////////////////////////////////////////////////////////////////
//
//  Called by main() to run splash screen inspired by original monochrome
//  Nintendo Game Boy. This function is fully self-contained and can be main()
//  for a standaline app.
//  Be sure to copy the relevant constant #define above if doing so.

void gameboy_monochrome_splash() {
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
	int gfx_tiles_err = gfx_load_tiles_mem(GFXTILES, &GFXPAL[0], &_binary_gameboytiles_png_start, (&_binary_gameboytiles_png_end-&_binary_gameboytiles_png_start));
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
	gfx_load_fb_mem(fbmem, &GFXPAL[FB_PAL_OFFSET], 4, 512, &_binary_gameboybackground_png_start, (&_binary_gameboybackground_png_end-&_binary_gameboybackground_png_start));

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	//Copied from IPL not sure why yet
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

	// Place first row of tiles for "Superc" and part of "o"
	for (uint8_t x = 0; x < 16; x++) {
		x_offset = GBM_X + x;
		for (uint8_t y = 0; y < 4; y++) {
			y_offset = GBM_Y + y;
			tile_index = TILE_GBM + x + 0x10*y;
			__tile_a_set(x_offset, y_offset, tile_index);
		}
	}

	// Finish with remaining row for rest of "o" and "n"
	for (uint8_t x = 0; x < 6; x++) {
		x_offset = GBM_X + 0x10 + x;
		for (uint8_t y = 0; y < 4; y++) {
			y_offset = GBM_Y + y;
			tile_index = TILE_GBM + x + 0x40 + 0x10*y;
			__tile_a_set(x_offset, y_offset, tile_index);
		}
	}

	// Move A off screen
	int16_t y_offscreen = 64*16*(GBM_Y+4);
	__tile_a_translate(0,y_offscreen);

	// Tiles are set up, we can now enable layers
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEA;

	// Bring A back down
	for (int16_t y = y_offscreen; y > 0; y -= 8) {
		__tile_a_translate(0,y);
		__INEFFICIENT_delay(1);
	}

	// Logo complete, allow admiration for a short time before exiting.
	__INEFFICIENT_delay(750);
}

/////////////////////////////////////////////////////////////////////////////
//
//  Called by main() to run splash screen inspired by Nintendo Switch. This
//  function is fully self-contained and can be main() for a standaline app.
//  Be sure to copy the relevant constant #define above if doing so.

void switch_splash() {	

	/////////////////////////////////////////////////////////////////////////
	//  Generic badge app boilerplate

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
	int gfx_tiles_err = gfx_load_tiles_mem(GFXTILES, &GFXPAL[0], &_binary_switch_tileset_png_start, (&_binary_switch_tileset_png_end-&_binary_switch_tileset_png_start));
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
	gfx_load_fb_mem(fbmem, &GFXPAL[FB_PAL_OFFSET], 4, 512, &_binary_switch_bg_png_start, (&_binary_switch_bg_png_end-&_binary_switch_bg_png_start));

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	//Copied from IPL not sure why yet
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

	/////////////////////////////////////////////////////////////////////////
	//  Code specific to Switch splash

	uint8_t x_offset = 0;
	uint8_t y_offset = 0;
	uint8_t tile_index = 0;

	// Place switch icon left tiles on layer A
	for (uint8_t x = 0; x < 4; x++) {
		x_offset = SWITCH_LEFT_X+x;
		for (uint8_t y = 0; y < 8; y++) {
			y_offset = SWITCH_LEFT_Y+y;
			tile_index = TILE_SWITCH_LEFT + x + 0x10*y;
			__tile_a_set(x_offset, y_offset, tile_index);
		}
	}

	// Place switch icon right tiles on layer B
	for (uint8_t x = 0; x < 4; x++) {
		x_offset = SWITCH_RIGHT_X+x;
		for (uint8_t y = 0; y < 8; y++) {
			y_offset = SWITCH_RIGHT_Y+y;
			tile_index = TILE_SWITCH_RIGHT + x + 0x10*y;
			__tile_b_set(x_offset, y_offset, tile_index);
		}
	}

    #define B_Y_START 64*16*2
	int16_t y_translate = B_Y_START;

	__tile_b_translate(0,y_translate);

	// Tiles are set up, we can now enable layers
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEA|GFX_LAYEREN_TILEB;

	// Wait a bit before starting animation
	__INEFFICIENT_delay(100);

	// Animate right joycon upwards
	for (; y_translate < B_Y_START+(B_Y_START/4); y_translate+=16) {
		__tile_b_translate(0,y_translate);
		__INEFFICIENT_delay(1);
	}

	// Animate right joycon down until even.
	for (; y_translate > 0; y_translate-=32) {
		__tile_b_translate(0,y_translate);
		__INEFFICIENT_delay(1);
	}

	// Place "Supercon" on layer B
	for (uint8_t x = 0; x < 12; x++) {
		x_offset = SWITCH_SUPERCON_X+x;
		for (uint8_t y = 0; y < 2; y++) {
			y_offset = SWITCH_SUPERCON_Y+y;
			tile_index = TILE_SWITCH_SUPERCON + x + 0X10*y;
			__tile_b_set(x_offset, y_offset, tile_index);
		}
	}

	// Animate both tilemaps downwards a bit.
	for (int16_t bounce=0; bounce < B_Y_START/2; bounce+=32) {
		__tile_a_translate(0,y_translate-bounce);
		__tile_b_translate(0,y_translate-bounce);
		__INEFFICIENT_delay(1);
	}

	// And back up to neutral position
	for (int16_t bounce=B_Y_START/2; bounce > 0; bounce-=32) {
		__tile_a_translate(0,y_translate-bounce);
		__tile_b_translate(0,y_translate-bounce);
		__INEFFICIENT_delay(1);
	}

	// Logo complete, allow admiration for a short time before exiting.
	__INEFFICIENT_delay(750);
}

/////////////////////////////////////////////////////////////////////////////
//
//  Called by main() to run splash screen inspired by Xbox One. This
//  function is fully self-contained and can be main() for a standaline app.
//  Be sure to copy the relevant constant #define above if doing so.

void xbox_splash() {
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
	int gfx_tiles_err = gfx_load_tiles_mem(GFXTILES, &GFXPAL[0], &_binary_xbox_tiles_png_start, (&_binary_xbox_tiles_png_end-&_binary_xbox_tiles_png_start));
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
	gfx_load_fb_mem(fbmem, &GFXPAL[FB_PAL_OFFSET], 4, 512, &_binary_xbox_bg_png_start, (&_binary_xbox_bg_png_end-&_binary_xbox_bg_png_start));

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	//Copied from IPL not sure why yet
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

	// Place tiles for Xbox sphere (actually circle since we're 2D)
	for (uint8_t x = 0; x < 16; x++) {
		x_offset = XBOX_X + x;
		for (uint8_t y = 0; y < 16; y++) {
			y_offset = XBOX_Y + y;
			tile_index = TILE_XBOX + x + 0x10*y;
			__tile_a_set(x_offset, y_offset, tile_index);
		}
	}

	double scale = 6.3;

	gfx_set_xlate_val(0, 240, 128, scale, 0);

	// Tiles are set up, we can now enable layers
	 GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEA;

	for (uint8_t i = 0; i < 60; i++) {
		scale -= 0.1;
		gfx_set_xlate_val(0, 240, 128, scale, 0);
		__INEFFICIENT_delay(1);
	}

	// Logo complete, allow admiration for a short time before exiting.
	__INEFFICIENT_delay(750);
}

/////////////////////////////////////////////////////////////////////////////
//
//  Randomly choose one of available splash screens to display

void main(int argc, char **argv) {
	uint32_t random = 0xFF;

	// Will look at the lowest few bits of the randomly generated number,
	// number depends on how many possibilities we can launch. With 6
	// splash screens, the next highest power of two is 8, so we look at
	// 3 bits. (2^3 = 8) If the number is too big, rather than consuming
	// CPU cycles to do math and scale it down, we'll toss that number and
	// grab another one. Reading registers are cheap and fast.
	uint32_t bitmask = 0x7; // Lowest three bits

	while(random >= 6) {
		random = MISC_REG(MISC_RNG_REG) & bitmask;
	}

	switch(random) {
		case 0:
			gameboy_monochrome_splash();
			break;
		case 1:
		case 2:
			switch_splash();
			break;
		case 3:
		case 4:
		case 5:
			xbox_splash();
			break;
	}
}