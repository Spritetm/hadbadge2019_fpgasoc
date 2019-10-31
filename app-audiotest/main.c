#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "mach_defines.h"
#include "gfx_load.h"
#include "cache.h"

//hardware addresses I really need to dump into an include or something...
extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]
extern volatile uint32_t GFXREG[];
#define GFX_REG(i) GFXREG[(i)/4]
extern uint32_t GFXPAL[];
extern uint32_t GFXTILES[];
extern uint32_t GFXTILEMAPA[];
extern uint32_t GFXTILEMAPB[];



//Pointer to the framebuffer memory.
uint8_t *fbmem;

#define FB_WIDTH 512
#define FB_HEIGHT 320

extern volatile uint32_t SYNTH[];
#define SYNTHREG(i) SYNTH[i/4]

static inline void button_wait(){
	//Wait until all buttons are released
	while (MISC_REG(MISC_BTN_REG)) ;
	//Wait until button A is pressed
	while ((MISC_REG(MISC_BTN_REG) & BUTTON_A)==0) ;
}

void main(int argc, char **argv) {
	//We're running in app context. We have full control over the badge and can do with the hardware what we want. As
	//soon as main() returns, however, we will go back to the IPL.
	
	//Blank out fb while we're loading stuff by disabling all layers. This just shows the background color.
	//  Blue, Green, Red
	GFX_REG(GFX_BGNDCOL_REG)=0xf010f0; //a soft gray
	GFX_REG(GFX_LAYEREN_REG)=0; //disable all gfx layers
	
	//First, allocate some memory for the background framebuffer. We're gonna dump a fancy image into it. The image is
	//going to be 8-bit, so we allocate 1 byte per pixel.
	fbmem=calloc(FB_WIDTH,FB_HEIGHT);
	
	//Tell the GFX hardware to use this, and its pitch. We also tell the GFX hardware to use palette entries starting
	//from 0 for the frame buffer.
	GFX_REG(GFX_FBPITCH_REG)=(0<<GFX_FBPITCH_PAL_OFF)|(FB_WIDTH<<GFX_FBPITCH_PITCH_OFF);
	//Set up the framebuffer address
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)fbmem);

	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//we tell it to start writing from entry 0.
	/* int png_size=(&_binary_bgnd_png_end-&_binary_bgnd_png_start); */
	/* int i=gfx_load_fb_mem(fbmem, &GFXPAL[0], 8, FB_WIDTH, &_binary_bgnd_png_start, png_size); */
	/* printf("gfx_load_mem: %d\n", i); */

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	//The IPL leaves us with a tileset that has tile 0 to 127 map to ASCII characters, so we do not need to
	//load anything specific for this. In order to get some text out, we can use the /dev/console device
	//that will use these tiles to put text in a tilemap. It uses escape codes to do so, see 
	//ipl/gloss/console_out.c for more info.
	FILE *f;
	f=fopen("/dev/console", "w");
	setvbuf(f, NULL, _IOLBF, 1024); //make console line buffered
	//Note that without the setvbuf command, no characters would be printed until 1024 characters are
	//buffered.
	fprintf(f, "\033C"); //clear the console. Note '\033' is the escape character.
	fprintf(f, "\0335X"); //set Xpos to 5
	fprintf(f, "\0338Y"); //set Ypos to 8
	fprintf(f, "Hello World!\n"); // Print a nice greeting.
	//Note that without the newline at the end, all printf's would stay in the buffer.
	//The user can still see nothing of this graphics goodness, so let's re-enable the framebuffer and
	//tile layer A (the default layer for the console). Also indicate the framebuffer we have is
	//8-bit.
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB_8BIT|GFX_LAYEREN_FB|GFX_LAYEREN_TILEA;

	button_wait();
    SYNTHREG(0x0) = 0x1;	// just send gate high for now
	button_wait();
	fprintf(f,"HOWDY!\n");
    SYNTHREG(0x0) = 0x0;	// just send gate high for now
	button_wait();
}
