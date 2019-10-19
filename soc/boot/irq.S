
#include "custom_ops.S"

.section .text
.global irq_vec
.global irq_table

.balign 16
irq_vec:
	/* save registers */

	//save x1 and x2 to q2 and q3
	picorv32_setq_insn(q2, x1)
	picorv32_setq_insn(q3, x2)

	lui x1, %hi(irq_regs)
	addi x1, x1, %lo(irq_regs)

	picorv32_getq_insn(x2, q0)
	sw x2,   0*4(x1)

	picorv32_getq_insn(x2, q2) //=x1
	sw x2,   1*4(x1)

	picorv32_getq_insn(x2, q3) //=x2
	sw x2,   2*4(x1)

	sw x3,   3*4(x1)
	sw x4,   4*4(x1)
	sw x5,   5*4(x1)
	sw x6,   6*4(x1)
	sw x7,   7*4(x1)
	sw x8,   8*4(x1)
	sw x9,   9*4(x1)
	sw x10, 10*4(x1)
	sw x11, 11*4(x1)
	sw x12, 12*4(x1)
	sw x13, 13*4(x1)
	sw x14, 14*4(x1)
	sw x15, 15*4(x1)
	sw x16, 16*4(x1)
	sw x17, 17*4(x1)
	sw x18, 18*4(x1)
	sw x19, 19*4(x1)
	sw x20, 20*4(x1)
	sw x21, 21*4(x1)
	sw x22, 22*4(x1)
	sw x23, 23*4(x1)
	sw x24, 24*4(x1)
	sw x25, 25*4(x1)
	sw x26, 26*4(x1)
	sw x27, 27*4(x1)
	sw x28, 28*4(x1)
	sw x29, 29*4(x1)
	sw x30, 30*4(x1)
	sw x31, 31*4(x1)

	/* call interrupt handler C function */

	lui a0, %hi(irq_stack_ptr)
	addi a0, a0, %lo(irq_stack_ptr)
	lw sp, 0(a0)

	// Arg 0 to irq handler is old reg addr, return is new reg address. Save this in S2.
	lui s2, %hi(irq_regs)
	addi s2, s2, %lo(irq_regs)
	//S1 is irq handler table, starting at handler for irq 0
	lui s1, %hi(irq_table)
	addi s1, s1, %lo(irq_table)
	//s0 is the bitmap of interrupts
	picorv32_getq_insn(s0, q1)
	//Note the ABI states S0 and S1 are preserved across calls.
lp:
	//Check if bit 1 is set in s0 If so, we need to call the handler.
	andi a3, s0, 1
	beq a3, zero, no_int_hdl
	
	// arg0 = address of regs
	addi a0, s2, 0

	//Load and call handler.
	lw a3, 0(s1)
	jalr ra, a3, 0

	// ret = address of new regs
	addi s2, a0, 0

no_int_hdl: 

	//Go to the next handler
	addi s1, s1, 4
	//and shift the interrupt bitmap right by one.
	srli s0, s0, 1
	//Check if 0, if so we are done.
	bne s0, zero, lp

	/* restore registers */

	// new irq_regs address returned from C code in s2
	addi x1, s2, 0

	lw x2,   0*4(x1)
	picorv32_setq_insn(q0, x2)

	lw x2,   1*4(x1)
	picorv32_setq_insn(q1, x2)

	lw x2,   2*4(x1)
	picorv32_setq_insn(q2, x2)

	lw x3,   3*4(x1)
	lw x4,   4*4(x1)
	lw x5,   5*4(x1)
	lw x6,   6*4(x1)
	lw x7,   7*4(x1)
	lw x8,   8*4(x1)
	lw x9,   9*4(x1)
	lw x10, 10*4(x1)
	lw x11, 11*4(x1)
	lw x12, 12*4(x1)
	lw x13, 13*4(x1)
	lw x14, 14*4(x1)
	lw x15, 15*4(x1)
	lw x16, 16*4(x1)
	lw x17, 17*4(x1)
	lw x18, 18*4(x1)
	lw x19, 19*4(x1)
	lw x20, 20*4(x1)
	lw x21, 21*4(x1)
	lw x22, 22*4(x1)
	lw x23, 23*4(x1)
	lw x24, 24*4(x1)
	lw x25, 25*4(x1)
	lw x26, 26*4(x1)
	lw x27, 27*4(x1)
	lw x28, 28*4(x1)
	lw x29, 29*4(x1)
	lw x30, 30*4(x1)
	lw x31, 31*4(x1)

	picorv32_getq_insn(x1, q1)
	picorv32_getq_insn(x2, q2)

	picorv32_retirq_insn()

.section .bss

irq_regs:
	// registers are saved to this memory region during interrupt handling
	// the program counter is saved as register 0
	.align 4
	.fill 32,4

