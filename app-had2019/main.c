#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
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

// start and end of embedded tile map PNG
extern char _binary_had_sprites_png_start;
extern char _binary_had_sprites_png_end;

void reopen_stdfiles_as_usb(void) {
	for (int i=0;i<3;i++) {
		close(i);
		open("/dev/ttyUSB", O_RDWR);
	}
}

// ------------------------

#define FB_WIDTH 512
#define FB_HEIGHT 320
#define BG_PAL_START 256

// adapted from app-mynameis/main.c
void *load_bg_png(const uint8_t *start, const uint8_t *end) {
	//First, allocate some memory for the background framebuffer. We're gonna dump a fancy image into it. The image is
	//going to be 8-bit, so we allocate 1 byte per pixel.
	void *fbmem = calloc(FB_WIDTH, FB_HEIGHT);
	
	//Tell the GFX hardware to use this, and its pitch. We also tell the GFX hardware to use palette entries starting
	//from 128 for the frame buffer; the tiles left by the IPL will use palette entries 0-16 already.
	GFX_REG(GFX_FBPITCH_REG) =
		(BG_PAL_START<<GFX_FBPITCH_PAL_OFF) |
		(FB_WIDTH << GFX_FBPITCH_PITCH_OFF);
	//Set up the framebuffer address
	GFX_REG(GFX_FBADDR_REG) = ((uint32_t)fbmem);

	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//we tell it to start writing from entry BG_PAL_START (128).
	int png_size = end - start;
	int ret = gfx_load_fb_mem(fbmem, &GFXPAL[BG_PAL_START], 8, FB_WIDTH, start, png_size);
	if (ret) {
		printf("gfx_load_fb_mem: error %d\n", ret);
	}

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem + FB_WIDTH * FB_HEIGHT);

	return fbmem;
}

#define TILE_WIDTH 128
#define TILE_HEIGHT 16
#define TILE_PAL_START 240

void load_tile_png(const uint8_t *start, const uint8_t *end) {
	int png_size = end - start;
	int ret = gfx_load_tiles_mem(GFXTILES, &GFXPAL[TILE_PAL_START], start, png_size);
	if (ret) {
		printf("gfx_load_tiles_mem: error %d\n", ret);
	}
}

// ------------------------

void set_bw_pal(int index, float brightness) {
	uint32_t *png_pal = &GFXPAL[0];
	int scaled_brightness = 0xFF * brightness;
	png_pal[index] = (scaled_brightness << 24) | (scaled_brightness << 16) |
		(scaled_brightness << 8) | 0xFF;
}

void flush_pal(int start, int end) {
	cache_flush(&GFXPAL[start], &GFXPAL[end]);
}

// this image has a palette of 75 colors, with index 0 being black
// setup sinewaves for each of the other -- start all at black,
// but set them up to ramp up/down at various rates with the rate
// changing each time around

#define BG_PAL_SIZE 76
uint16_t pal_offset[BG_PAL_SIZE];
float pal_speed[BG_PAL_SIZE];

void init_bg_palette(void) {
	for (int i = 1; i < BG_PAL_SIZE; ++i) {
		pal_speed[i] = (10.0 + (rand() * 200.0 / RAND_MAX));
		pal_offset[i] = 100.0 * rand() / RAND_MAX;
	}
}

void animate_bg_palette(uint32_t cur_vbl_ctr) {
	for (int i = 1; i < BG_PAL_SIZE; ++i) {
		float brightness =
			fabs(table_sin((cur_vbl_ctr + pal_offset[i]) / pal_speed[i]));
		set_bw_pal(i + BG_PAL_START, brightness);
	}
	flush_pal(BG_PAL_START, BG_PAL_START + BG_PAL_SIZE);
}

// sprites move up/down in the first and last 96 horizontal pixels of the screen
// our animation pattern starts with three chevrons at flight at a time, moving
// up/down to meet each other at different speeds

void set_sprite(int no, int x, int y, int sx, int sy, int tileno, int palstart) {
	x += 64;
	y += 64;
	GFXSPRITES[no * 2] =
		(y << GFX_SPRITE_ENT_YPOS_OFF) |
		(x << GFX_SPRITE_ENT_XPOS_OFF);
	GFXSPRITES[no * 2 + 1] =
		(sx << GFX_SPRITE_ENT_XSIZE_OFF) |
		(sy << GFX_SPRITE_ENT_YSIZE_OFF) |
		(tileno << GFX_SPRITE_ENT_TILE_OFF) |
		((palstart / 4) << GFX_SPRITE_ENT_PALSEL_OFF);
}

struct sprite_data {
	int num;
	int x;
	int y_start;
	int y_end;
	uint32_t t_start;
	uint32_t t_end;
};
typedef struct sprite_data sprite_data;

