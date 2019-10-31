/*
 * Copyright 2019 Jeroen Domburg <jeroen@spritesmods.com>
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software.  If not, see <https://www.gnu.org/licenses/>.
 */
#include <stdint.h>
#include <stdio.h>
#include <sys/select.h>
#include "video_renderer.hpp"

//This emulates the HDMI encoder, and instead shows the image in a SDL window.

#define SCALE 1

Video_renderer::Video_renderer(bool show_display) {
	do_display=show_display;
	if (do_display) {
		if (SDL_Init(SDL_INIT_VIDEO) < 0) {
			printf("Error initializing sdl!\n");
			exit(1);
		}
		window=SDL_CreateWindow("DMI output", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640*SCALE, 480*SCALE, SDL_WINDOW_SHOWN );
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
	}
	beam_x=0;
	beam_y=0;
}

int Video_renderer::next_pixel(int red, int green, int blue, int *fetch_next, int *next_line, int *next_field) {
	SDL_Rect r;
	if (beam_x<640 && beam_y<480) {
		r.x=beam_x*SCALE;
		r.y=beam_y*SCALE;
		r.w=SCALE;
		r.h=SCALE;
		if (do_display) SDL_FillRect(screen_surf, &r, SDL_MapRGB(screen_surf->format, red, green, blue));
		*fetch_next=1;
	} else {
		*fetch_next=0;
	}
	*next_line=(beam_x==640)?1:0;
	*next_field=(beam_y==480)?1:0;
	beam_x++;
	if (beam_x==796) {
		// Uncomment for more regular updates
		// if (do_display) {
		// 	Uint32 time_since_last=SDL_GetTicks()-last_update;
		// 	if (time_since_last>100) {
		// 		SDL_UpdateWindowSurface(window);
		// 		last_update=SDL_GetTicks();
		// 	}
		// }
		beam_x=0;
		beam_y++;
		if (beam_y==523) {
			if (do_display) SDL_UpdateWindowSurface(window);
			beam_y=0;
		}
	}
	return 0;
}

