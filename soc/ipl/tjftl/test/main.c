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
#include <stdint.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include "../tjftl.h"
#include "hexdump.h"


#define BACKING_MEM (15*1024*1024)
#define STORAGE_MEM (14*1024*1024)

typedef struct {
	uint8_t *flash;
	int fail_after;
} flash_t;

bool flash_rd(int addr, uint8_t *buf, int len, void *arg) {
	assert(addr>=0);
	assert(addr+len<=BACKING_MEM);
	flash_t *f=(flash_t*)arg;
	memcpy(buf, f->flash+addr, len);
	return true;
}

bool flash_erase(int addr, void *arg) {
//	printf("flash_erase blk %d\n", addr/32768);
	assert(addr>=0);
	assert(addr+32768<=BACKING_MEM);
	flash_t *f=(flash_t*)arg;
	if (f->fail_after<=0) return false;
	memset(f->flash+addr, 0xff, 32*1024);
	return true;
}

bool flash_program(int addr, const uint8_t *buf, int len, void *arg) {
//	printf("flash_program blk %d sect %d\n", addr/32768, (addr/512)&63);
//	hexdump(buf, 512);
	assert(addr>=0);
	assert(addr+len<=BACKING_MEM);
	flash_t *f=(flash_t*)arg;
	if (f->fail_after<=0) return false;
	f->fail_after--;
	if (f->fail_after==0) printf("POWER FAILS HERE!\n");
	for (int i=0; i<len; i++) {
		f->flash[addr+i]&=buf[i];
	}
	return true;
}

int main(int argc, char **argv) {
	flash_t *flash=malloc(sizeof(flash_t));
	flash->flash=malloc(BACKING_MEM);
	uint8_t *realmem=malloc(STORAGE_MEM);
	memset(realmem, 0xff, STORAGE_MEM);
	for (int i=0; i<BACKING_MEM; i++) {
		flash->flash[i]=rand();
	}
	
	flash->fail_after=999999;
	tjftl_t *tj=tjftl_init(flash_rd, flash_erase, flash_program, flash, BACKING_MEM, STORAGE_MEM/512);
	flash->fail_after=rand()%1000;
	int iter=0;
	while(iter<(STORAGE_MEM/512)*1000) {
		if ((iter&0xff)==0) {
//		printf("Iter %d\n", iter);
		bool has_err=false;
		for (int i=0; i<STORAGE_MEM/512; i++) {
			uint8_t buf[512];
			memset(buf, 0xff, 512);
			tjftl_read(tj, i, buf);
			if (memcmp(buf, realmem+(i*512), 512)!=0) {
				printf("Omg! Error at iter %d, lba %d\n", iter, i);
				has_err=true;
			}
		}
		if (has_err) exit(1);

		}

		int lba=rand()%(STORAGE_MEM/512);
		uint8_t buf[512];
		for (int i=0; i<512; i++) buf[i]=rand();
		tjftl_write(tj, lba, buf);
		memcpy(realmem+lba*512, buf, 512);
//		printf("Written to LBA %d\n", lba);
		iter++;

		if (flash->fail_after<=0) {
			printf("Simulated power fail. Re-initializing ftl.\n");
			flash->fail_after=999999;
			tj=tjftl_init(flash_rd, flash_erase, flash_program, flash, BACKING_MEM, STORAGE_MEM/512);
			tjftl_write(tj, lba, buf);
			flash->fail_after=(rand()%100000)+30;
		}
	}
}