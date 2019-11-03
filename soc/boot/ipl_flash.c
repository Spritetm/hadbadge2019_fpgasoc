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
#include "gloss/mach_defines.h"
#include "ipl_flash.h"

volatile uint32_t *MISC=(volatile uint32_t*)MISC_OFFSET;
#define MISC_REG(i) MISC[(i/4)]

static inline void flash_start_xfer(int flash_sel) {
	if (flash_sel!=FLASH_SEL_CURRENT) {
		MISC_REG(MISC_FLASH_SEL_REG)=(flash_sel==0)?MISC_FLASH_SEL_INTFLASH:MISC_FLASH_SEL_CARTFLASH;
	}
	MISC_REG(MISC_FLASH_CTL_REG)=MISC_FLASH_CTL_CLAIM;
}

static inline void flash_end_xfer() {
	while (!(MISC_REG(MISC_FLASH_CTL_REG)&MISC_FLASH_CTL_IDLE));
	MISC_REG(MISC_FLASH_CTL_REG)=0;
}

static inline uint8_t flash_send_recv(uint8_t data) {
	while (!(MISC_REG(MISC_FLASH_CTL_REG)&MISC_FLASH_CTL_IDLE));
	MISC_REG(MISC_FLASH_WDATA_REG)=data;
	while (!(MISC_REG(MISC_FLASH_CTL_REG)&MISC_FLASH_CTL_IDLE));
	return MISC_REG(MISC_FLASH_RDATA_REG);
}

#define CMD_GETUID 0x4B
#define CMD_GETID 0x9f
#define CMD_FASTREAD 0x0B
#define CMD_PAGE_PGM 0x02
#define CMD_READSR1 0x05
#define CMD_READSR2 0x35
#define CMD_READSR3 0x15
#define CMD_WRITESR1 0x01
#define CMD_WRITESR2 0x31
#define CMD_WRITESR3 0x11
#define CMD_WRITEENA 0x06
#define CMD_ERASE4K 0x20
#define CMD_ERASE32K 0x52
#define CMD_ERASE64K 0xD8
#define CMD_WAKE 0xAB
#define CMD_VOLATILE_SR_WRITE_EN 0x50

#define FLASH_READ_USE_DMA 1

uint32_t flash_get_id(int flash_sel) {
	int id=0;
	flash_start_xfer(flash_sel);
	flash_send_recv(CMD_GETID);
	id=flash_send_recv(0)<<16;
	id|=flash_send_recv(0)<<8;
	id|=flash_send_recv(0);
	flash_end_xfer();
	return id;
}

uint64_t flash_get_uid(int flash_sel) {
	uint64_t uid;
	flash_start_xfer(flash_sel);
	flash_send_recv(CMD_GETUID);
	for (int i=0; i<4; i++) flash_send_recv(0);
	for (int i=0; i<8; i++) {
		uid<<=8;
		uid|=flash_send_recv(0);
	}
	flash_end_xfer();
	return uid;
}


void flash_read(int flash_sel, uint32_t addr, uint8_t *buff, int len) {
#if FLASH_READ_USE_DMA
	//Use DMA
	MISC_REG(MISC_FLASH_SEL_REG)=(flash_sel==0)?MISC_FLASH_SEL_INTFLASH:MISC_FLASH_SEL_CARTFLASH;
	while (len>0) {
		//Transfer max 512 words at a time
		int xfer_len=(len+3)/4;
		if (xfer_len>512) xfer_len=512;
		MISC_REG(MISC_FLASH_DMAADDR)=(uint32_t)buff;
		MISC_REG(MISC_FLASH_RDADDR)=addr;
		MISC_REG(MISC_FLASH_DMALEN)=xfer_len; //also starts xfer
		//wait till xfer is done
		while((MISC_REG(MISC_FLASH_CTL_REG) & MISC_FLASH_CTL_DMADONE)==0);
		//subtract work done
		len-=xfer_len*4;
		buff+=xfer_len*4;
		addr+=xfer_len*4;
	}
#else
	//Use manual SPI reads
	flash_start_xfer(flash_sel);
	flash_send_recv(CMD_FASTREAD);
	flash_send_recv(addr>>16);
	flash_send_recv(addr>>8);
	flash_send_recv(addr);
	flash_send_recv(0); //dummy
	for (int i=0; i<len; i++) {
		buff[i]=flash_send_recv(0);
	}
	flash_end_xfer();
#endif
}

uint8_t flash_read_status(int flash_sel, int reg) {
	uint8_t regcmd[3]={CMD_READSR1, CMD_READSR2, CMD_READSR3};
	if (reg<1 || reg>3) return 0xff;
	flash_start_xfer(flash_sel);
	flash_send_recv(regcmd[reg-1]);
	uint8_t r=flash_send_recv(0);
	flash_end_xfer();
	return r;
}

bool flash_write_status(int flash_sel, int reg) {
	uint8_t regcmd[3]={CMD_WRITESR1, CMD_WRITESR2, CMD_WRITESR3};
	if (reg<1 || reg>3) return false;
	flash_start_xfer(flash_sel);
	flash_send_recv(regcmd[reg-1]);
	uint8_t r=flash_send_recv(0);
	flash_end_xfer();
	return true;
}


bool flash_wake(int flash_sel) {
	flash_start_xfer(flash_sel);
	flash_send_recv(CMD_WAKE);
	flash_end_xfer();

#if FLASH_READ_USE_DMA
	//also enable quad i/o mode
	//qpi enable needs to write 2 in status register 2
	flash_start_xfer(flash_sel);
	flash_send_recv(CMD_VOLATILE_SR_WRITE_EN);
	flash_end_xfer();
	flash_start_xfer(flash_sel);
	flash_send_recv(CMD_WRITESR2);
	flash_send_recv(2);
	flash_end_xfer();
#endif
	return true;
}
