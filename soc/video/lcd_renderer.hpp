
#pragma once

#include <SDL.h>


using namespace std;

class Lcd_renderer {
	public:
	Lcd_renderer();
	void update(int db, int wr, int rd, int rs);

	private:
	SDL_Surface *screen_surf;
	SDL_Window *window;
	int xpos;
	int ypos;
	int lastwr;
	Uint32 last_update;
};
