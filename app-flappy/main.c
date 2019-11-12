#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "mach_defines.h"
#include "sdk.h"
#include "gfx_load.h"
#include "cache.h"

#include "libsynth.h"
#include "synth_utils.h"
#include "midi_note_increments.h"

//The bgnd.png image got linked into the binary of this app, and these two chars are the first
//and one past the last byte of it.
extern char _binary_bgnd_png_start;
extern char _binary_bgnd_png_end;
extern char _binary_flappy_tileset_png_start;
extern char _binary_flappy_tileset_png_end;

//Pointer to the framebuffer memory.
uint8_t *fbmem;

#define FB_WIDTH 512
#define FB_HEIGHT 320
#define FB_PAL_OFFSET 256

extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]
extern volatile uint32_t GFXREG[];
#define GFX_REG(i) GFXREG[(i)/4]

//Manually point to sprites memory location
uint32_t *GFXSPRITES = (uint32_t *)0x5000C000;

//Define some tilemap data
#define FLAPPY_GROUND_INDEX 247
#define FLAPPY_GROUND_Y 19
#define FLAPPY_BRICK_INDEX 136
#define FLAPPY_PLAYER_INDEX 184
#define FLAPPY_PLAYER_JUMP_INDEX 191

//Define game parameters
#define FLAPPY_PIPE_GAP 7
#define FLAPPY_PIPE_BOTTOM 19
#define FLAPPY_PIPE_HEIGHT_MIN 2
#define FLAPPY_PIPE_HEIGHT_MAX 9
#define FLAPPY_SPEED 1.8
#define FLAPPY_PLAYER_X 4
#define FLAPPY_GRAVITY 2.0
#define FLAPPY_JUMP (-17)
#define FLAPPY_BOTTOM_EXTENT 290

int m_player_y = 11;
float m_player_velocity = 0.0;
uint32_t m_score = 0;
int m_pipe_1_x = 11;
int m_pipe_1_height = 3;
int m_pipe_2_x = 27;
int m_pipe_2_height = 5;
int m_pipe_3_x = 43;
int m_pipe_3_height = 7;
int m_pipe_4_x = 59;
int m_pipe_4_height = 4;

//Borrowed this from lcd.c until a better solution comes along :/
static void __INEFFICIENT_delay(int n) {
	for (int i=0; i<n; i++) {
		for (volatile int t=0; t<(1<<11); t++);
	}
}


//Wait until all buttons are released
static inline void __button_wait_for_press() {
	while (MISC_REG(MISC_BTN_REG) == 0);
}

//Wait until all buttons are released
static inline void __button_wait_for_release() {
	while (MISC_REG(MISC_BTN_REG));
}

static inline void __sprite_set(int index, int x, int y, int size_x, int size_y, int tile_index, int palstart) {
	x+=64;
	y+=64;
	GFXSPRITES[index*2]=(y<<16)|x;
	GFXSPRITES[index*2+1]=size_x|(size_y<<8)|(tile_index<<16)|((palstart/4)<<25);
}

//Helper function to set a tile on layer a
static inline void __tile_a_set(uint8_t x, uint8_t y, uint32_t index) {
	GFXTILEMAPA[y*GFX_TILEMAP_W+x] = index;
}

//Helper function to set a tile on layer b
static inline void __tile_b_set(uint8_t x, uint8_t y, uint32_t index) {
	GFXTILEMAPB[y*GFX_TILEMAP_W+x] = index;
}

//Helper function to move tile layer 1
static inline void __tile_a_translate(int dx, int dy) {
	GFX_REG(GFX_TILEA_OFF)=(dy<<16)+(dx &0xffff);
}

//Helper function to move tile layer b
static inline void __tile_b_translate(int dx, int dy) {
	GFX_REG(GFX_TILEB_OFF)=(dy<<16)+(dx &0xffff);
}

