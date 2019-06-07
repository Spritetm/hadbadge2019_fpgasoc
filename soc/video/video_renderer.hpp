
#pragma once

#include <SDL.h>


using namespace std;

class Video_renderer {
	public:
	Video_renderer();
	int next_pixel(int red, int green, int blue, int *fetch_next, int *next_line, int *next_field);

	private:
	SDL_Surface *screen_surf;
	SDL_Window *window;
	int beam_x;
	int beam_y;
	Uint32 last_update;
};
