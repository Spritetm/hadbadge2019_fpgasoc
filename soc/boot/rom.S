
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

do_reset:
	//LEDS: 1 for init
	li a1, MISC_OFFSET
	li a2, 1
	sw a2, MISC_LED_REG(a1)

	//see if we are the 2nd cpu
	lw a2,MISC_CPU_NO(a1)
	bne a2, zero, secondcpu

	//Set up UART divider
	li a1, UART_OFFSET
	li a2, 416 //115200 with a clock of 48MHz
	sw a2, UART_DIV_REG(a1)
	sw a2, UART_IRDA_DIV_REG(a1)


	//Check if we are running in a simulation. If so, immediately jump to app that the simulator already
	//preloaded in psram.
	li a2, MISC_OFFSET
	lw a2, MISC_SOC_VER(a2)
	srli a2, a2, 15 //mask out 15th bit
	andi a2, a2, 1
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
bbpsraminit:
	la a1, psram_init
	li a2, MISC_OFFSET //bitbang port
bbloop:
	lbu a3, 0(a1)
	sw a3, MISC_PSRAMOVRA_REG(a2)
	sw a3, MISC_PSRAMOVRB_REG(a2)
	addi a1, a1, 1
	bne zero, a3, bbloop

	//flush cache to psram
	li a1, MACH_FLUSH_REGION
	li a2, MACH_RAM_SIZE
	sw a2, 0(a1)


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

jtagwait:
	li a1, 0x40000000
	lw a3, 0(a1)
	li a2, 0xdeadbeef
	bne a3, a2, jtagwait

	li a2, 8
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



//Bitbang SPI port to get the PSRAM to QPI mode (command 0x35)
psram_init:
	.byte 0xDC, 0xCC //lower sck
	.byte 0xCC, 0xEC //bit 7
	.byte 0xCC, 0xEC //bit 6
	.byte 0xCD, 0xED //bit 5
	.byte 0xCD, 0xED //bit 4
	.byte 0xCC, 0xEC //bit 3
	.byte 0xCD, 0xED //bit 2
	.byte 0xCC, 0xEC //bit 1
	.byte 0xCD, 0xED //bit 0
	.byte 0xDD, 0x4F //raise sck, clear override
	.byte 0

