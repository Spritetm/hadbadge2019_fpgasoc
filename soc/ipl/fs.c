//FileStorage wrapper. This connects the low-level flash through the ftl to the mass storage
//and fatfs drivers.
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
#include <stdlib.h>
#include "gloss/mach_defines.h"
#include "gloss/uart.h"
#include <stdio.h>
#include <lcd.h>
#include "ugui.h"
#include <string.h>
#include "tusb.h"
#include "flash.h"
#include "tjftl/tjftl.h"
#include "hexdump.h"
#include "ff.h"
#include "diskio.h"

//Offset and end of the filesystem partition
#define FS_INT_PART_START 0x380000
#define FS_INT_PART_END 0xD00000
#define FS_INT_TFL_SECT ((FS_INT_PART_END-FS_INT_PART_START-32868*10)/512)

typedef struct {
	int flash_sel;
	int start;
	int end;
} flash_part_desc_t;

static flash_part_desc_t part_int={
	.start=FS_INT_PART_START,
	.end=FS_INT_PART_END,
	.flash_sel=FLASH_SEL_INT
};

static bool tj_flash_read(int addr, uint8_t *buf, int len, void *arg) {
	flash_part_desc_t *part=(flash_part_desc_t*)arg;
	addr+=part->start;
	if (addr+len>part->end) {
		printf("tj_flash_read: read past end %d len %d\n", addr, len);
		return false;
	}
	flash_read(part->flash_sel, addr, buf, len);
	return true;
}

static bool tj_flash_erase_32k(int addr, void *arg) {
	flash_part_desc_t *part=(flash_part_desc_t*)arg;
	addr+=part->start;
	if (addr+32768>part->end) {
		printf("tj_flash_erase_32k: erase past end\n");
		return false;
	}
	return flash_erase_range(part->flash_sel, addr, 32768);
}

static bool tj_flash_program(int addr, const uint8_t *buf, int len, void *arg) {
	flash_part_desc_t *part=(flash_part_desc_t*)arg;
	addr+=part->start;
	if (addr+len>part->end) {
		printf("tj_flash_program: program past end\n");
		return false;
	}
	return flash_program(part->flash_sel, addr, buf, len);
}

#define PDRV_INT FLASH_SEL_INT
#define PDRV_EXT FLASH_SEL_CART
#define PDRV_MAX FLASH_SEL_CART

static tjftl_t *ftl[2];


DSTATUS disk_status (BYTE pdrv) {
	if (pdrv>PDRV_MAX) return STA_NOINIT;
	return (ftl[pdrv]==NULL)?STA_NOINIT:0;
}

DSTATUS disk_initialize(BYTE pdrv) {
	if (pdrv>PDRV_MAX) return STA_NOINIT;
	return (ftl[pdrv]==NULL)?STA_NOINIT:0;
}

DRESULT disk_read(BYTE pdrv, BYTE *buff, DWORD sector, UINT count) {
	if (pdrv>PDRV_MAX) return RES_NOTRDY;
//	printf("disk_read sector %d count %d\n", sector, count);
	bool ok=true;
	while(count) {
		ok&=tjftl_read(ftl[pdrv], sector, buff);
		count--;
		sector++;
		buff+=512;
	}
	if (!ok) printf("disk_read: error at sect %d count %d\n", sector, count);
	return ok?RES_OK:RES_ERROR;
}

DRESULT disk_write(BYTE pdrv, const BYTE *buff, DWORD sector, UINT count) {
	if (pdrv>PDRV_MAX) return RES_NOTRDY;
//	printf("disk_write sector %d count %d\n", sector, count);

	bool ok=true;
	while(count) {
		ok&=tjftl_write(ftl[pdrv], sector, buff);
		count--;
		sector++;
		buff+=512;
	}
	if (!ok) printf("disk_write: error at sect %d count %d\n", sector, count);
	return ok?RES_OK:RES_ERROR;
}

DRESULT disk_ioctl(BYTE pdrv, BYTE cmd, void *buff) {
	if (pdrv>PDRV_MAX) return RES_NOTRDY;
	if (ftl[pdrv]==NULL) return RES_NOTRDY;
	if (cmd==GET_SECTOR_COUNT) {
		DWORD *s=(DWORD*)buff;
		if (pdrv==PDRV_INT) *s=FS_INT_TFL_SECT;
//		if (pdrv==PDRV_EXT) *s=FS_EXT_TFL_SECT;
		return RES_OK;
	} else if (cmd==GET_SECTOR_SIZE) {
		DWORD *s=(DWORD*)buff;
		*s=512;
		return RES_OK;
	} else if (cmd==GET_BLOCK_SIZE) {
		DWORD *s=(DWORD*)buff;
		*s=512;
		return RES_OK;
	} else if (cmd==CTRL_TRIM) {
		//ToDo
	}
	return RES_PARERR;
}

static FATFS fs[2];

static bool msc_enabled=false;

void usb_msc_on() {
	//umount
	f_mount(NULL, "int", 0);
	msc_enabled=true;
}

