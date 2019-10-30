/*
 * Copyright 2019 Jeroen Domburg <jeroen@spritesmods.com>
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <stdlib.h>
#include "Vpic_wrapper.h"
#include <verilated.h>
#include <verilated_vcd_c.h>

uint64_t ts=0;
uint64_t tracepos=0;

Vpic_wrapper *tb;
VerilatedVcdC *trace=NULL;

int led_dc[16];

double sc_time_stamp() {
	return ts;
}

#define CHECK(x) do { if (!(x)) printf("%s:%d: check failed: %s\n", __FILE__, __LINE__, #x); } while(0)

#define PRINT_EVERY (1<<20)

void dump_vars() {
	const char *vars[]={
		"dim_period", "ramp_factor", "preset_a", "preset_b", "pattern", "target_b", "target_a", "slow_b", "slow_a", "count_b", "count_a",
		"inner_count", "outer_count", "broad_count", "pat_count", "count_dim", "tempw", "flag", NULL};
	int a=0;
	printf("PC: %X\n", tb->pic_wrapper__DOT__pic__DOT__pc_reg);
	while (vars[a]!=NULL) {
		printf("%s:\t\t0x%X\n", vars[a], tb->pic_wrapper__DOT__datamem[a+0x20]);
		a++;
	}
}

void print_leds() {
	const char *ch[4]={" ","░","▒","▓"};
	for (int i=0; i<16; i++) {
		int p=led_dc[i]/(PRINT_EVERY/4);
		if (p>3) p=3;
		printf("%s", ch[p]);
		led_dc[i]=0;
	}
	printf("\n");
}


int doclk() {
	int do_abort;
	ts++;
	tracepos++;
	tb->clk = 0;
	tb->eval();
	if (trace) trace->dump(tracepos*21);
	tb->clk = 1;
	tb->eval();
	if (trace) trace->dump(tracepos*21+10);
	for (int i=0; i<16; i++) {
		if (tb->gpio_out&(1<<i)) led_dc[i]++;
	}
	if ((ts%PRINT_EVERY)==0) print_leds();

/*
	if (tb->pic_wrapper__DOT__pic__DOT__pc_reg==0x180) dump_vars();

	if (tb->pic_wrapper__DOT__pic__DOT__ram_we_reg) {
		if (tb->pic_wrapper__DOT__pic__DOT__ram_adr_node==0x2e) dump_vars();
	}
*/
	return do_abort;
}

int main(int argc, char **argv) {
	// Initialize Verilators variables
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);

	tb = new Vpic_wrapper;
//	trace = new VerilatedVcdC;
	if (trace) tb->trace(trace, 99);
	if (trace) trace->open("pictrace.vcd");

	tb->reset = 1;
	doclk();
	tb->reset=0;
	doclk();
	doclk();
	doclk();
	doclk();

	while(1) {
		doclk();
	}

	if (trace) trace->flush();

	if (trace) trace->close();
	exit(EXIT_SUCCESS);
}