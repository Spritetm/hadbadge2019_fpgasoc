#include <stdlib.h>
#include "Vsoc.h"
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "psram_emu.hpp"
#include "uart_emu.hpp"
#include "uart_emu_gdb.hpp"

int uart_get(int ts) {
	return 1;
}

int do_abort=0;
#define TAGMEM0 soc__DOT__qpimem_cache__DOT__genblk0__BRA__1__KET____DOT__tagdata__DOT__mem
#define TAGMEM1 soc__DOT__qpimem_cache__DOT__genblk1__BRA__1__KET____DOT__tagdata__DOT__mem

uint64_t ts=0;
uint64_t tracepos=0;


double sc_time_stamp() {
	return ts;
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
	int do_trace=1;

	Psram_emu psram=Psram_emu(8*1024*1024);
	//ToDo: load elfs so we can mark ro sections as read-only
	psram.load_file("boot/rom.bin", 0, false);
//	psram.load_file("app/app.bin", 0x2000, false);

	Uart_emu uart=Uart_emu(64);
//	Uart_emu_gdb uart=Uart_emu_gdb(64);
//	Uart_emu uart=Uart_emu(416);

	int oldled=0;
	while(1) {
		ts++;
		if (do_trace) tracepos++;
		if (do_abort) break;
		tb->uart_rx=uart_get(ts*21);
		int sin, rx;
		do_abort |= psram.eval(tb->psrama_sclk, tb->psrama_nce, tb->psrama_sout, tb->psrama_oe, &sin);
		uart.eval(tb->clk48m, tb->uart_tx, &rx);
		tb->uart_rx=rx;
		tb->clk48m = 1;
		tb->eval();
		tb->psrama_sin=sin;
		if (do_trace) trace->dump(tracepos*21);
		do_abort |= psram.eval(tb->psrama_sclk, tb->psrama_nce, tb->psrama_sout, tb->psrama_oe, &sin);
		uart.eval(tb->clk48m, tb->uart_tx, &rx);
		tb->uart_rx=rx;
		tb->clk48m = 0;
		tb->eval();
		tb->psrama_sin = sin;
		if (do_trace) trace->dump(tracepos*21+10);
		if (oldled != tb->led) {
			oldled=tb->led;
			printf("LEDs: 0x%X\n", oldled);
			//if (oldled == 0x3A) do_trace=1;
		}
/*
		if (tb->soc__DOT__cpu__DOT__reg_pc==0x400060f4) {
			do_trace=1;
			printf("Trace start\n");
		}
		if (tb->soc__DOT__cpu__DOT__reg_pc==0x400002d4) {
			do_trace=0;
			printf("Trace stop\n");
		}
*/
//		printf("%X\n", tb->soc__DOT__cpu__DOT__reg_pc);
	};
//	printf("Verilator sim exited, pc 0x%08X\n", tb->soc__DOT__cpu__DOT__reg_pc);
	trace->flush();

	trace->close();
	exit(EXIT_SUCCESS);
}