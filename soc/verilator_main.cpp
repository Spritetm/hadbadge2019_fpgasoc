#include <stdlib.h>
#include "Vsoc.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

int uart_get(int ts) {
	return 1;
}

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
	int do_trace=0;

	for (int i=0; i<48000000; i++) {
		tb->uart_rx=uart_get(i*21);
		tb->clk = 1;
		tb->eval();
		if (do_trace) trace->dump(i*21);
		tb->clk = 0;
		tb->eval();
		if (do_trace) trace->dump(i*21+10);
	};
	trace->flush();

	trace->close();
	exit(EXIT_SUCCESS);
}