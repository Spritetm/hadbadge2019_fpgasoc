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
	tb->addr=addr;
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
	for (int i=0; i<256; i++) {
		int p;
		p=vgapal[i*3];
		p|=vgapal[i*3+1]<<8;
		p|=vgapal[i*3+2]<<16;
		p|=(0xff<<24);
		tb_write(PAL_OFF+(i*4), p);
		tb_write(PAL_OFF+((i+256)*4), p);
	}

	// Set some of the remaining palette colors
	tb_write(PAL_OFF+(0x100*4), 0xffff00ff);
	tb_write(PAL_OFF+((0x1ff)*4), 0x10ff00ff);
}

// Set a sprite's position, scale and tile number
void set_sprite(int no, int x, int y, int sx, int sy, int tileno) {
	uint32_t sa, sb;
	x+=64;
	y+=64;
	sa=(y<<16)|x;
	sb=sx|(sy<<8)|(tileno<<16);
	printf("Sprite %d: %08X %08X\n", no, sa, sb);
	tb_write(SPRITE_OFF+no*8, sa);
	tb_write(SPRITE_OFF+no*8+4, sb);
}