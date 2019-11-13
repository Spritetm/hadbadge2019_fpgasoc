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
#include <string.h>
#include "tusb.h"
#include "flash.h"
#include "tjftl/tjftl.h"
#include "hexdump.h"
#include "ff.h"
#include "diskio.h"

//Offset and end of the filesystem partition
#define FS_INT_PART_START 0x380000
#define FS_INT_PART_END 0x1000000
#define FS_INT_TFL_SECT ((FS_INT_PART_END-FS_INT_PART_START-32868*10)/512)

#define FS_CART_PART_START 0x200000
#define FS_CART_TFL_SECT(cart_size) (((cart_size-1)-FS_CART_PART_START-32868*10)/512)

static int cart_size;

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

static flash_part_desc_t part_cart={
	.start=FS_CART_PART_START,
	.end=0,
	.flash_sel=FLASH_SEL_CART
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

#define PDRV_INT 0
#define PDRV_EXT 1
#define PDRV_MAX FLASH_SEL_CART

static tjftl_t *ftl[2];

DSTATUS disk_status (BYTE pdrv) {
	if (pdrv>PDRV_MAX) return STA_NOINIT;
//	printf("disk_status %d\n", pdrv);
	return (ftl[pdrv]==NULL)?STA_NOINIT:0;
}

DSTATUS disk_initialize(BYTE pdrv) {
	if (pdrv>PDRV_MAX) return STA_NOINIT;
//	printf("disk_initialize %d\n", pdrv);
	return (ftl[pdrv]==NULL)?STA_NOINIT:0;
}

DRESULT disk_read(BYTE pdrv, BYTE *buff, DWORD sector, UINT count) {
	if (pdrv>PDRV_MAX) return RES_NOTRDY;
//	printf("disk_read disk %d sector %d count %d\n", pdrv, sector, count);
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
//	printf("disk_write disk %d sector %d count %d\n", pdrv, sector, count);

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
		if (pdrv==PDRV_EXT) *s=FS_CART_TFL_SECT(cart_size);
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
	if (msc_enabled) return;
	//umount
	f_mount(NULL, "/int", 0);
	if (ftl[1]) f_mount(NULL, "/cart", 0);
	msc_enabled=true;
}

void usb_msc_off() {
	if (!msc_enabled) return;
	MKFS_PARM mkfsopt={
		.fmt=FM_FAT
	};
	int res=f_mount(&fs[0], "/int", 1); //force mount
	if (res!=FR_OK) {
		printf("Mounting fs failed; trying mkfs\n");
		uint8_t mkfs_buf[512];
		res=f_mkfs("/int", &mkfsopt, mkfs_buf, 512);
		if (res!=FR_OK) {
			printf("Aiee! Couldn't mount or create internal fat fs! (%d)\n", res);
		}
		res=f_mount(&fs[0], "/int", 1);
		if (res!=FR_OK) {
			printf("Aiee! Couldn't mount fs after creating!\n");
		}
	}
	if (ftl[1]) {
		//We have a flash translation layer active for cart flash; we can mount the fat there.
		int res=f_mount(&fs[1], "/cart", 1); //force mount
		if (res!=FR_OK) {
			printf("Mounting cart fs failed; trying mkfs\n");
			uint8_t mkfs_buf[512];
			res=f_mkfs("/cart", &mkfsopt, mkfs_buf, 512);
			if (res!=FR_OK) {
				printf("Aiee! Couldn't mount or create cart fat fs! (%d)\n", res);
			}
			res=f_mount(&fs[0], "/cart", 1);
			if (res!=FR_OK) {
				printf("Aiee! Couldn't mount cart fs after creating!\n");
			}
		}
	}
}

void fs_init() {
	if (ftl[0]) return; //don't call twice
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
	flash_wake(FLASH_SEL_CART);
	uint32_t id=flash_get_id(FLASH_SEL_CART);
	printf("Cartridge JEDEC ID: %x\n", id);
	if ((id&0xff)<=0x18) {
		cart_size=1<<(id&0xff);
	} else {
		cart_size=0;
	}
	part_cart.end=cart_size-1;
	if (cart_size && tjftl_detect(tj_flash_read, &part_cart)) {
		printf("tjftl detected on cart. Initing.\n");
		ftl[1]=tjftl_init(tj_flash_read, tj_flash_erase_32k, tj_flash_program, &part_cart,
				(cart_size-1)-FS_CART_PART_START, FS_CART_TFL_SECT(cart_size), true);
		if (!ftl[1]) {
			printf("Failed initializing tjftl on cart... ignoring.\n");
		}
	}
	//Abuse usb_msc_off to mount all filesystems
	msc_enabled=true;
	usb_msc_off();
}

int fs_cart_ftl_active() {
	return (ftl[1]!=NULL);
}

int fs_cart_initialize_fat() {
	if (fs_cart_ftl_active()) return 1;
	flash_wake(FLASH_SEL_CART);
	ftl[1]=tjftl_init(tj_flash_read, tj_flash_erase_32k, tj_flash_program, &part_cart,
			(cart_size-1)-FS_CART_PART_START, FS_CART_TFL_SECT(cart_size), true);
	if (!ftl[1]) {
		printf("Aiee! Couldn't initialize ftl for cart flash!\n");
		printf("Nuking flash and re-trying...\n");
		flash_erase_range(FLASH_SEL_CART, FS_CART_PART_START, (cart_size-1)-FS_CART_PART_START);
		ftl[1]=tjftl_init(tj_flash_read, tj_flash_erase_32k, tj_flash_program, &part_cart,
				(cart_size-1)-FS_CART_PART_START, FS_CART_TFL_SECT(cart_size), true);
		if (!ftl[1]) {
			printf("Still no good. No clue what happened here.\n");
			return 0;
		}
	}
	printf("Cart ftl/fat created succesfully.\n");
}

#define LUN_INT 0
#define LUN_CART 1

// Invoked to determine max LUN
uint8_t tud_msc_get_maxlun_cb(void) {
	return ftl[1]?2:1;
}


// Invoked when received SCSI_CMD_INQUIRY
// Application fill vendor id, product id and revision with string up to 8, 16, 4 characters respectively
void tud_msc_inquiry_cb(uint8_t lun, uint8_t vendor_id[8], uint8_t product_id[16], uint8_t product_rev[4]) {
	(void) lun;
	const char vid[] = "HADBadge";
	const char pid_int[] = "Internal Flash";
	const char pid_cart[] = "Cartridge Flash";
	const char rev[] = "1337";
	memcpy(vendor_id  , vid, strlen(vid));
	if (lun==LUN_INT) {
		memcpy(product_id , pid_int, strlen(pid_int));
	} else {
		memcpy(product_id , pid_cart, strlen(pid_cart));
	}
	memcpy(product_rev, rev, strlen(rev));
}

// Invoked when received Test Unit Ready command.
// return true allowing host to read/write this LUN e.g SD card inserted
bool tud_msc_test_unit_ready_cb(uint8_t lun) {
	return msc_enabled && (ftl[lun]);
}

// Invoked when received SCSI_CMD_READ_CAPACITY_10 and SCSI_CMD_READ_FORMAT_CAPACITY to determine the disk size
// Application update block count and block size
void tud_msc_capacity_cb(uint8_t lun, uint32_t* block_count, uint16_t* block_size) {
	if (lun==0) {
		*block_count = FS_INT_TFL_SECT;
	} else {
		*block_count = FS_CART_TFL_SECT(cart_size);
	}
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
	if (offset!=0) printf("Eek! tud_msc_read10_cb has offset; %d\n", offset);
	disk_read(lun, buffer, lba, bufsize/512);
	return bufsize;
}

// Callback invoked when received WRITE10 command.
// Process data in buffer to disk's storage and return number of written bytes
int32_t tud_msc_write10_cb(uint8_t lun, uint32_t lba, uint32_t offset, uint8_t* buffer, uint32_t bufsize) {
	if (offset!=0) printf("Eek! tud_msc_write10_cb has offset; %d\n", offset);
	disk_write(lun, buffer, lba, bufsize/512);
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
