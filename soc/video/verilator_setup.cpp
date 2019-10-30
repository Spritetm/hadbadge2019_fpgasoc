#include "verilator_setup.hpp"
#include "vgapal.h"

// Trace globals
uint64_t ts=0;
double sc_time_stamp() {
	return ts;
}
Vvid *tb = NULL;
VerilatedVcdC *trace = NULL;

// Evaluate model, advance time and optionally trace
void tb_step(bool trace_exempt) { 
	tb->eval(); 
	if (trace && !trace_exempt) trace->dump(ts); 
	ts++;
}

// Create the test bench
void init_test_bench(bool trace_on) {
	tb = new Vvid;
	if (trace_on) {
		trace = new VerilatedVcdC;
		tb->trace(trace, 99);
		trace->open("vidtrace.vcd");
	}
}

// Clock data out to a given register in video subsystem.
void tb_write(int addr, int data, bool trace_exempt) {
	tb->addr=addr & 0x1ffffff; // Only top 25 bits used
	tb->din=data;
	tb->wstrb=0xf;
	do {
		tb->eval();
		tb->clk=1;
		tb_step(trace_exempt);
		tb->clk=0;
		tb_step(trace_exempt);
	} while (tb->ready==0);
	tb->wstrb=0x0;
}

uint32_t tb_read(int addr, bool trace_exempt) {
	tb->addr=addr & 0x1ffffff; // Only top 25 bits used
	tb->ren=1;
	tb->eval();
	tb->clk=1;
	tb_step(trace_exempt);
	tb->clk=0;
	tb_step(trace_exempt);	
	uint32_t result = tb->dout;
	tb->ren=0;
	return result;
}

// SDK-style access
RegisterPointer GFXREG(GFX_OFFSET_REGS);
RegisterPointer GFXPAL(GFX_OFFSET_PAL);
RegisterPointer GFXTILES(GFX_OFFSET_TILEMEM);
RegisterPointer GFXTILEMAPA(GFX_OFFSET_TILEMAPA);
RegisterPointer GFXTILEMAPB(GFX_OFFSET_TILEMAPB);
RegisterPointer GFXSPRITES(GFX_OFFSET_SPRITE);

// Send reset signal to test bench
void toggle_reset() {
	tb->reset=1;
	tb->ren=0;
	for (int i=0; i<16; i++) {
		tb->clk = 1;
		tb_step();
		tb->clk = 0;
		tb_step();
		if (i==8) tb->reset=0;
	}	
}

// Load a default palette
void load_default_palette() {
	// Set first 256 colors of palette to standard VGA colors 
	// Set second 256 colors to be the same
	for (int i=0; i<256; i++) {
		int p;
		p=vgapal[i*3];
		p|=vgapal[i*3+1]<<8;
		p|=vgapal[i*3+2]<<16;
		p|=(0xff<<24);
		GFXPAL[i] = p;
		GFXPAL[i+256] = p;
	}

	// Reset some of the second 256 colors
	GFXPAL[0x100] = 0xffff00ff;
	GFXPAL[0x1ff] = 0x10ff00ff;
}

// Set a sprite's position, scale and tile number
void set_sprite(int no, int x, int y, int sx, int sy, int tileno) {
	uint32_t sa, sb;
	x+=64;
	y+=64;
	sa=(y<<16)|x;
	sb=sx|(sy<<8)|(tileno<<16);
	printf("Sprite %d: %08X %08X\n", no, sa, sb);
	GFXSPRITES[no*2] = sa;
	GFXSPRITES[no*2+1] = sb;
}

// Load a tile into memory from a 256 char string
// 0-9a-f are the 16 colors. 
// A-F aliases a-f
// All other characters -> lower 4 bits are used
void load_tile(int tile, const char *s) {
	uint32_t eight_pix;
	for (int i = 0; s[i] && i < 256; i++) {
		char c = s[i];
		int v = 0;
		if ('a' <= c && c <= 'f') {
			v = c - 'a' + 10;
		} else if ('A' <= c && c <= 'F') {
			v = c - 'A' + 10;
		} else {
			v = c & 0xf;
		}
		eight_pix = (v << 28) | (eight_pix >> 4);
		if (i % 8 == 7) {
			GFXTILES[tile*32+i/8] = eight_pix;
		}
	}
}