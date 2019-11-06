#pragma once

#include "Vvid.h"
#include <verilated_vcd_c.h>

// These match constants from ../../ipl/gloss/mach_defines.h
#define REG_OFF      0x0000
#define PAL_OFF      0x2000
#define TILEMAPA_OFF 0x4000
#define TILEMAPB_OFF 0x8000
#define SPRITE_OFF   0xC000
#define TILEMEM_OFF 0x10000
#define COPPER_OFF  0x20000

// Trace machinery
extern uint64_t ts;
double sc_time_stamp();
// tb (test bench) contains a line renderer and video memory controller
extern Vvid *tb;
// trace is non-null if verilator tracing is on
extern VerilatedVcdC *trace;

// Evaluate model, advance time and optionally trace
void tb_step(bool trace_exempt=false);

// Create the test bench
void init_test_bench(bool trace_on);

// Clock data out to a given register in video subsystem.
// This clocks the video testbench main clock without also updating pixelclk.
// For this reason, updates made while system is processing main loop may not
// be properly interpreted.
void tb_write(int addr, int data, bool trace_exempt=false);

// Send reset signal to test bench
void toggle_reset();

// Load a default palette
void load_default_palette();

// Set a sprite's position, scale and tile number
void set_sprite(int no, int x, int y, int sx, int sy, int tileno);

// Load a tile into memory from a 256 char string
// 0-9a-f are the 16 colors. 
// A-F aliases a-f
// All other characters -> lower 4 bits are used
void load_tile(int no, const char *s);
