#include <stdlib.h>
#include "Vvid.h"
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "video_renderer.hpp"
#include <gd.h>
#include <stdint.h>
#include "vgapal.h"

uint64_t ts=0;
double sc_time_stamp() {
	return ts;
}


void tb_write(Vvid *tb, VerilatedVcdC *trace, int addr, int data) {
	tb->addr=addr;
	tb->din=data;
	tb->wstrb=0xf;
	do {
		tb->eval();
		tb->clk=1;
		tb->eval();
		if (trace) trace->dump(ts++);
		tb->clk=0;
		tb->eval();
		if (trace) trace->dump(ts++);
	} while (tb->ready==0);
	tb->wstrb=0x0;
}

#define REG_OFF 0x0000
#define PAL_OFF 0x2000
#define TILEMAPA_OFF 0x4000
#define TILEMAPB_OFF 0x8000
#define SPRITE_OFF 0xC000
#define TILEMEM_OFF 0x10000

void set_sprite(Vvid *tb, VerilatedVcdC *trace, int no, int x, int y, int sx, int sy, int tileno) {
	uint32_t sa, sb;
	x+=64;
	y+=64;
	sa=(y<<16)|x;
	sb=sx|(sy<<8)|(tileno<<16);
	printf("Sprite %d: %08X %08X\n", no, sa, sb);
	tb_write(tb, trace, SPRITE_OFF+no*8, sa);
	tb_write(tb, trace, SPRITE_OFF+no*8+4, sb);
}

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
//				c=x; //HACK
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
//			tb_write(tb, trace, TILEMAPA_OFF+pos*4, ((tile+1)<<16)|tile);
			pos++;
			tile+=2;
		}
	}

	gdImageDestroy(im);
	fclose(f);
}

int qpi_cur_adr;
int qpi_state=0;
uint8_t qpi_mem[1024*1024];
void qpi_eval(int clk, int qpi_addr, int qpi_do_read, int *qpi_is_idle, int *qpi_next_word, uint32_t *qpi_rdata) {
	if (clk) {
		*qpi_next_word=0;
		if (qpi_state==0) {
			if (qpi_do_read) {
//				printf("Read from %x\n", qpi_addr);
				qpi_cur_adr=qpi_addr;
				*qpi_is_idle=0;
				qpi_state=1;
			} else {
				*qpi_is_idle=1;
			}
		} else if (qpi_state==4) {
			qpi_state=1;
			*qpi_next_word=1;
			qpi_cur_adr &= 0xffffc;
			(*qpi_rdata)=qpi_mem[qpi_cur_adr++];
			(*qpi_rdata)|=qpi_mem[qpi_cur_adr++]<<8;
			(*qpi_rdata)|=qpi_mem[qpi_cur_adr++]<<16;
			(*qpi_rdata)|=qpi_mem[qpi_cur_adr++]<<24;

			if (!qpi_do_read) {
				*qpi_is_idle=1;
				qpi_state=0;
			}
		} else  {
			qpi_state++;
		}
	}
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

	FILE *f=fopen("background.raw", "r");
	if (!f) perror("raw fb data");
	for (int i=0; i<320; i++) {
		fread(&qpi_mem[512*i], 480, 1, f);
	}
	fclose(f);

	tb->reset=1;
	tb->ren=0;
	for (int i=0; i<16; i++) {
		tb->clk = 1;
		tb->eval();
		trace->dump(ts++);
		tb->clk = 0;
		tb->eval();
		trace->dump(ts++);
		if (i==8) tb->reset=0;
	}
	
	for (int i=0; i<256; i++) {
		int p;
		p=vgapal[i*3];
		p|=vgapal[i*3+1]<<8;
		p|=vgapal[i*3+2]<<16;
		p|=(0xff<<24);
		tb_write(tb, trace, PAL_OFF+(i*4), p);
		tb_write(tb, trace, PAL_OFF+((i+256)*4), p);
	}

//	tb_write(tb, trace, PAL_OFF+(0x100*4), 0xffff00ff);
	tb_write(tb, trace, PAL_OFF+((0x1ff)*4), 0x10ff00ff);


	load_tilemap(tb, trace, "tileset.png");
	printf("Buffers inited.\n");
	tb_write(tb, trace,REG_OFF+2*4, 0x8); //ena sprites
//	for (int i=0; i<10; i++) {
//		set_sprite(tb, trace, i*2, i*32+64, 64, i*2+1, i*2+1, 0);
//	}
	set_sprite(tb, trace, 2, 0, 0, 16, 16, 8);
	set_sprite(tb, trace, 3, 470, 16, 64, 16, 8);

	int fetch_next=0;
	int next_line=0;
	int next_field=0;
	float pixelclk_pos=0;
	int qpi_is_idle=0, qpi_next_word=0;
	uint32_t qpi_rdata=0;
	int layer=0;
	while(1) {
		tb->pixelclk = (pixelclk_pos>0.5)?1:0;
		tb->clk = !tb->clk;
		qpi_eval(tb->clk, tb->qpi_addr, tb->qpi_do_read, &qpi_is_idle, &qpi_next_word, &qpi_rdata);
		tb->qpi_rdata=qpi_rdata;
		tb->qpi_is_idle=qpi_is_idle;
		tb->qpi_next_word=qpi_next_word;
		tb->eval();
		trace->dump(ts++);
		tb->clk = !tb->clk;
		tb->eval();
		trace->dump(ts++);

		pixelclk_pos=pixelclk_pos+0.26;
		if (pixelclk_pos>1.0) {
			pixelclk_pos-=1.0;
			vid->next_pixel(tb->red, tb->green, tb->blue, &fetch_next, &next_line, &next_field);
			tb->fetch_next=fetch_next;
//			if (tb->next_field==0 && next_field==1) {
//				layer=(layer+1)&0xf;
//				tb_write(tb, trace,REG_OFF+2*4, 0x10000|layer);
//				printf("Layer: %x\n", layer);
//			}
			tb->next_field=next_field;
			tb->next_line=next_line;
		}
	}
	trace->flush();

	trace->close();
	exit(EXIT_SUCCESS);
}