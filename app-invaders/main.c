#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cache.h"
#include "gfx_load.h"
#include "mach_defines.h"
#include "sdk.h"

// The bgnd.png image got linked into the binary of this app, and these two
// chars are the first and one past the last byte of it.
extern char _binary_bgnd_png_start;
extern char _binary_bgnd_png_end;
extern char _binary_invaders_tileset_png_start;
extern char _binary_invaders_tileset_png_end;

// Pointer to the framebuffer memory.
uint8_t* fbmem;

#define FB_WIDTH 512
#define FB_HEIGHT 320
#define FB_PAL_OFFSET 256

// Horizontal velocity of player per frame
#define PLAYER_VELOCITY 1
#define PLAYER_Y 290
#define PLAYER_INDEX 129
#define PLAYER_SPRITE_INDEX 0
#define ALIEN_VELOCITY_X (0.05f)
#define ALIEN_VELOCITY_Y (10.0f)

#define ALIEN_COUNT 24
#define ALIEN_TOP_INDEX 128
#define BULLET_SPRITE_INDEX_START 4
#define BULLET_COUNT 4
#define BULLET_INDEX 131
#define BULLET_START_Y (15 * 16)
#define BULLET_FIRING_PERIOD 10000

// extern volatile uint32_t MISC[];
// #define MISC_REG(i) MISC[(i) / 4]
// extern volatile uint32_t GFXREG[];
// #define GFX_REG(i) GFXREG[(i) / 4]

typedef enum {
  alien_state_alive,
  alien_state_dead,
  __alien_state_count
} alien_state_t;

typedef struct {
  int x;
  int y;
  alien_state_t state;
} alien_t;

typedef struct {
  int x;
  int y;
} bullet_t;

uint8_t m_bullet_index = 0;

// Manually point to sprites memory location
uint32_t* GFXSPRITES = (uint32_t*)0x5000C000;

// Borrowed this from lcd.c until a better solution comes along :/
static void __INEFFICIENT_delay(int n) {
  for (int i = 0; i < n; i++) {
    for (volatile int t = 0; t < (1 << 11); t++)
      ;
  }
}

// Wait until all buttons are released
static inline void __button_wait_for_press() {
  while (MISC_REG(MISC_BTN_REG) == 0)
    ;
}

// Wait until all buttons are released
static inline void __button_wait_for_release() {
  while (MISC_REG(MISC_BTN_REG))
    ;
}

/**
 * Helper function to get the current 32-bit frame counter
 */
static inline uint32_t __counter() {
  return GFX_REG(GFX_VBLCTR_REG);
}

static inline void __sprite_set(int index,
                                int x,
                                int y,
                                int size_x,
                                int size_y,
                                int tile_index,
                                int palstart) {
  x += 64;
  y += 64;
  GFXSPRITES[index * 2] = (y << 16) | x;
  GFXSPRITES[index * 2 + 1] =
      size_x | (size_y << 8) | (tile_index << 16) | ((palstart / 4) << 25);
}

// Helper function to set a tile on layer a
static inline void __tile_a_set(uint8_t x, uint8_t y, uint32_t index) {
  GFXTILEMAPA[y * GFX_TILEMAP_W + x] = index;
}

// Helper function to set a tile on layer b
static inline void __tile_b_set(uint8_t x, uint8_t y, uint32_t index) {
  GFXTILEMAPB[y * GFX_TILEMAP_W + x] = index;
}

// Helper function to move tile layer 1
static inline void __tile_a_translate(int dx, int dy) {
  GFX_REG(GFX_TILEA_OFF) = (dy << 16) + (dx & 0xffff);
}

// Helper function to move tile layer b
static inline void __tile_b_translate(int dx, int dy) {
  GFX_REG(GFX_TILEB_OFF) = (dy << 16) + (dx & 0xffff);
}

/**
 * Render a single alien to the tilemap
 */
static inline void __render_alien(alien_t* p_alien) {
  __tile_b_set(p_alien->x, p_alien->y, ALIEN_TOP_INDEX);
  __tile_b_set(p_alien->x, p_alien->y + 1, ALIEN_TOP_INDEX + 16);
  __tile_b_set(p_alien->x, p_alien->y + 2, ALIEN_TOP_INDEX + 32);
}

