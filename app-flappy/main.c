#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "mach_defines.h"
#include "sdk.h"
#include "gfx_load.h"
#include "cache.h"

//The bgnd.png image got linked into the binary of this app, and these two chars are the first
//and one past the last byte of it.
extern char _binary_bgnd_png_start;
extern char _binary_bgnd_png_end;
extern char _binary_tileset_default_png_start;
extern char _binary_tileset_default_png_end;

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

//Borrowed this from lcd.c until a better solution comes along :/
static void __INEFFICIENT_delay(int n) {
	for (int i=0; i<n; i++) {
		for (volatile int t=0; t<(1<<11); t++);
	}
}

void main(int argc, char **argv) {
//Allocate fb memory
	fbmem=malloc(320*512/2);

	for (uint8_t i=0; i<10;i++) {
		MISC_REG(MISC_LED_REG)=0xFFFFF;
		__INEFFICIENT_delay(100);
		MISC_REG(MISC_LED_REG)=0x00000;
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
	gfx_load_tiles_mem(GFXTILES, &GFXPAL[0], &_binary_tileset_default_png_start, (&_binary_tileset_default_png_end-&_binary_tileset_default_png_start));
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

	// //Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	// //we tell it to start writing from entry 0.
	gfx_load_fb_mem(fbmem, &GFXPAL[FB_PAL_OFFSET], 4, 512, &_binary_bgnd_png_start, (&_binary_bgnd_png_end-&_binary_bgnd_png_start));
	// printf("gfx_load_mem: %d\n", i);

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEB|GFX_LAYEREN_TILEA|GFX_LAYEREN_SPR;
	GFXPAL[FB_PAL_OFFSET+0x100]=0x00ff00ff; //Note: For some reason, the sprites use this as default bgnd. ToDo: fix this...
	GFXPAL[FB_PAL_OFFSET+0x1ff]=0x40ff00ff; //so it becomes this instead.

	// set_sprite(0, 0,0,16,16,0,0);

	fprintf(console, "\0330M\033C\0330A"); //Set map to tilemap A, clear tilemap, set attr to 0
	fprintf(console, "\033C"); //clear the console. Note '\033' is the escape character.
	fprintf(console, "\0335X"); //set Xpos to 5
	fprintf(console, "\0338Y"); //set Ypos to 8
	fprintf(console, "Hello World!\n"); // Print a nice greeting.
	// //Note that without the newline at the end, all printf's would stay in the buffer.

	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);
	
	// //The user can still see nothing of this graphics goodness, so let's re-enable the framebuffer and
	// //tile layer A (the default layer for the console). Also indicate the framebuffer we have is
	// //8-bit.
	// GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB_8BIT|GFX_LAYEREN_FB|GFX_LAYEREN_TILEA;

	printf("Hello Flappy222\r\n");
	fprintf(console,"Hello Flappy\r\n");



	//Wait until all buttons are released
	while (MISC_REG(MISC_BTN_REG)) ;

	//Wait until button A is pressed
	while ((MISC_REG(MISC_BTN_REG) & BUTTON_A)==0) ;
}
