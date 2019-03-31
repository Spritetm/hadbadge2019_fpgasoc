#include <stdint.h>
#include <stdio.h>
#include <cstdlib>

#define MEMSIZE 8*1024*1024

static uint8_t *mem;
static uint8_t rom[0x1000];

extern int do_abort;

void psram_emu_init() {
	mem=(uint8_t*)malloc(MEMSIZE);
	for (int i=0; i<MEMSIZE; i++) mem[i]=rand();
	FILE *f=fopen("boot/rom.bin", "rb");
	fread(rom, 1, 0x1000, f);
	fclose(f);
}

void verify_write(int addr, uint8_t val) {
	if (addr<0x10000) {
		if (val!=rom[addr]) {
			printf("ERROR! Overwriting boot ROM addr 0x%08X with 0x%02X!\n", addr, val);
			do_abort=1;
		}
	} else {
		uint32_t tw=0xaaaaaaaa+((addr-0x10000)/4);
		uint8_t tb;
		if ((addr&3)==0) tb=(tw>>0);
		if ((addr&3)==1) tb=(tw>>8);
		if ((addr&3)==2) tb=(tw>>16);
		if ((addr&3)==3) tb=(tw>>24);
		if (val!=tb) {
			printf("ERROR! invalid test byte addr 0x%08X written 0x%02X expected %02X!\n", addr, val, tb);
			do_abort=1;
		}
	}
}


static int nib=0;
static uint8_t cmd;
static uint32_t addr;
static int qpi_mode=0; //note: hw has 0 here on reset
static int sout_next=0, sout_cur=0;
static int oldclk;
//Called on clock changes.
int psram_emu(int clk, int ncs, int sin, int oe) {
	if (ncs==1) {
		nib=0;
		cmd=0;
		addr=0;
	} else if (oldclk==clk) {
		//nothing
	} else if (clk) {
		//posedge clk
		if (!qpi_mode) {
			//Just inited: SPI mode. nib is used as byte ctr
			if (nib<8) {
				cmd<<=1;
				if (sin&1) cmd|=1;
				nib++;
				if (nib==8) {
					if (cmd==0x35) {
						qpi_mode=1;
						printf("psram: switched to qpi mode\n");
					} else {
						printf("psram: Unknown command in SPI mode: 0x%02X\n", cmd);
					}
				}
			}
		} else {
			if (nib==0) cmd|=(sin<<4);
			if (nib==1) cmd|=(sin);
			if (nib==1 && (cmd!=0xeb && cmd!=0x02 && cmd!=0x38)) {
				printf("psram: Unsupported QPI command: 0x%02X\n", cmd);
			}
			if (nib==2) addr|=(sin<<20);
			if (nib==3) addr|=(sin<<16);
			if (nib==4) addr|=(sin<<12);
			if (nib==5) addr|=(sin<<8);
			if (nib==6) addr|=(sin<<4);
			if (nib==7) {
				addr|=(sin);
//				printf("cmd %x addr %x\n", cmd, addr);
			}
			if (nib>=8 && (cmd==0x2 || cmd==0x38)) {
				//write of data
				if ((nib&1)==0) {
					mem[addr]=(sin<<4);
				} else {
					mem[addr]|=sin;
					verify_write(addr, mem[addr]);
					addr++;
				}
			}

			if (nib>=13 && cmd==0xeb) {
				if (nib&1) {
					sout_next=mem[addr]>>4;
				} else {
					sout_next=mem[addr++]&0xf;
				}
			}
			nib++;
		}
	} else {
		sout_cur=sout_next;
		//negedge clk
		oldclk=clk;
	}
	oldclk=clk;
	return sout_cur;
}


