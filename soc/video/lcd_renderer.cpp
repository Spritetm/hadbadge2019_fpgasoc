#include <stdint.h>
#include <stdio.h>
#include <sys/select.h>
#include "lcd_renderer.hpp"

#define SCALE 2

Lcd_renderer::Lcd_renderer() {
	if (SDL_Init(SDL_INIT_VIDEO) < 0) {
		printf("Error initializing sdl!\n");
		exit(1);
	}
	window=SDL_CreateWindow("DMI output", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 480*SCALE, 320*SCALE, SDL_WINDOW_SHOWN );
	if (!window) {
		printf("Error creating window!\n");
		exit(1);
	}
	screen_surf=SDL_GetWindowSurface(window);
	if (!screen_surf) {
		printf("Error getting window surface!\n");
		exit(1);
	}
	SDL_FillRect(screen_surf, NULL, SDL_MapRGB(screen_surf->format, 0xff, 0, 0xff));
	SDL_UpdateWindowSurface(window);
	lastwr=1;
	xpos=0;
	ypos=0;
}

void Lcd_renderer::update(int db, int wr, int rd, int rs) {
	if (lastwr==wr || wr==1) {
		lastwr=wr;
		return;
	}
	lastwr=wr;
	if (rs==0) {
		//command
		if (db!=0x2c) {
			printf("LCD: Unknown command 0x%X\n", db);
		} else {
			printf("LCD: new frame\n");
		}
		xpos=0;
		ypos=0;
	} else {
		SDL_Rect r;
		if (xpos<480 && ypos<320) {
			int red=((db>>0)&0x1f)<<3;
			int green=((db>>5)&0x3f)<<2;
			int blue=((db>>10)&0x1f)<<3;
			r.x=xpos*SCALE;
			r.y=ypos*SCALE;
			r.w=SCALE;
			r.h=SCALE;
			SDL_FillRect(screen_surf, &r, SDL_MapRGB(screen_surf->format, red, green, blue));
		} else {
			printf("LCD: Hmm, got data for %d, %d\n", xpos, ypos);
		}
		xpos++;
		if (xpos==480) {
			Uint32 time_since_last=SDL_GetTicks()-last_update;
			if (time_since_last>100) {
				SDL_UpdateWindowSurface(window);
				time_since_last=SDL_GetTicks();
			}
			xpos=0;
			ypos++;
		}
	}
	return;
}

