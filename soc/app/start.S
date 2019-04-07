
#include "custom_ops.S"

	.section .text

#define RAM_START		0x00000000
#define PERI_UART_DATA	0x10000000
#define PERI_UART_DIV	0x10000004
#define PERI_LED		0x20000000
#define PERI_LCD		0x30000000

.globl _bss_start
.globl _bss_end

reset_vec:
	// no more than 16 bytes here !
//	picorv32_waitirq_insn(zero)
//	picorv32_maskirq_insn(zero, zero)
	j start

.balign 16
irq_vec:
	//unused for now

start:
# zero-initialize register file
	addi x0, zero, 0
# x2 (sp) is initialized by reset
	addi x3, zero, 0
	addi x4, zero, 0
	addi x5, zero, 0
	addi x6, zero, 0
	addi x7, zero, 0
	addi x8, zero, 0
	addi x9, zero, 0
	addi x10, zero, 0
	addi x11, zero, 0
	addi x12, zero, 0
	addi x13, zero, 0
	addi x14, zero, 0
	addi x15, zero, 0
	addi x16, zero, 0
	addi x17, zero, 0
	addi x18, zero, 0
	addi x19, zero, 0
	addi x20, zero, 0
	addi x21, zero, 0
	addi x22, zero, 0
	addi x23, zero, 0
	addi x24, zero, 0
	addi x25, zero, 0
	addi x26, zero, 0
	addi x27, zero, 0
	addi x28, zero, 0
	addi x29, zero, 0
	addi x30, zero, 0
	addi x31, zero, 0

# zero initialize scratchpad memory
	la a1, _bss_start
	la a2, _bss_end
bss_clear:
	bge a1, a2, bss_clear_done
	sw zero, 0(a1)
	addi a1, a1, 4
	j bss_clear
bss_clear_done:


	la a1, PERI_LED
	sw zero, 0(a1)

	addi a1, zero, 0
	addi a2, zero, 0
	
# sp = top of 8m of memory
	la sp, 0x7ffffc

#start app
	call app_main

#reset
	j 0

