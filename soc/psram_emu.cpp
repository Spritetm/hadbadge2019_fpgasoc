#include <stdint.h>
#include <stdio.h>
#include <cstdlib>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


#define MEMSIZE (8*1024*1024)
#define APP_START 0x400

static uint8_t *mem;
static int romsize;
static int appsize;

extern int do_abort;

FILE *lafd;

void psram_emu_init() {
	mem=(uint8_t*)malloc(MEMSIZE);
	for (int i=0; i<MEMSIZE; i+=4) {
		mem[i]=0xBE;
		mem[i+1]=0xBA;
		mem[i+2]=0xFE;
		mem[i+3]=0xCA;
	}

	FILE *f=fopen("boot/rom.bin", "rb");
	if (f==NULL) {
		perror("bootrom");
		exit(1);
	}
	romsize=fread(mem, 1, 0x1000, f);
	printf("ROM: %d bytes\n", romsize);
	fclose(f);

	f=fopen("app/app.bin", "rb");
	if (f==NULL) {
		perror("app");
		exit(1);
	}
	appsize=fread(&mem[APP_START], 1, MEMSIZE-APP_START, f);
	printf("APP: %d bytes\n", appsize);
	fclose(f);

	lafd=fopen("lafd.txt", "w");
}

void verify_write(int addr, uint8_t val) {
#if 1
	if (addr<APP_START) {
		if (addr<romsize && mem[addr]!=val) {
			printf("ERROR! Overwriting boot ROM addr 0x%08X with 0x%02X!\n", addr, val);
			do_abort=1;
		}
	} else if (addr >= APP_START && addr < APP_START+appsize) {
		if (mem[addr]!=val) {
			printf("ERROR! Overwriting app addr 0x%X with 0x%X!\n", addr, val);
			do_abort=1;
		}
	}
#endif
}


static int nib=0;
static uint8_t cmd;
static uint32_t addr;
static int qpi_mode=1; //note: hw has 0 here on reset
static int sout_next=0, sout_cur=0;
static int oldclk;
static uint8_t b;
//Called on clock changes.
int psram_emu(int clk, int ncs, int sin, int oe) {
	if (clk && clk!=oldclk) fprintf(lafd, "0.000012340000000,0x%04X\n", (oe?sin:sout_next)|(ncs?0x80:0));
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
			sin&=0xf;
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
					b=(sin<<4);
				} else {
					b|=sin;
					verify_write(addr, b);
					mem[addr]=b;
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
		//negedge clk
		sout_cur=sout_next;
		oldclk=clk;
	}
	oldclk=clk;
//	return sout_cur;
	return sout_next;
}


