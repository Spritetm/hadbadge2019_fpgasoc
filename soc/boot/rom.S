
#include "custom_ops.S"

	.section .text

#define RAM_START		0x00000000
#define PERI_UART_DATA	0x10000000
#define PERI_UART_DIV	0x10000004
#define PERI_LED		0x20000000
#define PERI_LCD		0x30000000

reset_vec:
//	picorv32_waitirq_insn(zero)
//	picorv32_maskirq_insn(zero, zero)

	//Set up UART divider
	li a1, PERI_UART_DIV
	li a2, 416 //115200 with a clock of 48MHz
	sw a2, 0(a1)

	//Set up LEDs
	li a1, PERI_LED
	li a2, 0xaa
	sw a2, 0(a1)

	la a1, txt
	call sendstr

rettohang:
	li a2, 0xaa
hang:
	li a1, 8000000/30
	li a3, PERI_UART_DATA
	li a5, 0xffffffff
loop:
	lw a4, 0(a3)
	bne a4, a5, recv
	addi a1, a1, -1
	bnez a1, loop

	not a2, a2
	li a1, PERI_LED
	sw a2, 0(a1)

	j hang

//a4 contains command
recv:
	li a1, 'w'
	beq a4, a1, dowrite
	li a1, 'r'
	beq a4, a1, doread
	li a1, 'g'
	beq a4, a1, dogo
	la a1, err
	call sendstr
	j rettohang


dowrite:
	call getbyte
	slli a3, a1, 8
	call getbyte
	add a3, a3, a1
	li a4, 0
writeloop:
	call getbyte
	sb a1, 0x200(a4)

	li a2, PERI_UART_DATA
	li a1, 'B'
	sw a1, 0(a2)

	addi a4, a4, 1
	bne a3, a4, writeloop
	
	la a1, okay
	call sendstr
	
	j rettohang


doread:
	call getbyte
	slli a3, a1, 8
	call getbyte
	add a3, a3, a1
	li a4, 0x200
	li a2, PERI_UART_DATA
readloop:
	lb a1, 0x200(a4)
	sw a1, 0(a2)
	addi a4, a4, 1
	bne a3, a4, readloop
	
	la a1, okay
	call sendstr
	
	j rettohang


dogo:
	call getbyte
	slli a4, a1, 8
	call getbyte
	add a4, a4, a1

	la a1, okay
	call sendstr

	jalr zero, a4, 0


//returns byte in a1
//kills a2
getbyte:
	li a2, PERI_UART_DATA
	lw a1, 0(a2)
	li a2, 0xffffffff
	beq a1, a2, getbyte
	ret


//killa a2, a3
sendstr:
	li a3, PERI_UART_DATA
sendstr_loop:
	lb a2, 0(a1)
	beqz a2, sendstr_end
	sw a2, 0(a3)
	addi a1, a1, 1
	j sendstr_loop

sendstr_end:
	ret


txt:
	.asciz "ROM loader v1.0\r\n"

err:
	.asciz "?"

okay:
	.asciz "K"


