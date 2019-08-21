
#include "custom_ops.S"

	.global load_ipl

	.section .text

#define RAM_START		0x40000000
#define RAM_SIZE		0x00800000 //8MiB
//#define RAM_SIZE		0x20000  //128KiB
#define RAM_FLUSH_REGION	0x41000000
#define RAM_FB			0x407C0000
#define PERI_UART_DATA	0x10000000
#define PERI_UART_DIV	0x10000004
#define PERI_MISC		0x20000000
#define PERI_LCD		0x30000000
#define PERI_LINERDR	0x50000000
#define PERI_LINERDR_VIDEO 0x50100000

reset_vec:
//	picorv32_waitirq_insn(zero)
//	picorv32_maskirq_insn(zero, zero)
	j do_reset

.balign 16
irq_vec_entry:
	j irq_vec

do_reset:
	//LEDS: 1 for init
	li a1, PERI_MISC
	li a2, 1
	sw a2, 0(a1)
	
	//see if we are the 2nd cpu
	lw a2,4(a1)
	bne a2, zero, secondcpu

//Bitbang PSRAM port initialization command
bbpsraminit:
	la a1, psram_init
	li a2, PERI_MISC+4 //bitbang port
bbloop:
	lbu a3, 0(a1)
	sw a3, 0(a2)
	addi a1, a1, 1
	bne zero, a3, bbloop

	//flush cache to psram
	li a1, RAM_FLUSH_REGION
	li a2, RAM_SIZE
	sw a2, 0(a1)

	//Set up UART divider
	li a1, PERI_UART_DIV
	li a2, 416 //115200 with a clock of 48MHz
//	li a2, 69 //115200 with a clock of 8MHz
	sw a2, 0(a1)

	//Check if we are running in a simulation. If so, immediately jump to app that the simulator already
	//preloaded in psram.
	li a2, PERI_MISC
	lw a2, 0(a2)
//	srli a2, a2, 31 //mask out 31th bit - does not work?
	beq a2, zero, memtest_start

	li a2, PERI_MISC
	li a1, 0x2
	sw a1, 0(a2)

	li a1, PERI_UART_DIV
	li a2, 64 //dummy for verilator
	sw a2, 0(a1)

	//start lcd
	li a1, PERI_LCD+0x8
	li a2, 0x09
	sw a2, 0(a1)

//if verilator, we skip the memtest
	j memtestok


//Memtest
memtest_start:
	li a2, PERI_MISC
	li a1, 0x3
	sw a1, 0(a2)

	//Test: writeback/cache line reload
	li a1, RAM_START+RAM_SIZE-0x40 //end
	li a4, RAM_START+0x2000 //start
	li a3, 0xAAAAAAAA
memtestwloop:
	addi a1, a1, -4
	sw a3, 0(a1)
	add a3, a3, a3
	add a3, a3, a1
	bne a1, a4, memtestwloop

	//LEDS: 4 for write loop done
	li a1, PERI_MISC
	li a2, 4
	sw a2, 0(a1)

	li a1, RAM_START+RAM_SIZE-0x40 //end
	li a4, RAM_START+0x2000 //start
	li a3, 0xAAAAAAAA
memtestrloop:
	addi a1, a1, -4
	lw a5, 0(a1)
	bne a5, a3, memtesterr
	add a3, a3, a3
	add a3, a3, a1
	bne a1, a4, memtestrloop

	//LEDS: 5 for OK
	li a2, 0x05
	j memtestok

memtesterr:
	//LEDs: 6 for error
	li a2, 6
	li a1, PERI_MISC
	sw a2, 0(a1)
	j memtesterr

memtestok:
	li a1, PERI_MISC
	sw a2, 0(a1)

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
	li a1, PERI_MISC
	sw a2, 0(a1)

//verilator: end simulation
//	li a2, 0x2a
//	li a1, PERI_MISC
//	sw a2, 0(a1)

	call load_ipl

jtagwait:
	li a1, 0x40000000
	lw a3, 0(a1)
	li a2, 0xdeadbeef
	bne a3, a2, jtagwait

	li a2, 8
	li a1, PERI_MISC
	sw a2, 0(a1)


	li a1, 0x40002008 //ipl image has 2 words of header
	jalr zero, a1, 0

	//break to gdbstub
	li a1, 0x40002000
	li a2, 0x00100073 //ebreak
	sw a2, 0(a1)
	jalr zero, a1, 0

// ---- Serial loader ----

	//Set up LEDs
	li a1, PERI_MISC
	li a2, 0xaa
	sw a2, 0(a1)

	la a1, txt
	call sendstr
	la a1, okay
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
	li a1, PERI_MISC
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
	//get count
	call getbyte
	slli a3, a1, 16
	call getbyte
	slli a1, a1, 8
	add a3, a3, a1
	call getbyte
	add a3, a3, a1
	li a4, RAM_START+0x2000
	add a3, a4, a3
writeloop:
	call getbyte
	sb a1, 0(a4)

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
	slli a3, a1, 16
	call getbyte
	slli a1, a1, 8
	add a3, a3, a1
	call getbyte
	add a3, a3, a1
	li a4, RAM_START+0x2000
	add a3, a4, a3 //len -> end addr
	li a2, PERI_UART_DATA
readloop:
	lb a1, 0(a4)
	sw a1, 0(a2)
	addi a4, a4, 1
	bne a3, a4, readloop
	
	la a1, okay
	call sendstr
	
	j rettohang


dogo:
	call getbyte
	slli a4, a1, 16
	call getbyte
	slli a1, a1, 8
	add a4, a4, a1
	call getbyte
	add a4, a4, a1
	li a1, RAM_START
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


//kills a2, a3
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

secondcpu:
	la a1, secondcputext
	call sendstr

secondcpuloop:
	la a1, RAM_FB-0x1000
	la a2, RAM_START+RAM_SIZE-0x100
	la a5, 0x11112222 //pixel data
render_line:
	sw a5, 0(a1)
	addi a1, a1, 4
	addi a5, a5, 1
	ble a1, a2, render_line

secondcpuhang:
	j secondcpuhang

secondcputext:
	.asciz "Hello from 2nd cpu\r\n"

txt:
	.asciz "ROM ldr v1.0\r\n"

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
	.byte 0xDD, 0x4F //raise sck, clear override
	.byte 0

