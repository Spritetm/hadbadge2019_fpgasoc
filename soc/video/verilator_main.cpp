#include <stdlib.h>
#include "Vvid.h"
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "video_renderer.hpp"
#include <gd.h>

uint64_t ts=0;
double sc_time_stamp() {
	return ts;
}


void tb_write(Vvid *tb, VerilatedVcdC *trace, int addr, int data) {
	tb->addr=addr;
	tb->din=data;
	tb->wstrb=0xf;
	do {
		tb->clk=1;
		tb->eval();
		if (trace) trace->dump(ts++);
		tb->clk=0;
		tb->eval();
		if (trace) trace->dump(ts++);
	} while (tb->ready==0);
}

#define REG_OFF 0x0000
#define PAL_OFF 0x2000
#define TILEMAPA_OFF 0x4000
#define TILEMAPB_OFF 0x8000
#define TILEMEM_OFF 0x10000


void load_tilemap(Vvid *tb, VerilatedVcdC *trace, char *file) {
	FILE *f=fopen(file, "r");
	if (file==NULL) {
		perror(file);
		exit(1);
	}
	gdImagePtr im=gdImageCreateFromPng(f);
	int tx=0, ty=0;
	int tile;
	for (tile=0; tile<512; tile++) {
		for (int y=0; y<16; y++) {
			uint64_t p;
			for (int x=0; x<16; x++) {
				p>>=4;
				int c=gdImageGetPixel(im, tx+x, ty+y);
				p|=((uint64_t)c)<<60ULL;
			}
			tb_write(tb, tile<3?trace:NULL, TILEMEM_OFF+(tile*32+y*2+0)*4, p&0xFFFFFFFF);
			tb_write(tb, tile<3?trace:NULL, TILEMEM_OFF+(tile*32+y*2+1)*4, p>>32ULL);
		}
		
		tx+=16;
		if (tx>=gdImageSX(im)) {
			tx=0;
			ty+=16;
			if (ty>gdImageSY(im)) break;
		}
	}
	printf("Loaded %d tiles from tileset of %dx%d pixels.\n", tile, gdImageSX(im), gdImageSY(im));
	tile=0;
	int pos=0;
	for (int y=0; y<64; y++) {
		tile=y*(gdImageSX(im)/16);
		for (int x=0; x<64; x+=2) {
			tb_write(tb, NULL, TILEMAPA_OFF+pos*4, ((tile+1)<<16)|tile);
			pos++;
			tile+=2;
		}
	}

	gdImageDestroy(im);
	fclose(f);
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

	tb_write(tb, trace, PAL_OFF+0x00, 0x000000); 
	tb_write(tb, trace, PAL_OFF+0x04, 0x00007f); 
	tb_write(tb, trace, PAL_OFF+0x08, 0x007f00); 
	tb_write(tb, trace, PAL_OFF+0x0c, 0x007f7f); 
	tb_write(tb, trace, PAL_OFF+0x10, 0x7f0000); 
	tb_write(tb, trace, PAL_OFF+0x14, 0x7f007f); 
	tb_write(tb, trace, PAL_OFF+0x18, 0x7f7f00); 
	tb_write(tb, trace, PAL_OFF+0x1c, 0x7f7f7f); 
	tb_write(tb, trace, PAL_OFF+0x20, 0x3f3f3f); 
	tb_write(tb, trace, PAL_OFF+0x24, 0x0000ff); 
	tb_write(tb, trace, PAL_OFF+0x28, 0x00ff00); 
	tb_write(tb, trace, PAL_OFF+0x2c, 0x00ffff); 
	tb_write(tb, trace, PAL_OFF+0x30, 0xff0000); 
	tb_write(tb, trace, PAL_OFF+0x34, 0xff00ff); 
	tb_write(tb, trace, PAL_OFF+0x38, 0xffff00); 
	tb_write(tb, trace, PAL_OFF+0x3c, 0xffffff); 
	load_tilemap(tb, trace, "tileset.png");
	printf("Buffers inited.\n");
	tb_write(tb, trace,REG_OFF+2*4, 0x2); //ena tile map a
//	tb_write(tb, trace,REG_OFF+2*4, 0x1); //ena fb

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