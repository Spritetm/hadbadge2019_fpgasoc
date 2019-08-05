//Utility function to perform hexdumps in the default format of the bsd hexdump utility
//(C) 2017 Jeroen Domburg <jeroen at spritesmods dot com>
//This file is public domain where possible or CC0-licensed where not.
//CC0: https://creativecommons.org/share-your-work/public-domain/cc0/

#include <stdio.h>
#include <ctype.h>
#include <stdint.h>

void hexdumpFrom(void *mem, int len, int adrStart) {
	uint8_t *data=(uint8_t*)mem;
	int pos=0;
	while (pos<len) {
		//Print address
		printf("%08x", pos+adrStart);
		//Print hex bytes
		for (int i=0; i<16; i++) {
			if ((i&7)==0) printf(" ");
			if (pos+i<len) {
				printf(" %02x", data[pos+i]);
			} else {
				printf("   ");
			}
		}
		//Print ASCII bytes
		printf("  |");
		for (int i=0; i<16; i++) {
			//Abort if at end
			if (pos+i>=len) break;
			//Print if printable
			if (isprint((int)data[pos+i])) {
				printf("%c", data[pos+i]);
			} else {
				printf(".");
			}
		}
		printf("|\n");
		pos+=16;
	}
	printf("%08x\n", adrStart+len);
}


void hexdump(void *mem, int len) {
	hexdumpFrom(mem, len, 0);
}


//Uncomment the following line and compile 'gcc -o hexdump hexdump.c' to create a barebones hexdump utility that
//reads stdin and dumps the hex content of it to stdout
//#define TESTCASE

#ifdef TESTCASE
#include <stdlib.h>
int main(int argc, char **argv) {
	char buff[1024];
	int adr=0;
	if (argc>1) adr=strtol(argv[1], NULL, 0);
	int i=0;
	int ch;
	while ((ch=getchar())!=EOF) buff[i++]=ch;
	hexdumpFrom(buff, i, adr);
}
#endif