static inline void __create_pipe(int x, int h) {
	//Generate a full pipe including gap
	for (uint8_t y=0; y<FLAPPY_PIPE_BOTTOM; y++) {
		//TOP
		if (y < FLAPPY_PIPE_BOTTOM-FLAPPY_PIPE_GAP-h) {
			__tile_a_set(x,y,FLAPPY_BRICK_INDEX);
			__tile_a_set(x+1,y,FLAPPY_BRICK_INDEX+1);
			__tile_a_set(x+2,y,FLAPPY_BRICK_INDEX+1);
			__tile_a_set(x+3,y,FLAPPY_BRICK_INDEX+2);
		} 
		//MIDDLE
		else if (y < FLAPPY_PIPE_BOTTOM-h) {
			__tile_a_set(x,y,0);
			__tile_a_set(x+1,y,0);
			__tile_a_set(x+2,y,0);
			__tile_a_set(x+3,y,0);
		} 
		//BOTTOM
		else {
			__tile_a_set(x,y,FLAPPY_BRICK_INDEX);
			__tile_a_set(x+1,y,FLAPPY_BRICK_INDEX+1);
			__tile_a_set(x+2,y,FLAPPY_BRICK_INDEX+1);
			__tile_a_set(x+3,y,FLAPPY_BRICK_INDEX+2);
		}
		__tile_a_set(x+4,y,0);
	}
}

/**
 * Check for collision with a pipe with true screen x coordinate and height value
 * Sadly units do not match. If I find time to fix it I will.
 * x is in absolute screen coordinate (pixels)
 * h is the height of the bottom pipe in tiles
 * 
 * This is compared against the player position which is stored statically.
 * YOLO
 * 
 * Returns 0 if no collision, non-zero if collision
 */
static int __collision_test(int x, int h) {
	//Easiest test is if player has not reached pipe
	if (x > ((FLAPPY_PLAYER_X* 16)+32)) {
		return 0;
	}

	//If player is past the pipe there can be no collision
	if ((x + 4) * 16 < (FLAPPY_PLAYER_X * 16)) {
		return 0;
	}

	//We only reach this point if player is at the pipe


	//Top is the minimum y extent the player can be as they're passing through the pipe
	int top = (FLAPPY_PIPE_BOTTOM - FLAPPY_PIPE_GAP - h) * 16;
	//Bottom is the maximum y extent he player can be as they're passing through the pipe
	int bottom = ((FLAPPY_PIPE_BOTTOM - h) * 16) - 32;

	//Test if player y is valid
	if (m_player_y < top || m_player_y > bottom) {
		return -1;
	}


	//We got this far, must be clear
	return 0;
}

// Sound FX
void synth_play_game_over(void){
	synth_queue->voice_force = (1 << 2); 
	for (uint32_t pitch = midi_table[64] ; pitch > midi_table[64-36] ; pitch=(pitch*15/16)){
		synth_queue->voice[2].phase_inc = pitch; 
		synth_queue->cmd_wait = 1250; 
	}
	synth_queue->voice_force = 0; 

}
void synth_play_flap(void){
	synth_queue->voice_force = 3; 
	synth_queue->voice[0].phase_inc = midi_table[80]; 
	synth_queue->voice[1].phase_inc = midi_table[80]; 
	for (uint16_t i=0; i<100; i=i+1){
		synth_queue->cmd_wait = 50; 
		synth_queue->voice[0].phase_inc = midi_table[85]+i*16; 
		synth_queue->voice[1].phase_inc = midi_table[85]+i*16; 
	}
	synth_queue->voice_force = 0; 
}

