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
 * along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "custom_ops.S"

#include "../ipl/gloss/mach_defines.h"

	.global load_ipl
	.global run_ipl

	.section .text


reset_vec:
	j do_reset

.balign 16
irq_vec_entry:
	j irq_vec

.balign 16
//Interrupt handler table is at 0x20. Normally initialized with jumps to the panic handler.
//Can be modified by IPL/apps to real interrupt handlers later.
	.global gdb_panic_handler
	.global irq_table
irq_table:
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler
	.word gdb_panic_handler

.global irq_stack_ptr
irq_stack_ptr:
	.word 0x40002000

.global cart_boot_flag
cart_boot_flag:
	.word 0

do_reset:
	//LEDS: 1 for init
	li a1, MISC_OFFSET
	li a2, 1
	sw a2, MISC_LED_REG(a1)

	//see if we are the 2nd cpu
	lw a2,MISC_CPU_NO(a1)
	bne a2, zero, secondcpu

	//Set up UART divider for 115200
	li a1, UART_OFFSET
	li a2, 414
	sw a2, UART_DIV_REG(a1)
	li a2, 24
	sw a2, UART_IRDA_DIV_REG(a1)


	//Check if we are running in a simulation. If so, immediately jump to app that the simulator already
	//preloaded in psram.
	li a2, MISC_OFFSET
	lw a2, MISC_SOC_VER(a2)
	srli a2, a2, 15 //mask out 15th bit
	andi a2, a2, 1
//	andi a2, a2, 0
	beq a2, zero, is_real_badge

	li a2, MISC_OFFSET
	li a1, 0x2
	sw a1, MISC_LED_REG(a2)

	li a1, UART_OFFSET
	li a2, 64 //dummy for verilator
	sw a2, UART_DIV_REG(a1)

	//start lcd
	li a1, LCD_OFFSET
	li a2, LCD_CONTROL_BLEN | LCD_CONTROL_FBSTART
	sw a2, LCD_CONTROL_REG(a1)

	//irqs: enable 1 (ecall), 2 (unaligned mem), 3 (bus error) to bring us to gdbstub
	li a1, 0xffffffff-0xE
	picorv32_maskirq_insn(a1, a1)

	li a2, MISC_OFFSET
	li a1, 0xF
	sw a1, MISC_LED_REG(a2)

	//Directly jump to IPL
	call run_ipl

kill:
	j kill

//if verilator, we skip the memtest
	j memtestok


is_real_badge:

//Bitbang PSRAM port initialization command
psram_init:
	// Debug
	li a2, MISC_OFFSET
	li a1, 0x2
	sw a1, MISC_LED_REG(a2)

	// Load base offset
	li a1, PSRAM_CMD_OFFSET

	// Request manual control
	li a2, 2
	sw a2, PSRAM_CMD_CSR(a1)

	// Send single command
	li a2, 0x3535
	sw a2, PSRAM_CMD_SPI_WR_16B(a1)

	// Release manual control
	li a2, 4
	sw a2, PSRAM_CMD_CSR(a1)

	// Wait for completion
1:
	lw a2, PSRAM_CMD_CSR(a1)
	andi a2, a2, 16
	beq zero, a2, 1b

	// Flush cache to psram
	li a1, MACH_FLUSH_REGION
	li a2, MACH_RAM_SIZE
	sw a2, 0(a1)

//Prod version: skip memtest. Hope there aren't badges with memory issues.
	j memtestok


//Memtest
memtest_start:
	li a2, MISC_OFFSET
	li a1, 0x3
	sw a1, MISC_LED_REG(a2)

	//Test: writeback/cache line reload
	li a1, MACH_RAM_START+MACH_RAM_SIZE-0x40 //end
	li a4, MACH_RAM_START+0x2000 //start
	li a3, 0xAAAAAAAA
memtestwloop:
	addi a1, a1, -64 //1 cache line
	sw a3, 0(a1)
	add a3, a3, a3
	add a3, a3, a1
	bne a1, a4, memtestwloop

	//LEDS: 4 for write loop done
	li a1, MISC_OFFSET
	li a2, 4
	sw a2, MISC_LED_REG(a1)

	li a1, MACH_RAM_START+MACH_RAM_SIZE-0x40 //end
	li a4, MACH_RAM_START+0x2000 //start
	li a3, 0xAAAAAAAA
memtestrloop:
	addi a1, a1, -64 //1 cache line
	lw a5, 0(a1)
	bne a5, a3, memtesterr
	add a3, a3, a3
	add a3, a3, a1
	bne a1, a4, memtestrloop

	//LEDS: 5 for OK
	li a2, 0x05
	li a1, MISC_OFFSET
	sw a2, MISC_LED_REG(a1)
	j memtestok

memtesterr:
	//LEDs: 6 for error
	li a2, 6
	li a1, MISC_OFFSET
	sw a2, MISC_LED_REG(a1)
	j memtesterr

memtestok:

	//un-reset 2nd cpu
//	li a2, 2
//	sw a2, 12(a1)

	//irqs: enable 1 (ecall), 2 (unaligned mem), 3 (bus error) to bring us to gdbstub
	li a1, 0xffffffff-0xE
	picorv32_maskirq_insn(a1, a1)


#if 0
/*
Hardware multiplier tests. Run 'i reg' in gdb to see the results.
Note: We expect:
s2             0x8c751000	-1938485248
s3             0x3	3
s4             0xfffe1dc3	-123453
s5             0xfffc3b83	-246909
s6             0xfffffffc	-4
s7             0x1e23c	123452
s8             0x1e23c	123452
s9             0x3	3
s10            0x3	3
s11            0x3	3
*/

	li a1, -123456
	li a2, -123456
	mul s2, a1, a2
	mulh s3, a1, a2
	mulhsu s4, a1, a2
	mulhu s5, a1, a2
	li a1, 123456
	li a2, -123456
	mulh s6, a1, a2
	mulhsu s7, a1, a2
	mulhu s8, a1, a2
	li a1, 123456
	li a2, 123456
	mulh s9, a1, a2
	mulhsu s10, a1, a2
	mulhu s11, a1, a2
#endif

	li a2, 7
	li a1, MISC_OFFSET
	sw a2, MISC_LED_REG(a1)

//verilator: end simulation
//	li a2, 0x2a
//	li a1, MISC_OFFSET
//	sw a2, MISC_LED_REG(a1)

	call load_ipl
	call run_ipl

	li a2, 8
	li a1, MISC_OFFSET
	sw a2, MISC_LED_REG(a1)

jtagwait:
	li a1, 0x40000000
	lw a3, 0(a1)
	li a2, 0xdeadbeef
	bne a3, a2, jtagwait

	li a2, 9
	li a1, MISC_OFFSET
	sw a2, MISC_LED_REG(a1)


	li a1, 0x40002008 //ipl image has 2 words of header
	jalr zero, a1, 0

	//break to gdbstub
	li a1, 0x40002000
	li a2, 0x00100073 //ebreak
	sw a2, 0(a1)
	jalr zero, a1, 0


secondcpu:
secondcpuhang:
	j secondcpuhang

