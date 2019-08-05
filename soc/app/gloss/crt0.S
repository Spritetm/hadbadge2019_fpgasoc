
#include "custom_ops.S"

	.section .text

//note: no irq vector here as that's in the bootloader area

.global _stack_start
.global _bss_start
.global _bss_end
.global cpu_start
.global _start

.global _bin_start
.global _bin_end

reset_vec:
	.word 0x1337b33f
	.word _bin_end - _bin_start

_start:

	//setup stack
	la x2, _stack_start
	
	//clear bss
	la a1, _bss_start
	la a2, _bss_end
bss_clear:
	bge a1, a2, bss_clear_done
	sw zero, 0(a1)
	addi a1, a1, 4
	j bss_clear
bss_clear_done:


	//Jump to C code
	call cpu_start

#reset
	j 0x40000000
