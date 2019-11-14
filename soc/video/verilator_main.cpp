#include <string>
#include <stdlib.h>
#include <verilated.h>

#include "verilator_setup.hpp"
#include "verilator_options.hpp"
#include "video_renderer.hpp"
#include <gd.h>
#include <stdint.h>

#include "../ipl/gloss/mach_defines.h"


// Iterate over each 16x16 pixel block of a rectangular PNG file,
// loading tile memory.
void load_tilemap(const char *file) {
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
			tb_write(TILEMEM_OFF+(tile*32+y*2+0)*4, p&0xFFFFFFFF, tile>=3);
			tb_write(TILEMEM_OFF+(tile*32+y*2+1)*4, p>>32ULL, tile>=3);
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
//			tb_write(TILEMAPA_OFF+pos*4, ((tile+1)<<16)|tile);
			pos++;
			tile+=2;
		}
	}

	gdImageDestroy(im);
	fclose(f);
}

// Simulates a 1MB block of flash memory that takes 4 cycles to produce a result.
// Used by video memory controller.
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

// Loads an image from a png file into qpi memory at 8 bits resolution
// Returns the width of the image
unsigned load_png_to_qpi(const char *file, size_t addr) {
	FILE *f=fopen(file, "r");
	if (file==NULL) {
		perror(file);
		exit(1);
	}
	gdImagePtr im=gdImageCreateFromPng(f);
	unsigned sx = gdImageSX(im);
	unsigned sy = gdImageSY(im);
	for (unsigned y = 0; y < sy; y++) {
		for (int x = 0; x < sx; x++) {
			qpi_mem[addr++] = (uint8_t) gdImageGetPixel(im, x, y);
		}
	}

	return sx;
}

// Setup classic: the orignal-ish setup
void setup1() {
	// Load a tileset and palette for use by sprites
	load_tilemap("tileset-default.png");
	load_default_palette();
	printf("Buffers inited.\n");

	// Set up sprites: sprite 0 at 5, 5
	tb_write(REG_OFF+2*4, 0x8); //ena sprites
//	set_sprite(2, 5, 5, 16, 16, 0);

	int xp=0;
	int yp=100;
	for (int i=1; i<50; i++) {
		set_sprite(3+i, xp, yp-i, i, i, 65);
		xp+=i+1;
		yp-=2;
		if (xp>480) {
			xp=0;
			yp+=i+4+60;
		}
	}
}

// Setup 2: show the loaded background
void setup2() {
	// Load background.raw file into simulated flash
	FILE *f=fopen("background.raw", "r");
	if (!f) perror("raw fb data");
	for (int i=0; i<320; i++) {
		fread(&qpi_mem[512*i], 480, 1, f);
	}
	fclose(f);
	tb_write(REG_OFF+0, 0);
	tb_write(REG_OFF+4, (0 << 16) + 512);

	// Load a tileset and palette for use by sprites
	load_default_palette();

	// Enable frame buffer
	tb_write(REG_OFF+2*4, 0x10001);
}

// Setup 3: Tile layer A
void setup3() {
	// Load a tileset and palette
	// Just uses tile 0 everywhere
	load_tilemap("tileset.png");
	load_default_palette();
	tb_write(REG_OFF+2*4, 0x10002); // tileA
}

// Setup 4: Load a background
void setup4() {
	// Load a tileset and palette
	unsigned addr = 0x12340;
	unsigned width = load_png_to_qpi("../ipl/bgnd.png", addr);
	load_default_palette();

	// Set frame buffer at location addr
	tb_write(REG_OFF+0, addr);
	tb_write(REG_OFF+4, (0 << 16) + width);
	tb_write(REG_OFF+2*4, 0x10001); // 8 bit pixels, FB enabled
}

// Setup 5: Set tile 0 to be something useful for debugging HDMI horizontal output
// and use it to tile the whole window
void setup5() {
	// load a tile composed of 1 pixel wide green and black vertical stripes
	std::string s = "2 ";
	for (int i = 0; i < 7; i++) {
		s = s + s;
	}
	load_tile(0, s.c_str());
	load_default_palette();
	tb_write(REG_OFF+2*4, 0x10002); // all tile 0
}

