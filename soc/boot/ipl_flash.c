#include "gloss/mach_defines.h"
#include "ipl_flash.h"

volatile uint32_t *MISC=(volatile uint32_t*)MISC_OFFSET;
#define MISC_REG(i) MISC[(i/4)]

static inline void flash_start_xfer(int flash_sel) {
	//ToDo: use flash_sel to select internal or external flash cs
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

uint32_t flash_get_id(int flash_sel) {
	int id=0;
	MISC_REG(MISC_FLASH_CTL_REG)=MISC_FLASH_CTL_CLAIM;
	flash_start_xfer(flash_sel);
	flash_send_recv(CMD_GETID);
	id=flash_send_recv(0)<<16;
	id|=flash_send_recv(0)<<8;
	id|=flash_send_recv(0);
	flash_end_xfer();
	return id;
}

void flash_read(int flash_sel, uint32_t addr, uint8_t *buff, int len) {
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
	return true;
}
