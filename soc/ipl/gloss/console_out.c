
//Functions here give a way to printf() text to the screen. It uses one of the
//tile maps (a by default) as a console, and assumes an ASCII charset is loaded into that.

#include <stdio.h>
#include "gloss/mach_defines.h"
extern uint32_t GFXTILEMAPA[];
extern uint32_t GFXTILEMAPB[];


static int xpos=0;
static int ypos=0;
static int win_x=0, win_y=0, win_w=30, win_h=20;

#define ESCAPE 27
#define CMD_SET_X 'X'
#define CMD_SET_Y 'Y'
#define CMD_SET_POS 'P'
#define CMD_CLEAR 'C'
#define CMD_SET_WINSTART 'W'
#define CMD_SET_WINEND 'E'
#define CMD_SET_MAP 'M'
#define CMD_SET_ATTR 'A'

#define STATE_NORM 0
#define STATE_ESCAPED 1
static int state=STATE_NORM;
#define ARGMAX 3
static int arg[ARGMAX];
static int argpos;
static int attr=0;
static int to_mapb=0;

void console_write_char_raw(char c) {
	uint32_t *map;
	if (to_mapb) map=&GFXTILEMAPB[0]; else map=&GFXTILEMAPA[0];
	if (xpos>=win_x+win_w || c=='\n') {
		printf("Next line; xpos=%d win_w=%d, c=%d\n", xpos, win_w, c);
		xpos=win_x;
		ypos++;
		if (ypos>=win_y+win_h) {
			printf("Console scrolling because ypos %d >=win_y %d\n", ypos, win_y);
			//Scroll up the window
			for (int y=win_y; y<win_y+win_h-1; y++) {
				for (int x=win_x; x<win_x+win_w; x++) {
					map[y*GFX_TILEMAP_W+x]=map[(y+1)*GFX_TILEMAP_W+x];
				}
			}
			//..and clear last line.
			for (int y=win_y; y<win_y+win_w-1; y++) {
				map[y*GFX_TILEMAP_W+win_x+win_w-1]=' ';
			}
			ypos--;
		}
	}
	if (c!='\n') {
		map[ypos*GFX_TILEMAP_W+xpos]=c+attr;
		xpos++;
	}
}

static void console_write_char(char c) {
	if (state==STATE_NORM) {
		if (c==ESCAPE) {
			state=STATE_ESCAPED;
			for (int i=0; i<ARGMAX; i++) arg[i]=0;
			argpos=-1;
		} else {
			console_write_char_raw(c);
		}
	} else { //escaped
		if (c>='0' && c<='9') {
			if (argpos==-1) argpos=0;
			arg[argpos]=arg[argpos]*10+(c-'0');
		} else if (c==';') {
			argpos++;
			if (argpos>=ARGMAX) argpos=ARGMAX-1;
		} else {
			if (c==CMD_SET_X) {
				printf("console CMD_SET_X %d\n", arg[0]);
				xpos=arg[0]+win_x;
			} else if (c==CMD_SET_Y) {
				printf("console CMD_SET_Y %d\n", arg[0]);
				ypos=arg[0]+win_y;
			} else if (c==CMD_SET_POS) {
				printf("console CMD_SET_POS %d,%d\n", arg[0], arg[1]);
				xpos=arg[0]+win_x;
				ypos=arg[1]+win_y;
			} else if (c==CMD_CLEAR) {
				printf("console CMD_CLEAR\n");
				xpos=win_x;
				ypos=win_y;
				for (int i=0; i<win_h*win_w; i++) {
					console_write_char_raw(' ');
				}
				xpos=win_x;
				ypos=win_y;
			} else if (c==CMD_SET_WINSTART) {
				win_x=arg[0];
				win_y=arg[1];
			} else if (c==CMD_SET_WINEND) {
				win_w=arg[0];
				win_h=arg[1];
			} else if (c==CMD_SET_MAP) {
				to_mapb=arg[0];
			} else if (c==CMD_SET_ATTR) {
				attr=arg[0];
			} else {
				//Unknown escape sequence
				console_write_char_raw(c);
			}
			state=STATE_NORM;
		}
	}
}


int console_write(char *data, int len) {
	for (int i=0; i<len; i++) console_write_char(data[i]);
	return len;
}
