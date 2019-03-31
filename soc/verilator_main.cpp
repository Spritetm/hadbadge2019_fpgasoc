#include <stdlib.h>
#include "Vsoc.h"
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "psram_emu.h"

int uart_get(int ts) {
	return 1;
}

int do_abort=0;

int main(int argc, char **argv) {
	// Initialize Verilators variables
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	// Create an instance of our module under test
	Vsoc *tb = new Vsoc;
	//Create trace
	VerilatedVcdC *trace = new VerilatedVcdC;
	tb->trace(trace, 99);
	trace->open("soctrace.vcd");

	tb->btn=0xff; //no buttons pressed
	int do_trace=1;

	psram_emu_init();
	int oldled=0;
	for (int i=0; i<4800000; i++) {
		if (do_abort) break;
		tb->uart_rx=uart_get(i*21);
		tb->clk48m = 1;
		tb->psrama_sin = psram_emu(tb->psrama_sclk, tb->psrama_nce, tb->psrama_sout, tb->psrama_oe);
		tb->eval();
		if (do_trace) trace->dump(i*21);
		tb->clk48m = 0;
		tb->psrama_sin = psram_emu(tb->psrama_sclk, tb->psrama_nce, tb->psrama_sout, tb->psrama_oe);
		tb->eval();
		if (do_trace) trace->dump(i*21+10);
		if (oldled != tb->led) {
			oldled=tb->led;
			printf("LEDs: 0x%X\n", oldled);
		}
	};
	trace->flush();

	trace->close();
	exit(EXIT_SUCCESS);
}