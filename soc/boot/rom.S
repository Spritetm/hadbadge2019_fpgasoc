
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

//Bitbang PSRAM port
	la a1, psram_init
	li a2, PERI_LED+4
bbloop:
	lbu a3, 0(a1)
	sw a3, 0(a2)
	addi a1, a1, 1
	bne zero, a3, bbloop

	li a1, PERI_LED
	li a2, 0xff
	sw a2, 0(a1)

	//Test: writeback/cache line reload
	li a1, 0x10000
	li a4, 0x12000
	li a3, 0xAAAAAAAA
memtestwloop:
	sw a3, 0(a1)
	addi a3, a3, 1
	addi a1, a1, 4
	bne a1, a4, memtestwloop

	li a1, PERI_LED
	li a2, 1
	sw a2, 0(a1)

	li a1, 0x10000
	li a4, 0x12000
	li a3, 0xAAAAAAAA
memtestrloop:
	lw a5, 0(a1)
	bne a5, a3, memtesterr
	addi a3, a3, 1
	addi a1, a1, 4
	bne a1, a4, memtestrloop

	li a2, 0x02
	j memtestok

memtesterr:
	li a2, 0x00
memtestok:
	li a1, PERI_LED
	sw a2, 0(a1)

hangtest: j hangtest


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
//	.asciz "ROM ldr v1.0\r\n"
	.asciz "x"

err:
	.asciz "?"

okay:
	.asciz "K"

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
	.byte 0xDD, 0xCD //raise sck, clear override
	.byte 0x4F, 0



