#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <fcntl.h>
#include <unistd.h>

#include "sin_table.h"

#include "mach_defines.h"
#include "sdk.h"
#include "gfx_load.h"
#include "cache.h"

// start and end of embedded background PNG file
extern char _binary_hackaday_bg_png_start;
extern char _binary_hackaday_bg_png_end;

extern uint32_t GFXSPRITES[];

void reopen_stdfiles_as_usb(void) {
	for (int i=0;i<3;i++) {
		close(i);
		open("/dev/ttyUSB", O_RDWR);
	}
}

#define FB_WIDTH 512
#define FB_HEIGHT 320
#define PNG_PAL_START 256

// adapted from app-mynameis/main.c
void *load_bg_png(const uint8_t *start, const uint8_t *end) {
	//First, allocate some memory for the background framebuffer. We're gonna dump a fancy image into it. The image is
	//going to be 8-bit, so we allocate 1 byte per pixel.
	void *fbmem = calloc(FB_WIDTH, FB_HEIGHT);
	
	//Tell the GFX hardware to use this, and its pitch. We also tell the GFX hardware to use palette entries starting
	//from 128 for the frame buffer; the tiles left by the IPL will use palette entries 0-16 already.
	GFX_REG(GFX_FBPITCH_REG) =
		(PNG_PAL_START<<GFX_FBPITCH_PAL_OFF) |
		(FB_WIDTH << GFX_FBPITCH_PITCH_OFF);
	//Set up the framebuffer address
	GFX_REG(GFX_FBADDR_REG) = ((uint32_t)fbmem);

	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//we tell it to start writing from entry PNG_PAL_START (128).
	int png_size = end - start;
	int ret = gfx_load_fb_mem(fbmem, &GFXPAL[PNG_PAL_START], 8, FB_WIDTH, start, png_size);
	if (ret) {
		printf("gfx_load_fb_mem: error %d\n", ret);
	}

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	return fbmem;
}

// this image has a palette of 75 colors, with index 0 being black
// setup sinewaves for each of the other -- start all at black,
// but set them up to ramp up/down at various rates with the rate
// changing each time around

#define PAL_SIZE 76
uint16_t pal_offset[PAL_SIZE];
float pal_speed[PAL_SIZE];

void set_bw_pal(int index, float brightness) {
	uint32_t *png_pal = &GFXPAL[PNG_PAL_START];
	int scaled_brightness = 0xFF * brightness;
	png_pal[index] = (scaled_brightness << 24) | (scaled_brightness << 16) |
		(scaled_brightness << 8) | 0xFF;
}

void flush_png_pal() {
	uint32_t *png_pal = &GFXPAL[PNG_PAL_START];
	cache_flush(png_pal, png_pal + PAL_SIZE);
}

void init_palette(void) {
	for (int i = 1; i < PAL_SIZE; ++i) {
		pal_speed[i] = (10.0 + (rand() * 200.0 / RAND_MAX));
		pal_offset[i] = 100.0 * rand() / RAND_MAX;
	}
}

void animate_palette(uint32_t cur_vbl_ctr) {
	for (int i = 1; i < PAL_SIZE; ++i) {
		float brightness =
			fabs(table_sin((cur_vbl_ctr + pal_offset[i]) / pal_speed[i]));
		set_bw_pal(i, brightness);
	}
	flush_png_pal();
}

void wait_for_vblank(uint32_t cur_vbl_ctr) {
	while (GFX_REG(GFX_VBLCTR_REG) <= cur_vbl_ctr);
}

void main(int argc, char **argv) {
	// reopen_stdfiles_as_usb();
	init_sin_table();

	//Blank out fb while we're loading stuff by disabling all layers. This just shows the background color.
	GFX_REG(GFX_BGNDCOL_REG) = 0x202020; //a soft gray
	GFX_REG(GFX_LAYEREN_REG) = 0; //disable all gfx layers
	
	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//we tell it to start writing from entry 128.
	void *fb = load_bg_png(&_binary_hackaday_bg_png_start, &_binary_hackaday_bg_png_end);
	printf("Hello World: framebuffer at %p\n", fb);
	GFX_REG(GFX_LAYEREN_REG) = GFX_LAYEREN_FB | GFX_LAYEREN_FB_8BIT;

	init_palette();

	while (MISC_REG(MISC_BTN_REG)) ;

	//Loop until button A is pressed
	while ((MISC_REG(MISC_BTN_REG) & BUTTON_A) == 0) {
		uint32_t cur_vbl_ctr = GFX_REG(GFX_VBLCTR_REG);

		// rerandomize on button B
		if ((MISC_REG(MISC_BTN_REG) & BUTTON_B)) {
			init_palette();
		}
		else {
			animate_palette(cur_vbl_ctr);
		}

		wait_for_vblank(cur_vbl_ctr);
	}

	free(fb);
}
