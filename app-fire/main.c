#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "mach_defines.h"
#include "sdk.h"
#include "gfx_load.h"
#include "cache.h"

//Pointer to the framebuffer memory.
uint8_t *fbmem;

#define FB_WIDTH 512
#define FB_HEIGHT 320

#define COMP_COLOR(A, R, G, B) ((((A) & 0xFF) << 24) | \
								(((B) & 0xFF) << 16) | \
								(((G) & 0xFF) <<  8) | \
								(((R) & 0xFF) <<  0))
#define FB_PIX(X, Y) fbmem[(X) + ((Y) * FB_WIDTH)]

void __create_fire_palette(void) {

	// transparent to blue (leaving the first 16 for the tileset)
	// this could be as well just black to blue, but why not. :)
	for (int i = 0; i < 16; i++) {
		GFXPAL[i+17] = COMP_COLOR(i << 2, 0, 0, i << 2);
	}

	// setting the remaining palette in one go
	for (uint32_t i = 0; i < 32; i++) {
		// blue to red
		GFXPAL[i +  32] = COMP_COLOR(0xFF, i << 3, 0, 64 - (i << 1));
		// red to yellow
		GFXPAL[i +  64] = COMP_COLOR(0xFF, 0xFF, i << 3, 0);
		// yellow to white
		GFXPAL[i +  96] = COMP_COLOR(0xFF, 0xFF, 0xFF,   0 + (i << 2));
		GFXPAL[i + 128] = COMP_COLOR(0xFF, 0xFF, 0xFF,  64 + (i << 2));
		GFXPAL[i + 160] = COMP_COLOR(0xFF, 0xFF, 0xFF, 128 + (i << 2));
		GFXPAL[i + 192] = COMP_COLOR(0xFF, 0xFF, 0xFF, 192 + i);
		GFXPAL[i + 224] = COMP_COLOR(0xFF, 0xFF, 0xFF, 224 + i);
	}
}

void __render_fire(void) {
	/* draw randomized fire seed row */
	uint32_t rnd;
	for (int x = 0; x < FB_WIDTH; x++) {
		if ((x & 32) == 0) {
			rnd = MISC_REG(MISC_RNG_REG);
		}
		if (rnd & 0x00000001) {
			FB_PIX(x, FB_HEIGHT - 1) = 255 - 17;
		} else {
			FB_PIX(x, FB_HEIGHT - 1) = 0;
		}
		rnd >>= 1;
	}

	/* draw the fire:
	 * How it works:
	 * - We iterate through each pixel starting with the seed row.
	 * - Average the pixels palette entry values around us
	 *   including the one we are on:
	 *
	 * | |x| |
	 * |x|o|x|
	 *
	 * (current pixel marked with 'o', averaged pixels marked with 'x')
	 *
	 * - The resulting pixel value can then be decremented by 1 if
	 *   the color palette value is bigger than 0 to achieve a decay.
	 * - The resulting palette entry value into the postion right above
	 *   the current pixel.
	 * - Quit the loop when all pixels on the current line are 0 to
	 *   optimize rendering time...
	 */
	int tmp;
	int line = 0;
	// iterate over rows, calculate offset directly as it is more efficient
	// than calculating the buffer offset for each pixel access
	for (int y_off = FB_WIDTH * (FB_HEIGHT - 1);
		 y_off > 0;
		 y_off -= FB_WIDTH) {

		int done = 1;
		// iterate over columns
		for (int x = 0; x < FB_WIDTH; x++) {
			// left most column
			if (x == 0) {
				tmp  = fbmem[y_off];
				tmp += fbmem[y_off + 1];
				tmp += fbmem[y_off - FB_WIDTH];
				tmp /= 3;
			// right most column
			} else if (x == (FB_WIDTH - 1)) {
				tmp  = fbmem[y_off];
				tmp += fbmem[y_off - FB_WIDTH + x];
				tmp += fbmem[y_off + x - 1];
				tmp /= 3;
			// all the other columns ;)
			} else {
				tmp  = fbmem[y_off + x];
				tmp += fbmem[y_off + x + 1];
				tmp += fbmem[y_off + x - 1];
				tmp += fbmem[y_off - FB_WIDTH + x];
				tmp >>= 2;
			}

			// decay palette entry value until we reach 0
			if (tmp > 1) {
				tmp--;
				// while we are at it, also make sure to not exit prematurely
				// when the row has no pixels != 0 we can stop rendering
				done = 0;
			}

			// set the resulting pixel value
			fbmem[y_off - FB_WIDTH + x] = tmp;
		}

		// stop rendering when we reach 0 palette value, there will be nothing
		// happening any more, we will just keep wasting cycles ;)
		if (done) break;
	}

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);
}

void main(int argc, char **argv) {
	// We're running in app context. We have full control over the badge and
	// can do with the hardware what we want. As soon as main() returns,
	// however, we will go back to the IPL.
	printf("fire app: main running\n");

	// Blank out fb while we're loading stuff by disabling all layers. This
	// just shows the background color.
	GFX_REG(GFX_BGNDCOL_REG)=0x202020; //a soft gray
	GFX_REG(GFX_LAYEREN_REG)=0; //disable all gfx layers

	// First, allocate some memory for the background framebuffer.
	// We will be using a custom 256 entry color palette, so we allocate 1 byte
	// per pixel.
	fbmem=calloc(FB_WIDTH,FB_HEIGHT);
	printf("fire app: framebuffer at %p\n", fbmem);

	// Telling the GFX hardware what our framebuffer width is, and that it will
	// use palette entries starting from 17. The tiles left by the IPL will use
	// palette entries 0-16.
	GFX_REG(GFX_FBPITCH_REG)=(17<<GFX_FBPITCH_PAL_OFF)|(FB_WIDTH<<GFX_FBPITCH_PITCH_OFF);
	// Set up the framebuffer address
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)fbmem);

	// Generatinf the fire palette
	__create_fire_palette();

	// Clear the framebuffer
	for (int i = 0; i < (FB_WIDTH * FB_HEIGHT); i++) {
		fbmem[i] = 0;
	}

	// The IPL leaves us with a tileset that has tile 0 to 127 mapped to ASCII
	// characters, so we do not need to load anything specific for this. In
	// order to get some text out, we can use the /dev/console device that will
	// use these tiles to put text in a tilemap. It uses escape codes to do so,
	// see ipl/gloss/console_out.c for more info.
	FILE *f;
	f=fopen("/dev/console", "w");
	setvbuf(f, NULL, _IONBF, 0); //make console line unbuffered
	// Note that without the setvbuf command, no characters would be printed
	// until 1024 characters are buffered. You normally don't want this.
	fprintf(f, "\033C"); //clear the console. Note '\033' is the escape character.
	fprintf(f, "hold start to exit");
	fprintf(f, "\0337X"); //set Xpos to 5
	fprintf(f, "\0338Y"); //set Ypos to 8
	fprintf(f, "Welcome the fire!"); // Print a message

	// The user can still see nothing of this graphics goodness, so let's
	// re-enable the framebuffer and tile layer A (the default layer for the
	// console). Also indicate the framebuffer we have is 8-bit.
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB_8BIT|GFX_LAYEREN_FB|GFX_LAYEREN_TILEA;

	int run = 1;
	while(run) {
		// Render a frame of the fire effect on the framebuffer layer
		__render_fire();

		// Exit when the start button is pressed
		if (MISC_REG(MISC_BTN_REG) & BUTTON_START) {
			run = 0;
    	}
	}

	printf("fire app done. Bye!\n");
}
