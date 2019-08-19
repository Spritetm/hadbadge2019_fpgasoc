#include <stdlib.h>
#include "Vqpitest.h"
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "../psram_emu.hpp"

uint64_t ts=0;
uint64_t tracepos=0;

Vqpitest *tb;
Psram_emu *psram;
VerilatedVcdC *trace;

double sc_time_stamp() {
	return ts;
}

#define CHECK(x) do { if (!(x)) printf("%s:%d: check failed: %s\n", __FILE__, __LINE__, #x); } while(0)

int doclk() {
	int do_abort;
	ts++;
	tracepos++;
	int sin;
	do_abort |= psram->eval(tb->spi_clk, tb->spi_ncs, tb->spi_sout, tb->spi_oe, &sin);
	tb->clk = 0;
	tb->eval();
	tb->spi_sin=sin;
	trace->dump(tracepos*21);
	do_abort |= psram->eval(tb->spi_clk, tb->spi_ncs, tb->spi_sout, tb->spi_oe, &sin);
	tb->clk = 1;
	tb->eval();
	tb->spi_sin = sin;
	trace->dump(tracepos*21+10);
	return do_abort;
}

void do_write(int addr, int data) {
	tb->addr=addr;
	tb->wdata=data;
	tb->wen=0xf;
	do {
		doclk();
	} while (tb->ready==0);
	tb->wen=0;
	doclk();
}

int do_read(int addr) {
	int ret;
	tb->addr=addr;
	tb->ren=1;
	do {
		doclk();
	} while (tb->ready==0);
	tb->ren=0;
	ret=tb->rdata;
	doclk();
	return ret;
}

int main(int argc, char **argv) {
	// Initialize Verilators variables
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	tb = new Vqpitest;
	trace = new VerilatedVcdC;
	tb->trace(trace, 99);
	trace->open("qpitesttrace.vcd");
	psram = new Psram_emu(8*1024*1024);
	psram->force_qpi();

	tb->rst = 1;
	doclk();
	tb->rst=0;
	doclk();
	doclk();
	doclk();
	doclk();

	do_read(0x20000); //dummy because ?????
	do_write(0x10001, 0xdeadbeef);
	do_write(0x10002, 0xcafebabe);

	CHECK(do_read(0x10001)==0xdeadbeef);
	CHECK(do_read(0x10002)==0xcafebabe);

	trace->flush();

	trace->close();
	exit(EXIT_SUCCESS);
}