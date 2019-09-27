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

	Video_renderer *vid=new Video_renderer(true);

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

	printf("Buffers inited.\n");

	int fetch_next=0;
	int next_line=0;
	int next_field=0;
	float pixelclk_pos=0;
	while(1) {
		tb->pixelclk = (pixelclk_pos>0.5)?1:0;
		tb->clk = !tb->clk;
		tb->eval();
		trace->dump(ts++);

		pixelclk_pos=pixelclk_pos+0.26;
		if (pixelclk_pos>1.0) {
			pixelclk_pos-=1.0;
			vid->next_pixel(tb->red, tb->green, tb->blue, &fetch_next, &next_line, &next_field);
			tb->fetch_next=fetch_next;
			tb->next_line=next_line;
			tb->next_field=next_field;
		}
	}
	trace->flush();

	trace->close();
	exit(EXIT_SUCCESS);
}