//Flash reading and programming routines.
//Note: Hard-assumes a 256-byte page and a 4K minimal erase size.

#include "flash.h"
#include "gloss/mach_defines.h"

extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]

static inline void flash_start_xfer(int flash_sel) {
	MISC_REG(MISC_FLASH_SEL_REG)=(flash_sel==0)?MISC_FLASH_SEL_INTFLASH:MISC_FLASH_SEL_CARTFLASH;
	MISC_REG(MISC_FLASH_CTL_REG)=MISC_FLASH_CTL_CLAIM;
}

static inline void flash_end_xfer() {
	while (!(MISC_REG(MISC_FLASH_CTL_REG)&MISC_FLASH_CTL_IDLE));
	MISC_REG(MISC_FLASH_CTL_REG)=0;
	MISC_REG(MISC_FLASH_SEL_REG)=MISC_FLASH_SEL_INTFLASH;
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

bool flash_write_enable(int flash_sel) {
	flash_start_xfer(flash_sel);
	flash_send_recv(CMD_WRITEENA);
	flash_end_xfer();
	return true;
}

bool flash_wake(int flash_sel) {
	flash_start_xfer(flash_sel);
	flash_send_recv(CMD_WAKE);
	flash_end_xfer();
	return true;
}


bool flash_wait_idle(int flash_sel) {
	int to=0x10000;
	uint8_t p;
	while (flash_read_status(flash_sel, 1) & 0x01) {
		to--;
		if (to==0) return false;
	}
	return true;
}

static bool flash_page_program(int flash_sel, uint32_t addr, const uint8_t *buff, int len) {
	//should stay in the same page
	if (((addr+len-1)&0xffff00) != (addr&0xffff00)) return false;
	if (len<1) return false;
	flash_write_enable(flash_sel);
	flash_start_xfer(flash_sel);
	flash_send_recv(CMD_PAGE_PGM);
	flash_send_recv(addr>>16);
	flash_send_recv(addr>>8);
	flash_send_recv(addr);
	for (int i=0; i<len; i++) {
		flash_send_recv(buff[i]);
	}
	flash_end_xfer();
	return flash_wait_idle(flash_sel);
}

bool flash_program(int flash_sel, uint32_t addr, const uint8_t *buff, int len) {
	while (len) {
		int in_page_offset=(addr&255); //offset in page where we start
		int in_page_len=len+in_page_offset; //len if we were to start at the beginning of the page
		if (in_page_len>256) in_page_len=256; //make sure that len doesn't go out of the page
		in_page_len-=in_page_offset; //adjust to actual amount of bytes we need to write not starting from page beginnning
		bool r=flash_page_program(flash_sel, addr, buff, in_page_len);
		if (!r) return false;
		addr+=in_page_len;
		buff+=in_page_len;
		len-=in_page_len;
	}
}

bool flash_erase_range(int flash_sel, int addr, int len) {
	while(len!=0) {
		uint8_t cmd;
		int erasesize;
		flash_start_xfer(flash_sel);
//		printf("addr %x\n", (addr&(32*1024-1)));
		if (len>=(64*1024) && ((addr&(64*1024-1))==0)) {
			cmd=CMD_ERASE64K;
			erasesize=64*1024;
		} else if (len>=(32*1024) && ((addr&(32*1024-1))==0)) {
			cmd=CMD_ERASE32K;
			erasesize=32*1024;
		} else if (len>=(4*1024) && ((addr&(4*1024-1))==0)) {
			cmd=CMD_ERASE4K;
			erasesize=4*1024;
		} else {
			printf("flash_erase_range: no matching block for addr 0x%X len 0x%X\n", addr, len);
			//can't erase this
			return false;
		}
		flash_write_enable(flash_sel);
		flash_start_xfer(flash_sel);
		flash_send_recv(cmd);
		flash_send_recv(addr>>16);
		flash_send_recv(addr>>8);
		flash_send_recv(addr);
		flash_end_xfer();
		if (!flash_wait_idle(flash_sel)) return false;
		addr+=erasesize;
		len-=erasesize;
	}
	return true;
}