void usb_msc_off() {
	int res=f_mount(&fs[0], "int", 1); //force mount
	if (res!=FR_OK) {
		printf("Mounting fs failed; trying mkfs\n");
		uint8_t mkfs_buf[512];
		res=f_mkfs("int", FM_FAT, 0, mkfs_buf, 512);
		if (res!=FR_OK) {
			printf("Aiee! Couldn't mount or create internal fat fs! (%d)\n", res);
		}
		res=f_mount(&fs[0], "int", 1);
		if (res!=FR_OK) {
			printf("Aiee! Couldn't mount fs after creating!\n");
		}
	}
}


void fs_init() {
	//Initialize tjftl on internal flash
	flash_wake(FLASH_SEL_INT);
	ftl[0]=tjftl_init(tj_flash_read, tj_flash_erase_32k, tj_flash_program, &part_int,
				FS_INT_PART_END-FS_INT_PART_START, FS_INT_TFL_SECT, true);
	if (!ftl[0]) {
		printf("Aiee! Couldn't initialize ftl for internal flash!\n");
		printf("Nuking flash and re-trying...\n");
		flash_erase_range(FLASH_SEL_INT, FS_INT_PART_START, FS_INT_PART_END-FS_INT_PART_START);
		ftl[0]=tjftl_init(tj_flash_read, tj_flash_erase_32k, tj_flash_program, &part_int,
					FS_INT_PART_END-FS_INT_PART_START, FS_INT_TFL_SECT, true);
		if (!ftl[0]) {
			printf("Still failed. Flash FUBAR?\n");
		}
	}
	usb_msc_off();
}


// Invoked when received SCSI_CMD_INQUIRY
// Application fill vendor id, product id and revision with string up to 8, 16, 4 characters respectively
void tud_msc_inquiry_cb(uint8_t lun, uint8_t vendor_id[8], uint8_t product_id[16], uint8_t product_rev[4]) {
	(void) lun;
	const char vid[] = "HADBadge";
	const char pid[] = "Internal Flash";
	const char rev[] = "1337";
	memcpy(vendor_id  , vid, strlen(vid));
	memcpy(product_id , pid, strlen(pid));
	memcpy(product_rev, rev, strlen(rev));
}

// Invoked when received Test Unit Ready command.
// return true allowing host to read/write this LUN e.g SD card inserted
bool tud_msc_test_unit_ready_cb(uint8_t lun) {
	(void) lun;
	return msc_enabled;
}

// Invoked when received SCSI_CMD_READ_CAPACITY_10 and SCSI_CMD_READ_FORMAT_CAPACITY to determine the disk size
// Application update block count and block size
void tud_msc_capacity_cb(uint8_t lun, uint32_t* block_count, uint16_t* block_size) {
	(void) lun;
	*block_count = FS_INT_TFL_SECT;
	*block_size  = 512;
}

// Invoked when received Start Stop Unit command
// - Start = 0 : stopped power mode, if load_eject = 1 : unload disk storage
// - Start = 1 : active mode, if load_eject = 1 : load disk storage
bool tud_msc_start_stop_cb(uint8_t lun, uint8_t power_condition, bool start, bool load_eject)
{
  (void) lun;
  (void) power_condition;
  return true;
}

// Callback invoked when received READ10 command.
// Copy disk's data to buffer (up to bufsize) and return number of copied bytes.
int32_t tud_msc_read10_cb(uint8_t lun, uint32_t lba, uint32_t offset, void* buffer, uint32_t bufsize) {
	(void) lun;
	if (offset!=0) printf("Eek! tud_msc_read10_cb has offset; %d\n", offset);
	disk_read(PDRV_INT, buffer, lba, bufsize/512);
	return bufsize;
}

// Callback invoked when received WRITE10 command.
// Process data in buffer to disk's storage and return number of written bytes
int32_t tud_msc_write10_cb(uint8_t lun, uint32_t lba, uint32_t offset, uint8_t* buffer, uint32_t bufsize) {
	(void) lun;
	if (offset!=0) printf("Eek! tud_msc_write10_cb has offset; %d\n", offset);
	disk_write(PDRV_INT, buffer, lba, bufsize/512);
	return bufsize;
}

// Callback invoked when received an SCSI command not in built-in list below
// - READ_CAPACITY10, READ_FORMAT_CAPACITY, INQUIRY, MODE_SENSE6, REQUEST_SENSE
// - READ10 and WRITE10 has their own callbacks
int32_t tud_msc_scsi_cb (uint8_t lun, uint8_t const scsi_cmd[16], void* buffer, uint16_t bufsize) {
	// read10 & write10 has their own callback and MUST not be handled here
	void const* response = NULL;
	uint16_t resplen = 0;
	// most scsi handled is input
	bool in_xfer = true;
	
	switch (scsi_cmd[0]) {
		case SCSI_CMD_PREVENT_ALLOW_MEDIUM_REMOVAL:
			// Host is about to read/write etc ... better not to disconnect disk
			resplen = 0;
			break;
		default:
			// Set Sense = Invalid Command Operation
			tud_msc_set_sense(lun, SCSI_SENSE_ILLEGAL_REQUEST, 0x20, 0x00);
			// negative means error -> tinyusb could stall and/or response with failed status
			resplen = -1;
		break;
	}

	// return resplen must not larger than bufsize
	if ( resplen > bufsize ) resplen = bufsize;

	if ( response && (resplen > 0) ) {
		if(in_xfer) {
			memcpy(buffer, response, resplen);
		} else {
			// SCSI output
		}
	}

	return resplen;
}