void main(int argc, char **argv) {
	//Allocate framebuffer memory
	fbmem=malloc(320*512/2);

	for (uint8_t i=0; i<16;i++) {
		MISC_REG(MISC_LED_REG)=(i<<i);
		__INEFFICIENT_delay(100);
	}
	

	//Set up the framebuffer address.
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)fbmem)&0xFFFFFF;
	//We're going to use a pitch of 512 pixels, and the fb palette will start at 256.
	GFX_REG(GFX_FBPITCH_REG)=(FB_PAL_OFFSET<<GFX_FBPITCH_PAL_OFF)|(512<<GFX_FBPITCH_PITCH_OFF);
	//Blank out fb while we're loading stuff.
	GFX_REG(GFX_LAYEREN_REG)=0;

	//Load up the default tileset and font.
	//ToDo: loading pngs takes a long time... move over to pcx instead.
	printf("Loading tiles...\n");
	int gfx_tiles_err = 
	gfx_load_tiles_mem(GFXTILES, &GFXPAL[0], 
		&_binary_flappy_tileset_png_start, 
		(&_binary_flappy_tileset_png_end - &_binary_flappy_tileset_png_start));
	printf("Tiles initialized err=%d\n", gfx_tiles_err);

	//The IPL leaves us with a tileset that has tile 0 to 127 map to ASCII characters, so we do not need to
	//load anything specific for this. In order to get some text out, we can use the /dev/console device
	//that will use these tiles to put text in a tilemap. It uses escape codes to do so, see 
	//ipl/gloss/console_out.c for more info.
	//Note that without the setvbuf command, no characters would be printed until 1024 characters are
	//buffered.
	FILE *console=fopen("/dev/console", "w");
	setvbuf(console, NULL, _IONBF, 0); //make console unbuffered
	if (console==NULL) {
		printf("Error opening console!\n");
	}

	//we tell it to start writing from entry 0.
	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//PAL offset changes the colors that the 16-bit png maps to?
	gfx_load_fb_mem(fbmem, &GFXPAL[FB_PAL_OFFSET], 4, 512, &_binary_bgnd_png_start, (&_binary_bgnd_png_end-&_binary_bgnd_png_start));

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	//Copied from IPL not sure why yet
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEB|GFX_LAYEREN_TILEA|GFX_LAYEREN_SPR;
	GFXPAL[FB_PAL_OFFSET+0x100]=0x00ff00ff; //Note: For some reason, the sprites use this as default bgnd. ToDo: fix this...
	GFXPAL[FB_PAL_OFFSET+0x1ff]=0x40ff00ff; //so it becomes this instead.

	__button_wait_for_release();

	//Set map to tilemap B, clear tilemap, set attr to 0
	//Not sure yet what attr does, but tilemap be is important as it will have the effect of layering
	//on top of our scrolling game
	fprintf(console, "\0331M\033C\0330A"); 

	//Clear both tilemaps
	memset(GFXTILEMAPA,0,0x4000);
	memset(GFXTILEMAPB,0,0x4000);
	//Clear sprites that IPL may have loaded
	memset(GFXSPRITES,0,0x4000);

	//Draw the ground on the tilemap, probably inefficient but we're learning here
	//Tilemap is 64 wide. Fille the entire bottom row with grass
	for (uint8_t x=0; x<64; x++) {
		__tile_a_set(x, FLAPPY_GROUND_Y, FLAPPY_GROUND_INDEX);
	}

	//The user can still see nothing of this graphics goodness, so let's re-enable the framebuffer and
	//tile layer A (the default layer for the console). 
	//Normal FB enabled (vice 8 bit) because background is loaded into the framebuffer above in 4 bit mode. 
	//TILEA is where text is printed by default
	 GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEA|GFX_LAYEREN_TILEB|GFX_LAYEREN_SPR;

	//Draw the player as a brick. Need to use our custome tilemap so we have a real sprite or figure
	//out how sprites work in the graphics engine
	 

	//Primary game loop
	float dy=0;
	float dx=0;
	int game_over = 0;
	 while(!game_over) {

		//Move the tile layer b, each 1024 of dx is equal to one tile (or 16 pixels)
		__tile_a_translate((int)dx, (int)dy);
		dx += FLAPPY_SPEED;

		//Calculate true screen coordinates x coordinate of pipes
		int x1 = (((m_pipe_1_x << 10) - (int)dx) & 0xFFFF) >> 6;
		int x2 = (((m_pipe_2_x << 10) - (int)dx) & 0xFFFF) >> 6;
		int x3 = (((m_pipe_3_x << 10) - (int)dx) & 0xFFFF) >> 6;
		int x4 = (((m_pipe_4_x << 10) - (int)dx) & 0xFFFF) >> 6;

		//Periodically update user y position and check for jumping
		if ((m_score % 300) == 0) {
			m_player_y += m_player_velocity;

			//Collision detection
			if (m_player_y >= FLAPPY_BOTTOM_EXTENT) {
				game_over = 1;
				m_player_y = 272;
			}

			//Jump when user presses button
			if (MISC_REG(MISC_BTN_REG)) {
				m_player_velocity = 0;
				m_player_y += FLAPPY_JUMP;
				__sprite_set(0, FLAPPY_PLAYER_X*16, m_player_y, 32, 32, FLAPPY_PLAYER_JUMP_INDEX, 0);	
				synth_play_flap();
			} else {
				m_player_velocity += FLAPPY_GRAVITY;
				__sprite_set(0, FLAPPY_PLAYER_X*16, m_player_y, 32, 32, FLAPPY_PLAYER_INDEX, 0);	
			}

			//Test collision against any pipes, but use our made up minimum score values to only test after the pipes
			//are created
			if (m_score > 8000) {
				game_over |=
					__collision_test(x3, m_pipe_3_height) ||
					__collision_test(x4, m_pipe_4_height);
			}
			if (m_score > 25000) {
				game_over |= 
					__collision_test(x1, m_pipe_1_height) ||
					__collision_test(x2, m_pipe_2_height);
			}
		}

		//Generate 4 pipes with fixed heights so it's easy to get started
		//Only generate the pipes as they make progress
		//The 8000 and 25000 values are arbitrary but defer pipe creation _just_ enough
		if (m_score == 8000) {
			__create_pipe(m_pipe_3_x, m_pipe_3_height);
			__create_pipe(m_pipe_4_x, m_pipe_4_height);
		} else if (m_score == 25000) {
			__create_pipe(m_pipe_1_x, m_pipe_1_height);
			__create_pipe(m_pipe_2_x, m_pipe_2_height);
		}
			
		//Detect a pipe about to enter from right side of screen, in this case generate
		//A new pipe at that same tile x coord so it appears we have infinite scrolling
		//Screen is 480 wide so 500 is good enough
		if (x1 == 500) {
			// m_pipe_1_height = (rand() % (FLAPPY_PIPE_HEIGHT_MIN - FLAPPY_PIPE_HEIGHT_MAX)) + FLAPPY_PIPE_HEIGHT_MIN;
			__create_pipe(m_pipe_1_x, m_pipe_1_height);
		}

		if (x2 == 500) {
			// m_pipe_2_height = (rand() % (FLAPPY_PIPE_HEIGHT_MIN - FLAPPY_PIPE_HEIGHT_MAX)) + FLAPPY_PIPE_HEIGHT_MIN;
			__create_pipe(m_pipe_2_x, m_pipe_2_height);
		}

		if (x3 == 500) {
			// m_pipe_3_height = (rand() % (FLAPPY_PIPE_HEIGHT_MIN - FLAPPY_PIPE_HEIGHT_MAX)) + FLAPPY_PIPE_HEIGHT_MIN;
			__create_pipe(m_pipe_3_x, m_pipe_3_height);
		}

		if (x4 == 500) {
			// m_pipe_4_height = (rand() % (FLAPPY_PIPE_HEIGHT_MIN - FLAPPY_PIPE_HEIGHT_MAX)) + FLAPPY_PIPE_HEIGHT_MIN;
			__create_pipe(m_pipe_4_x, m_pipe_4_height);
		}

		//Print score at 0,0
		//NOTE: this seems to be a *very* slow operation. Adding a second fprintf will have a noticeable
		//slowdown effect. Removing this fprintf will put the game into ludicrous speed mode. Need to fix!
		fprintf(console, "\0330X\0330Y%dm\03324XFLAPPY", (m_score >> 10)); 

		//Flappy score increases with distance which is simply a function of time
		m_score++;
	 }

	 synth_play_game_over();
	 //Print game over
	 fprintf(console, "\03310X\03310YGAME OVER!\nScore: %dm", (m_score/1000));

	 //Wait for user to release whatever buttons they were pressing and to press a new one
	__button_wait_for_release();
	__INEFFICIENT_delay(200);
 	__button_wait_for_press();

	//Clear both tilemaps
	memset(GFXTILEMAPA,0,0x4000);
	memset(GFXTILEMAPB,0,0x4000);
	//Clear sprites that IPL may have loaded
	memset(GFXSPRITES,0,0x4000);
}