// Setup 6: Copper test
void setup6() {
	// Load a tileset and palette
	// Just uses tile 0 everywhere
	load_tilemap("tileset.png");
	load_default_palette();
	tb_write(REG_OFF+2*4, 0x10000+2); // tileA
	int i=0;
	tb_write(COPPER_OFF+(i++)*4, COPPER_OP_WAIT(5, 5));
	tb_write(COPPER_OFF+(i++)*4, COPPER_OP_WRITE((REG_OFF+GFX_TILEA_OFF), 1));
	printf("Op %x\n", COPPER_OP_WRITE((REG_OFF+GFX_TILEA_OFF), 1));
	tb_write(COPPER_OFF+(i++)*4, 64*4);
	tb_write(COPPER_OFF+(i++)*4, COPPER_OP_WAIT(5, 6));
	tb_write(COPPER_OFF+(i++)*4, COPPER_OP_WRITE((REG_OFF+GFX_TILEA_OFF), 1));
	tb_write(COPPER_OFF+(i++)*4, 64*8);
	tb_write(COPPER_OFF+(i++)*4, COPPER_OP_WAIT(5, 7));
	tb_write(COPPER_OFF+(i++)*4, COPPER_OP_WRITE((REG_OFF+GFX_TILEA_OFF), 1));
	tb_write(COPPER_OFF+(i++)*4, 64*9);
	tb_write(COPPER_OFF+(i++)*4, COPPER_OP_WAIT(5, 8));
	tb_write(COPPER_OFF+(i++)*4, COPPER_OP_WRITE((REG_OFF+GFX_TILEA_OFF), 1));
	tb_write(COPPER_OFF+(i++)*4, 64*10);
	tb_write(COPPER_OFF+(i++)*4, COPPER_OP_WAIT(0, 0));
	tb_write(COPPER_OFF+(i++)*4, COPPER_OP_WRITE((REG_OFF+GFX_TILEA_OFF), 1));
	tb_write(COPPER_OFF+(i++)*4, 0);
	tb_write(COPPER_OFF+(i++)*4, COPPER_OP_RESET);
	tb_write(REG_OFF+GFX_COPPER_CTL_REG, (1<<31));
}


// Array of all setups - defined in verilator_options.hpp
setup_fn setups[] = {
	setup1,
	setup2,
	setup3,
	setup4,
	setup5,
	setup6,
	NULL
};

int main(int argc, char **argv) {
	CmdLineOptions options = CmdLineOptions::parse(argc, argv);
	
	// Initialize Verilators variables
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	// Create an instance of our module under test
	// Vvid contains a line renderer and video memory controller wired together
	init_test_bench(options.trace_on);

	// Video renderer - shows HDMI output in GUI and simulates hdmi-encoder.v
	Video_renderer *vid=new Video_renderer(true);

	// Toggle reset signal.
	// We do this before setup as reset resets many of the line_render's registers
	toggle_reset();

	// Call the selected setup
	options.setup();

	// Main display loop
	// Runs two clocks
	// 1. tb->clk is the base system clock
	// 2. tb->pixelclk runs about 1/4 the speed of the system clock
	int fetch_next=0;
	int next_line=0;
	int next_field=0;
	float pixelclk_pos=0;
	int qpi_is_idle=0, qpi_next_word=0;
	uint32_t qpi_rdata=0;
	int layer=0;

	// Main loop - count fields
	int field = 0;
	while (field < options.num_fields) {
		// Toggle main clock high
		tb->pixelclk = (pixelclk_pos>0.5)?1:0;
		tb->clk = !tb->clk;

		// Drive memory
		qpi_eval(tb->clk, tb->qpi_addr, tb->qpi_do_read, &qpi_is_idle, &qpi_next_word, &qpi_rdata);
		tb->qpi_rdata=qpi_rdata;
		tb->qpi_is_idle=qpi_is_idle;
		tb->qpi_next_word=qpi_next_word;
		tb_step();

		// Set main clock low
		tb->clk = !tb->clk;
		tb_step();

		// Drive video output based on pixel clock
		pixelclk_pos=pixelclk_pos+0.26;
		if (pixelclk_pos>1.0) {
			pixelclk_pos-=1.0;
			vid->next_pixel(tb->red, tb->green, tb->blue, &fetch_next, &next_line, &next_field);
			tb->fetch_next=fetch_next;
			// Count fields
			if (tb->next_field==1 && next_field==0) {
				printf("Finished field: %d\n", field);
				field++;
			}
			tb->next_field=next_field;
			tb->next_line=next_line;
		}
	}

	if (trace) {
		trace->flush();
		trace->close();
	}

	printf("Press ENTER to exit\n");
	getc(stdin);
	exit(EXIT_SUCCESS);
}
