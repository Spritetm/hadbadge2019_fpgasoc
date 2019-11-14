/*
 *	Copyright 2019 Roger Cheng <roger.random@outlook.com>
 *	This is free software: you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation, either version 3 of the License, or
 *	(at your option) any later version.
 *
 *	This software is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this software.  If not, see <https://www.gnu.org/licenses/>.
 */

#include <stdint.h>
#include "mach_defines.h"
#include "tusb.h"

extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]
extern volatile uint32_t GFXREG[];
#define GFX_REG(i) GFXREG[(i)/4]

#define CYCLES_PER_SECOND 48000000 //	SOC runs at a constant 48 MHz
#define CYCLES_PER_MS     48000

//	RISC V instruction set includes ability to retrieve CSR with the number
//	of clock cycles executed since an arbitrary point in the past. In our
//	case since initial power-up. Badge SOC clock speed is constant (no sleep
//	mode, no slower power-saving modes, etc) so we will be using this clock
//	count to derive real world time.
uint64_t cycle() {
	uint32_t high1, high2, low;
	uint64_t cycle;

	//	There is a small chance that we read these registers just as the low 32
	//	bits overflowed, incrementing the high 32 bits. If not compensated for,
	//	we risk returning a time roughly 90 seconds (2^32 cycles at 48 MHz)
	//	differ from actual time.
	//	We detect this condition by reading the high 32 bits twice: once before
	//	and once after reading the low 32 bits.
	asm volatile ("rdcycleh %0" : "=r"(high1));
	asm volatile ("rdcycle %0" : "=r"(low));
	asm volatile ("rdcycleh %0" : "=r"(high2));

	if (high1 != high2) {
		//	If the high 32 bits have indeed changed, the low 32 bits we just read
		//	is unreliable. It might be large if we read it just before overflow,
		//	meaning it should be paired with high1. Or it might be small if read
		//	it just after overflow, which then should be paired with high2.
		//	Rather than making comparisons which will take several instructions,
		//	let's execute a single instruction to re-read the low 32 bits and
		//	always pair it with high2.
		asm volatile ("rdcycle %0" : "=r"(low));
	}

	//	Assemble the second value of high 32 bits with the low 32 bits.
	cycle = high2;
	cycle = (cycle<<32) | low;

	return cycle;
}

//	Badge has background housekeeping tasks that need to be called occasionally,
//	but their execution is completely at the mercy of the foreground app calling
//	into this function. To encourage housekeeping, we provide a few convenience
//	functions that perform tasks while we wait for something.
void do_background_tasks() {
	if (tud_cdc_connected()) {
		tud_cdc_write_flush();
	}
	tud_task();
}

//	Arduino-style millis()
uint32_t millis() {
	return (cycle() / CYCLES_PER_MS) & 0xFFFFFFFF;
}

//	Arduino-style delay()
void delay(uint32_t ms) {
	uint64_t cycles_start = cycle();
	uint64_t cycles_end = cycles_start + ms*CYCLES_PER_MS;
	do {
		do_background_tasks();
	} while (cycle() < cycles_end);
}

//	Wait for button press, do background tasks while we wait.
void wait_for_button_press(uint32_t button_mask) {
	do {
		do_background_tasks();
	} while ((MISC_REG(MISC_BTN_REG) & button_mask)==0);
}

//	Wait for button release, do background tasks while we wait.
void wait_for_button_release() {
	do {
		do_background_tasks();
	} while (MISC_REG(MISC_BTN_REG));
}

//	Wait for VBlank counter to increment, do background tasks while we wait.
void wait_for_next_frame(uint32_t current_frame) {
	do {
		do_background_tasks();
	} while (GFX_REG(GFX_VBLCTR_REG) <= current_frame);
}