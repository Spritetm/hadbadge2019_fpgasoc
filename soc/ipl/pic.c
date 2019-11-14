#include <stdio.h>
#include "gloss/mach_defines.h"

extern uint32_t PIC_REG[];
extern uint32_t PIC_DATAMEM[];
extern uint32_t PIC_PROGMEM[];

int pic_load_run_file(char *file) {
	FILE *f=fopen(file, "r");
	if (!f) return 0;
	uint8_t *mem=malloc(2048);
	int r=fread(mem, 2048, 1, f);
	fclose(f);
	if (!r) {
		free(mem);
		return 0;
	}
	PIC_REG[0]=PIC_CTL_RESET;
	for (int i=0; i<1024; i++) {
		PIC_PROGMEM[i]=(mem[i*2+1]<<8)|mem[i*2];
	}
	PIC_REG[0]=0;
	free(mem);
	return 1;
}
