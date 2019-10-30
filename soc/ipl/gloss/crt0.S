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
 * along with this software.  If not, see <https://www.gnu.org/licenses/>.
 */

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

.global start_ipl
.global exit_to_ipl

start_ipl:
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

	//Called when an app does exit(). Note error core is in A0.
exit_to_ipl:
	//setup stack
	la x2, _stack_start
	
	//clear bss
	la a1, _bss_start
	la a2, _bss_end
bss_clear_exit:
	bge a1, a2, bss_clear_done_exit
	sw zero, 0(a1)
	addi a1, a1, 4
	j bss_clear_exit
bss_clear_done_exit:

	//Jump to C code
	call cpu_start


#reset
	j 0x40000000
