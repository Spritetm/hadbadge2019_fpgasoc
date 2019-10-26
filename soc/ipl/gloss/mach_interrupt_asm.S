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


.global mach_timer_get
mach_timer_get:
	li a0, 0
	picorv32_timer_insn(a0, a0)
	picorv32_timer_insn(a0, a0)
	ret

.global mach_timer_set
mach_timer_set:
	picorv32_timer_insn(a0, a0)
	ret
