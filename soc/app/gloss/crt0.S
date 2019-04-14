
#include "custom_ops.S"

	.section .text

reset_vec:
	// no more than 16 bytes here !
//	picorv32_waitirq_insn(zero)
//	picorv32_maskirq_insn(zero, zero)
	j _start

.balign 16
irq_vec:
	//Not used as of now
	j irq_vec

.global _stack_start
.global _bss_start
.global _bss_end
.global cpu_start
.global _start

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
	j 0
