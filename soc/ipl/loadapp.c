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
#include <inttypes.h>
#include <stdio.h>
#include "gloss/mach_defines.h"
#include "elfload/elfload.h"


typedef struct {
	el_ctx ctx; //needs to be 1st member so we can pass off the wrapper struct address as a ctx
	FILE *f;
	uint32_t max_alloc_addr;
} ctx_wrapper_t;


static bool fpread(el_ctx *ctx, void *dest, size_t nb, size_t offset) {
	ctx_wrapper_t *wrap=(ctx_wrapper_t*)ctx;
	(void) ctx;
	if (fseek(wrap->f, offset, SEEK_SET)) {
		printf("elf loader: fpread: seek to %d failed\n", offset);
		perror("fseek");
		return false;
	}
	if (fread(dest, nb, 1, wrap->f) != 1) {
		printf("elf loader: fpread: fread of %d failed\n", nb);
		perror("fread");
		return false;
	}
	return true;
}

static void *alloccb(el_ctx *ctx, Elf_Addr phys, Elf_Addr virt, Elf_Addr size) {
	ctx_wrapper_t *wrap=(ctx_wrapper_t*)ctx;
	(void) phys;
	(void) size;
	wrap->max_alloc_addr=phys+size;
	return (void*) virt;
}

//Returns entry point of app. Also sets highest used address, so we can make
//the rest into heap.
uintptr_t load_new_app(const char *appname, uintptr_t *max_alloc_addr) {
	el_status r;
	ctx_wrapper_t wrap={0};
	wrap.f=fopen(appname, "rb");
	if (!wrap.f) {
		perror(appname);
		return 0;
	}
	wrap.ctx.pread=fpread;
	r=el_init(&wrap.ctx);
	if (r!=EL_OK) {
		fprintf(stderr, "load_new_app: el_init failed (%d)\n", r);
		return 0;
	}
	wrap.ctx.base_load_vaddr = wrap.ctx.base_load_paddr = 0;
	r=el_load(&wrap.ctx, alloccb);
	if (r!=EL_OK) {
		fprintf(stderr, "load_new_app: el_load failed (%d)\n", r);
		return 0;
	}
	r=el_relocate(&wrap.ctx);
	if (r!=EL_OK) {
		fprintf(stderr, "load_new_app: el_relocate failed (%d)\n", r);
		return 0;
	}
	uintptr_t epaddr = wrap.ctx.ehdr.e_entry;
	fclose(wrap.f);
	*max_alloc_addr=wrap.max_alloc_addr;
	return epaddr;
}
