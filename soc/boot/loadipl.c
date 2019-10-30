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
 * along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
 */
#include "gloss/mach_defines.h"
#include <stdint.h>
#include <stdbool.h>
#include "ipl_flash.h"


typedef void (*fun_ptr_t)(void);

typedef struct {
	uint32_t magic;
	uint32_t size;
	uint32_t entry_point;
	uint32_t data[];
} ipl_t;

#define IPL_FLASH_LOC 0x300000
#define IPL_MAGIC 0x1337b33f

void load_ipl() {
	ipl_t *ipl=(ipl_t*)MEM_IPL_START;
	flash_wake(FLASH_SEL_INT);
	
	flash_read(FLASH_SEL_INT, IPL_FLASH_LOC, (uint8_t*)ipl, sizeof(ipl_t));
	if (ipl->magic != IPL_MAGIC) return;
	flash_read(FLASH_SEL_INT, IPL_FLASH_LOC, (uint8_t*)ipl, ipl->size);
}

void run_ipl() {
	ipl_t *ipl=(ipl_t*)MEM_IPL_START;
	if (ipl->magic != IPL_MAGIC) return;
	fun_ptr_t entrypoint=(fun_ptr_t)&ipl->entry_point;
	entrypoint();
}