#define NUM_SPRITES 3
sprite_data sprites[NUM_SPRITES];

bool sprite_done(const sprite_data *spr, int t) {
	return (t >= spr->t_end);
}

bool sprite_upd_pos(const sprite_data *spr, int t) {
	if (t < spr->t_start) return;
	if (t > spr->t_end) t = spr->t_end;
	
	int off = t - spr->t_start;
	int dur = spr->t_end - spr->t_start;

	float mult = (float)off / (float) dur;
	int y = spr->y_start + mult * (spr->y_end - spr->y_start);

	set_sprite(spr->num, spr->x, y, 16, 16,
		spr->y_end > spr->y_start ? 1 : 0, TILE_PAL_START);
}

int sprite_state = 0;

void set_sprite_data(int num, uint32_t t,
	int start_off, int end_off,
	int x, int y_start, int y_end) {
	sprite_data *spr = &sprites[num];
	spr->num = num;
	spr->x = x;
	spr->y_start = y_start;
	spr->y_end = y_end;
	spr->t_start = t + start_off;
	spr->t_end = t + end_off;
}

void init_sprites(uint32_t t) {
	// start with one sprite
	set_bw_pal(TILE_PAL_START + 1, 1.0);
	set_bw_pal(TILE_PAL_START + 2, 1.0);

	switch (sprite_state) {
	case 0: // left from top, going down
		set_sprite_data(0, t, 0,  180, 32, 360, 40);
		set_sprite_data(1, t, 10, 190, 32, 360, 48);
		set_sprite_data(2, t, 20, 200, 32, 360, 56);
		break;
	case 1: // left from bottom, going down
		set_sprite_data(0, t, 10,  80, 32, 40, -40);
		set_sprite_data(1, t, 20,  90, 32, 48, -40);
		set_sprite_data(2, t, 30, 100, 32, 56, -40);
		break;
	case 2: // right from bottom, going up
		set_sprite_data(0, t, 0,  180, 432, -40, 280);
		set_sprite_data(1, t, 10, 190, 432, -40, 272);
		set_sprite_data(2, t, 20, 200, 432, -40, 264);
		break;
	case 3: // right from top, going up
		set_sprite_data(0, t, 10,  80, 432, 280, 360);
		set_sprite_data(1, t, 20,  90, 432, 272, 360);
		set_sprite_data(2, t, 30, 100, 432, 264, 360);
		break;
	}
}

void animate_sprites(uint32_t t) {
	for (int i = 0; i < NUM_SPRITES; ++i) {
		sprite_upd_pos(&sprites[i], t);
	}

	bool all_done = true;
	for (int i = 0; i < NUM_SPRITES; ++i) {
		all_done = all_done && sprite_done(&sprites[i], t);
	}
	if (all_done) {
		sprite_state = (sprite_state + 1) % 4;
		init_sprites(t);
	}
}

void wait_for_vblank(uint32_t cur_vbl_ctr) {
	while (GFX_REG(GFX_VBLCTR_REG) <= cur_vbl_ctr);
}

void main(int argc, char **argv) {
	// reopen_stdfiles_as_usb();
	init_sin_table();

	load_tile_png(&_binary_had_sprites_png_start, &_binary_had_sprites_png_end);

	//Blank out fb while we're loading stuff by disabling all layers. This just shows the background color.
	GFX_REG(GFX_BGNDCOL_REG) = 0x202020; //a soft gray
	GFX_REG(GFX_LAYEREN_REG) = 0; //disable all gfx layers
	
	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//we tell it to start writing from entry 128.
	void *fb = load_bg_png(&_binary_hackaday_bg_png_start, &_binary_hackaday_bg_png_end);
	GFX_REG(GFX_LAYEREN_REG) = GFX_LAYEREN_FB | GFX_LAYEREN_FB_8BIT | GFX_LAYEREN_SPR;
	GFXPAL[0x1ff]=0x00ff00ff; //Color the sprite layer uses when no sprites are drawn - 100% transparent.

	init_bg_palette();
	uint32_t cur_vbl_ctr = GFX_REG(GFX_VBLCTR_REG);
	init_sprites(cur_vbl_ctr);

	while (MISC_REG(MISC_BTN_REG)) ;

	//Loop until button A is pressed
	while ((MISC_REG(MISC_BTN_REG) & BUTTON_A) == 0) {
		cur_vbl_ctr = GFX_REG(GFX_VBLCTR_REG);

		// rerandomize on button B
		if ((MISC_REG(MISC_BTN_REG) & BUTTON_B)) {
			init_bg_palette();
		}
		else {
			animate_bg_palette(cur_vbl_ctr);
			animate_sprites(cur_vbl_ctr);
		}

		wait_for_vblank(cur_vbl_ctr);
	}

	free(fb);
}