void main(int argc, char** argv) {
  // Allocate framebuffer memory
  fbmem = malloc(320 * 512 / 2);

  // Set up the framebuffer address.
  GFX_REG(GFX_FBADDR_REG) = ((uint32_t)fbmem) & 0xFFFFFF;
  // We're going to use a pitch of 512 pixels, and the fb palette will start at
  // 256.
  GFX_REG(GFX_FBPITCH_REG) =
      (FB_PAL_OFFSET << GFX_FBPITCH_PAL_OFF) | (512 << GFX_FBPITCH_PITCH_OFF);
  // Blank out fb while we're loading stuff.
  GFX_REG(GFX_LAYEREN_REG) = 0;

  // Load up the default tileset and font.
  // ToDo: loading pngs takes a long time... move over to pcx instead.
  printf("Loading tiles...\n");
  int gfx_tiles_err = gfx_load_tiles_mem(GFXTILES, &GFXPAL[0],
                                         &_binary_invaders_tileset_png_start,
                                         (&_binary_invaders_tileset_png_end -
                                          &_binary_invaders_tileset_png_start));
  printf("Tiles initialized err=%d\n", gfx_tiles_err);

  // The IPL leaves us with a tileset that has tile 0 to 127 map to ASCII
  // characters, so we do not need to load anything specific for this. In order
  // to get some text out, we can use the /dev/console device that will use
  // these tiles to put text in a tilemap. It uses escape codes to do so, see
  // ipl/gloss/console_out.c for more info.
  // Note that without the setvbuf command, no characters would be printed until
  // 1024 characters are buffered.
  FILE* console = fopen("/dev/console", "w");
  setvbuf(console, NULL, _IOLBF, 1024);  // make console line buffered
  if (console == NULL) {
    printf("Error opening console!\n");
  }

  // we tell it to start writing from entry 0.
  // Now, use a library function to load the image into the framebuffer memory.
  // This function will also set up the palette entries, PAL offset changes the
  // colors that the 16-bit png maps to?
  gfx_load_fb_mem(fbmem, &GFXPAL[FB_PAL_OFFSET], 4, 512,
                  &_binary_bgnd_png_start,
                  (&_binary_bgnd_png_end - &_binary_bgnd_png_start));

  // Flush the memory region to psram so the GFX hw can stream it from there.
  cache_flush(fbmem, fbmem + FB_WIDTH * FB_HEIGHT);

  // Copied from IPL not sure why yet
  GFX_REG(GFX_LAYEREN_REG) =
      GFX_LAYEREN_FB | GFX_LAYEREN_TILEB | GFX_LAYEREN_TILEA | GFX_LAYEREN_SPR;
  GFXPAL[FB_PAL_OFFSET + 0x100] =
      0x00ff00ff;  // Note: For some reason, the sprites use this as default
                   // bgnd. ToDo: fix this...
  GFXPAL[FB_PAL_OFFSET + 0x1ff] = 0x40ff00ff;  // so it becomes this instead.

  __button_wait_for_release();

  // Set map to tilemap B, clear tilemap, set attr to 0
  // Not sure yet what attr does, but tilemap be is important as it will have
  // the effect of layering on top of our scrolling game
  fprintf(console, "\0331M\033C\0330A");
  // Note that without the newline at the end, all printf's would stay in the
  // buffer.

  // Clear both tilemaps
  memset(GFXTILEMAPA, 0, 0x4000);
  memset(GFXTILEMAPB, 0, 0x4000);
  // Clear sprites that IPL may have loaded
  memset(GFXSPRITES, 0, 0x4000);

  // The user can still see nothing of this graphics goodness, so let's
  // re-enable the framebuffer and tile layer A (the default layer for the
  // console). Normal FB enabled (vice 8 bit) because background is loaded into
  // the framebuffer above in 4 bit mode. TILEA is where text is printed by
  // default
  GFX_REG(GFX_LAYEREN_REG) =
      GFX_LAYEREN_FB | GFX_LAYEREN_TILEA | GFX_LAYEREN_TILEB | GFX_LAYEREN_SPR;

  // Generate the aliens
  alien_t aliens[ALIEN_COUNT];
  uint8_t x = 1, y = 1;
  for (uint8_t i = 0; i < ALIEN_COUNT; i++) {
    aliens[i].state = alien_state_alive;
    aliens[i].x = x;
    aliens[i].y = y;
    x += 2;
    if (x >= 17) {
      x = 1;
      y += 3;
    }
  }

  // Render the aliens onto the tilemap
  for (uint8_t i = 0; i < ALIEN_COUNT; i++) {
    __render_alien(&aliens[i]);
  }

  // Bullet storage
  bullet_t bullets[BULLET_COUNT];
  // Start bullets off screen. -16 is a magic value YOLO
  for (uint8_t i = 0; i < BULLET_COUNT; i++) {
    bullets[i].y = -16;
  }

  // Primary game loop
  int game_over = 0;
  int player_x = 0;
  float alien_dx = 0;
  float alien_dy = 0;
  uint32_t last_frame;
  uint32_t counter = 0;
  uint32_t next_fire = counter + BULLET_FIRING_PERIOD;

  while (!game_over) {
    if (MISC_REG(MISC_BTN_REG) & BUTTON_B) {
      game_over = 1;
    }

    // Periodically move and re-draw
    if ((counter % 300) == 0) {
      // Player move left
      if (MISC_REG(MISC_BTN_REG) & BUTTON_LEFT) {
        player_x -= PLAYER_VELOCITY;
      }
      // Player move right
      if (MISC_REG(MISC_BTN_REG) & BUTTON_RIGHT) {
        player_x += PLAYER_VELOCITY;
      }

      // Player sprites
      __sprite_set(PLAYER_SPRITE_INDEX, player_x - 16, PLAYER_Y - 16, 16, 16,
                   PLAYER_INDEX, 0);
      __sprite_set(PLAYER_SPRITE_INDEX + 1, player_x, PLAYER_Y - 16, 16, 16,
                   PLAYER_INDEX + 1, 0);
      __sprite_set(PLAYER_SPRITE_INDEX + 2, player_x - 16, PLAYER_Y, 16, 16,
                   PLAYER_INDEX + 16, 0);
      __sprite_set(PLAYER_SPRITE_INDEX + 3, player_x, PLAYER_Y, 16, 16,
                   PLAYER_INDEX + 17, 0);

      // Bullets move and draw
      for (uint8_t i = 0; i < BULLET_COUNT; i++) {
        // Only move if bullets are on screen
        if (bullets[i].y > -16) {
          __sprite_set(BULLET_SPRITE_INDEX_START + i, bullets[i].x,
                       bullets[i].y, 16, 16, BULLET_INDEX, 0);
          bullets[i].y--;
        }
      }

      // Fire a bullet when A pressed
      if ((MISC_REG(MISC_BTN_REG) & BUTTON_A) && (counter > next_fire)) {
        // Only fire if we can re-use an offscreen bullet
        if (bullets[m_bullet_index].y <= -16) {
          bullets[m_bullet_index].x = player_x;
          bullets[m_bullet_index].y = BULLET_START_Y;
          m_bullet_index = (m_bullet_index + 1) % BULLET_COUNT;

          // Limit how often they can shoot
          next_fire = counter + BULLET_FIRING_PERIOD;
        }
      }
    }

    alien_dx -= ALIEN_VELOCITY_X;
    if (alien_dx < 0 - (1024 * 14)) {
      alien_dx = 0;
      alien_dy -= 512;
    }

    // Move alien tiles
    __tile_b_translate(alien_dx, alien_dy);
    last_frame = __counter();
    counter++;
  }

  // Print game over
  // fprintf(console, "\03310X\03310YGAME OVER!\nScore: %dm", (m_score / 1000));

  // Wait for user to release whatever buttons they were pressing and to press a
  // new one
  __button_wait_for_release();
  __INEFFICIENT_delay(200);
  __button_wait_for_press();

  // Clear both tilemaps
  memset(GFXTILEMAPA, 0, 0x4000);
  memset(GFXTILEMAPB, 0, 0x4000);
  // Clear sprites that IPL may have loaded
  memset(GFXSPRITES, 0, 0x4000);
}
