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
	
	fun_ptr_t entrypoint=(fun_ptr_t)&ipl->entry_point;
	entrypoint();
}

