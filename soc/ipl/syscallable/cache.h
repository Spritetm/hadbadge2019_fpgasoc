#include "mach_defines.h"
#include <stdint.h>

#pragma once

//Flush a certain memory region to psram
inline static void cache_flush(void *addr_start, void *addr_end) {
	volatile uint32_t *p = (volatile uint32_t*)(((uint32_t)addr_start & ~3) - MACH_RAM_START + MACH_FLUSH_REGION);
	*p=(uint32_t)addr_end-MACH_RAM_START;
}
