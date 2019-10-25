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
extern char _binary_bgnd_png_start;
extern char _binary_bgnd_png_end;
extern char _binary_flappy_tileset_png_start;
extern char _binary_flappy_tileset_png_end;

//Pointer to the framebuffer memory.
uint8_t *fbmem;

#define FB_WIDTH 512
#define FB_HEIGHT 320
#define FB_PAL_OFFSET 256

extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]
extern volatile uint32_t GFXREG[];
#define GFX_REG(i) GFXREG[(i)/4]

extern uint32_t GFXPAL[];
extern uint32_t GFXTILES[];
extern uint32_t GFXTILEMAPA[];
extern uint32_t GFXTILEMAPB[];

//Define some tilemap data
#define FLAPPY_GROUND_INDEX 237
#define FLAPPY_GROUND_Y 19
#define FLAPPY_BRICK_INDEX 265

uint32_t __score = 0;

//Borrowed this from lcd.c until a better solution comes along :/
static void __INEFFICIENT_delay(int n) {
	for (int i=0; i<n; i++) {
		for (volatile int t=0; t<(1<<11); t++);
	}
}

//Helper function to set a tile on layer a
static void __tile_a_set(uint8_t x, uint8_t y, uint32_t index) {
	GFXTILEMAPA[y*GFX_TILEMAP_W+x] = index;
}

void main(int argc, char **argv) {
//Allocate fb memory
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
	int gfx_tiles_err = gfx_load_tiles_mem(GFXTILES, &GFXPAL[0], &_binary_flappy_tileset_png_start, (&_binary_flappy_tileset_png_end-&_binary_flappy_tileset_png_start));
	printf("Tiles initialized\n");

	
	//The IPL leaves us with a tileset that has tile 0 to 127 map to ASCII characters, so we do not need to
	//load anything specific for this. In order to get some text out, we can use the /dev/console device
	//that will use these tiles to put text in a tilemap. It uses escape codes to do so, see 
	//ipl/gloss/console_out.c for more info.
	//Note that without the setvbuf command, no characters would be printed until 1024 characters are
	//buffered.
	FILE *console=fopen("/dev/console", "w");
	setvbuf(console, NULL, _IOLBF, 1024); //make console line buffered
	if (console==NULL) {
		printf("Error opening console!\n");
	}

	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//we tell it to start writing from entry 0.
	//PAL offset changes the colors that the 16-bit png maps to?
	gfx_load_fb_mem(fbmem, &GFXPAL[FB_PAL_OFFSET], 4, 512, &_binary_bgnd_png_start, (&_binary_bgnd_png_end-&_binary_bgnd_png_start));
	// printf("gfx_load_mem: %d\n", i);

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEB|GFX_LAYEREN_TILEA|GFX_LAYEREN_SPR;
	GFXPAL[FB_PAL_OFFSET+0x100]=0x00ff00ff; //Note: For some reason, the sprites use this as default bgnd. ToDo: fix this...
	GFXPAL[FB_PAL_OFFSET+0x1ff]=0x40ff00ff; //so it becomes this instead.

	//Wait until all buttons are released
	while (MISC_REG(MISC_BTN_REG));

	fprintf(console, "\0330M\033C\0330A"); //Set map to tilemap A, clear tilemap, set attr to 0
	fprintf(console, "\033C"); //clear the console. Note '\033' is the escape character.
	
	fprintf(console, "\03324X\0330YFlappy\n"); 
	fprintf(console, "\03324X\03310YERR: %d\n", gfx_tiles_err);
	// //Note that without the newline at the end, all printf's would stay in the buffer.

	// cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	uint8_t i=0;
	for (uint8_t x=0; x<30; x++) {
		for (uint8_t y=0;y<9; y++) {
			GFXTILEMAPA[y*GFX_TILEMAP_W+x] = i++;
		}
	}

	//Wait for button press then start game
	// while((MISC_REG(MISC_BTN_REG) & BUTTON_A)==0);
	// //Wait until all buttons are released
	// while (MISC_REG(MISC_BTN_REG));
	memset(GFXTILEMAPA,0,0x4000); //Clear tilemap a
	memset(GFXTILEMAPB,0,0x4000); //Clear tilemap b

	//Draw the ground on the tilemap, probably inefficient but we're learning here
	for (uint8_t x=0; x<30; x++) {
		__tile_a_set(x, FLAPPY_GROUND_Y, FLAPPY_GROUND_INDEX);
	}

	//Draw a bottom "pipe"
	__tile_a_set(20,16,FLAPPY_BRICK_INDEX);
	__tile_a_set(21,16,FLAPPY_BRICK_INDEX+1);
	__tile_a_set(22,16,FLAPPY_BRICK_INDEX+1);
	__tile_a_set(23,16,FLAPPY_BRICK_INDEX+2);
	__tile_a_set(20,17,FLAPPY_BRICK_INDEX);
	__tile_a_set(21,17,FLAPPY_BRICK_INDEX+1);
	__tile_a_set(22,17,FLAPPY_BRICK_INDEX+1);
	__tile_a_set(23,17,FLAPPY_BRICK_INDEX+2);
	__tile_a_set(20,18,FLAPPY_BRICK_INDEX);
	__tile_a_set(21,18,FLAPPY_BRICK_INDEX+1);
	__tile_a_set(22,18,FLAPPY_BRICK_INDEX+1);
	__tile_a_set(23,18,FLAPPY_BRICK_INDEX+2);

	//The user can still see nothing of this graphics goodness, so let's re-enable the framebuffer and
	//tile layer A (the default layer for the console). 
	//Normal FB enabled (vice 8 bit) because background is loaded into the framebuffer above in 4 bit mode. 
	//TILEA is where text is printed by default
	 GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEA|GFX_LAYEREN_TILEB;

	//Primary game loop
	 while((MISC_REG(MISC_BTN_REG) & BUTTON_A)==0) {
		//Print score at 0,0
		fprintf(console, "\0330X\0330Y%dm", __score); 

		//Flappy score increases with distance which is simply a function of time
		__score++;
	 }
}
