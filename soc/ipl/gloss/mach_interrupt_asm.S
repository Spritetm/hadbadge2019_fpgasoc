#include "custom_ops.S"

.section .text

.global mach_int_ena
mach_int_ena:
	li a1, 0xffffffff
	picorv32_maskirq_insn(a1, a1)
	xori a0, a0, -1; //invert bits of a0
	and a1, a1, a0; //clear the bits set in the argument
	picorv32_maskirq_insn(a1, a1)
	ret

.global mach_int_dis
mach_int_dis:
	li a1, 0xffffffff
	picorv32_maskirq_insn(a1, a1)
	or a1, a1, a0; //set the bits set in the argument
	picorv32_maskirq_insn(a1, a1)
	ret

