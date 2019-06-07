#include <stdlib.h>
#include "Vvid.h"
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "video_renderer.hpp"

uint64_t ts=0;
double sc_time_stamp() {
	return ts;
}


void tb_write(Vvid *tb, VerilatedVcdC *trace, int addr, int data) {
	tb->addr=addr;
	tb->din=data;
	tb->wen=1;
	do {
		tb->clk=1;
		tb->eval();
		trace->dump(ts++);
		tb->clk=0;
		tb->eval();
		trace->dump(ts++);
	} while (tb->ready==0);
}


int main(int argc, char **argv) {
	// Initialize Verilators variables
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	// Create an instance of our module under test
	Vvid *tb = new Vvid;
	//Create trace
	VerilatedVcdC *trace = new VerilatedVcdC;
	tb->trace(trace, 99);
	trace->open("vidtrace.vcd");

	Video_renderer *vid=new Video_renderer();

	tb->reset=1;
	tb->ren=0;
	for (int i=0; i<8; i++) {
		tb->clk = 1;
		tb->eval();
		trace->dump(ts++);
		tb->clk = 0;
		tb->eval();
		trace->dump(ts++);
	}
	tb->reset=0;

	///Init default palette
	for (int x=0; x<16; x++) {
		int d=(x>7)?0xff:0x80;
		tb_write(tb, trace, x*4, ((x&1)?(d<<16):0)|((x&2)?(d<<8):0)|((x&4)?(d<<0):0));
	}

	//init line buffers
	int v=0x12345678;
	for (int l=0; l<4; l++) {
		int line_offset=4*512*l+(1<<20);
		for (int x=0; x<480; x+=8) {
			v+=0x11111111;
			tb_write(tb, trace, line_offset+x*4, v);
		}
	}

	printf("Buffers inited.\n");

	int fetch_next=0;
	int next_line=0;
	int next_field=0;
	while(1) {
		tb->pixelclk = 1;
		tb->clk = 1;
		tb->eval();
		trace->dump(ts++);
		tb->clk = 0;
		tb->eval();
		trace->dump(ts++);
		tb->pixelclk = 0;
		tb->clk = 1;
		tb->eval();
		trace->dump(ts++);
		tb->clk = 0;
		tb->eval();
		trace->dump(ts++);
		vid->next_pixel(tb->red, tb->green, tb->blue, &fetch_next, &next_line, &next_field);
		tb->fetch_next=fetch_next;
		tb->next_line=next_line;
		tb->next_field=next_field;
	};
	trace->flush();

	trace->close();
	exit(EXIT_SUCCESS);
}