#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <fcntl.h>
#include <unistd.h>

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

float sin_vals[314]; // from 0 to 2*pi

void setup_sin_table(void) {
	for (int i = 0; i < 314; ++i) {
		sin_vals[i] = sinf(i / 50.0);
		//printf("%d: %f\n", i, sin_vals[i]);
	}
}

float table_sin(float x) {
	int index = (int)(x * 50.0) % 314;
	return sin_vals[index];
}

#define FB_WIDTH 512
#define FB_HEIGHT 320

// adapted from app-mynameis/main.c
void *load_bg_png(const uint8_t *start, const uint8_t *end) {
	//First, allocate some memory for the background framebuffer. We're gonna dump a fancy image into it. The image is
	//going to be 8-bit, so we allocate 1 byte per pixel.
	void *fbmem = calloc(FB_WIDTH, FB_HEIGHT);
	
	//Tell the GFX hardware to use this, and its pitch. We also tell the GFX hardware to use palette entries starting
	//from 128 for the frame buffer; the tiles left by the IPL will use palette entries 0-16 already.
	GFX_REG(GFX_FBPITCH_REG)=(128<<GFX_FBPITCH_PAL_OFF)|(FB_WIDTH<<GFX_FBPITCH_PITCH_OFF);
	//Set up the framebuffer address
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)fbmem);

	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//we tell it to start writing from entry 128.
	int png_size=(end - start);
	int ret = gfx_load_fb_mem(fbmem, &GFXPAL[128], 8, FB_WIDTH, start, png_size);
	if (ret) {
		printf("gfx_load_fb_mem: error %d\n", ret);
	}

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	return fbmem;
}

void set_bw_pal(int index, float brightness) {
	uint32_t *pal = (uint32_t *)(GFX_OFFSET_PAL);
	int scaled_brightness = 0xFF * brightness;
	pal[index] = (scaled_brightness << 24) | (scaled_brightness << 16) |
		(scaled_brightness << 8) | 0xFF;
}

void flush_pal(int start, int end) {
	uint32_t *pal = (uint32_t *)(GFX_OFFSET_PAL);
	cache_flush(pal + start, pal + end);
}

#define PAL_SIZE 74
uint16_t pal_offset[PAL_SIZE];
float pal_speed[PAL_SIZE];

void init_pal_entries(void) {
	// this image has a palette of 75 colors, with index 0 being black
	// setup sinewaves for each of the other -- start all at black,
	// but set them up to ramp up/down at various rates with the rate
	// changing each time around
	for (int i = 0; i < PAL_SIZE; ++i) {
		pal_speed[i] = (10.0 + (rand() * 200.0 / RAND_MAX));
		pal_offset[i] = 100.0 * rand() / RAND_MAX;
	}
}

void main(int argc, char **argv) {
	// reopen_stdfiles_as_usb();
	setup_sin_table();

	//Blank out fb while we're loading stuff by disabling all layers. This just shows the background color.
	GFX_REG(GFX_BGNDCOL_REG) = 0x202020; //a soft gray
	GFX_REG(GFX_LAYEREN_REG) = 0; //disable all gfx layers
	
	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//we tell it to start writing from entry 128.
	void *fb = load_bg_png(&_binary_hackaday_bg_png_start, &_binary_hackaday_bg_png_end);
	printf("Hello World: framebuffer at %p\n", fb);
	
	GFX_REG(GFX_LAYEREN_REG) = GFX_LAYEREN_FB | GFX_LAYEREN_FB_8BIT;

	// this image has a palette of 75 colors, with index 0 being black
	// setup sinewaves for each of the other -- start all at black,
	// but set them up to ramp up/down at various rates with the rate
	// changing each time around
	init_pal_entries();

	while (MISC_REG(MISC_BTN_REG)) ;

	//Loop until button A is pressed
	while ((MISC_REG(MISC_BTN_REG) & BUTTON_A) == 0) {
		uint32_t cur_vbl_ctr = GFX_REG(GFX_VBLCTR_REG);

		// rerandomize on button B
		if ((MISC_REG(MISC_BTN_REG) & BUTTON_B)) {
			init_pal_entries();
		}

		for (int i = 0; i < PAL_SIZE; ++i) {
			float brightness =
				fabs(table_sin((cur_vbl_ctr + pal_offset[i]) / pal_speed[i]));
			set_bw_pal(i + 129, brightness);
		}
		flush_pal(129, 129 + PAL_SIZE);

		while (GFX_REG(GFX_VBLCTR_REG) <= cur_vbl_ctr);
	}

	free(fb);
}
