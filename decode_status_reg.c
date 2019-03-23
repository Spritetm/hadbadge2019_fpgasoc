#include <stdio.h>

int main(int argc, char **argv) {
	int r=strtol(argv[1], NULL, 0);
	printf("%x:\n", r);
	if (r&(1<<0)) printf("Transparent mode\n");
	int cfg=(r>>1)&7;
	printf("Config: ");
	if (cfg==0) {
		printf("SRAM\n");
	} else if (cfg==1) {
		printf("SRAM\n");
	} else {
		printf("Unknown!\n");
	}
	if (r&(1<<4)) printf("JTAG active\n");
	if (r&(1<<5)) printf("PWD protected\n");
	if (r&(1<<7)) printf("Decrypt enable\n");
	if (r&(1<<8)) printf("DONE bit set\n");
	if (r&(1<<9)) printf("ISC enable\n");
	if (r&(1<<10)) printf("Write enable\n");
	if (r&(1<<11)) printf("Read enable\n");
	if (r&(1<<12)) printf("Busy\n");
	if (r&(1<<13)) printf("Fail\n");
	if (r&(1<<14)) printf("FEA OTP\n");
	if (r&(1<<15)) printf("Decrypt only\n");
	if (r&(1<<16)) printf("PWD enable\n");
	if (r&(1<<20)) printf("Encrypt preamble\n");
	if (r&(1<<21)) printf("Std preamble\n");
	if (r&(1<<22)) printf("SPIm fail 1\n");
	printf("BSE error:");
	int bse=(r>>23)&7;
	if (bse==0) {
		printf("No error\n");
	} else if (bse==1) {
		printf("ID error\n");
	} else if (bse==2) {
		printf("Illegal cmd\n");
	} else if (bse==3) {
		printf("CRC error\n");
	} else if (bse==4) {
		printf("Preamble error\n");
	} else if (bse==5) {
		printf("User aborted configuration\n");
	} else if (bse==6) {
		printf("Data overflow error\n");
	} else if (bse==7) {
		printf("Bitstream > size of sram error\n");
	}
	if (r&(1<<26)) printf("Execution error\n");
	if (r&(1<<27)) printf("ID error\n");
	if (r&(1<<28)) printf("Invalid command\n");
	if (r&(1<<29)) printf("SED error\n");
	if (r&(1<<30)) printf("Device is in bypass mode\n");
	if (r&(1<<31)) printf("Device is in flow-through mode\n");
}