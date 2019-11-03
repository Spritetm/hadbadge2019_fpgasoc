#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "mach_defines.h"
#include "gfx_load.h"
#include "cache.h"

//hardware addresses I really need to dump into an include or something...
extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]

extern volatile uint32_t SYNTH[];
#define SYNTHREG(i) SYNTH[i/4]

static inline void button_wait(){
	//Wait until all buttons are released
	while (MISC_REG(MISC_BTN_REG)) ;
	//Wait until button A is pressed
	while ((MISC_REG(MISC_BTN_REG) & BUTTON_A)==0) ;
}

static inline void pause(void){
	for (volatile uint32_t i=0; i<0x0003fff0; i++){;}
}

void main(int argc, char **argv) {
	//We're running in app context. We have full control over the badge and can do with the hardware what we want. As
	//soon as main() returns, however, we will go back to the IPL.

	SYNTHREG(0x40) = 0x00151800;	
	SYNTHREG(0x50) = 0x00251E00;	
	SYNTHREG(0x60) = 0x00352400;	
	SYNTHREG(0x70) = 0x00453000;	
	pause();
	pause();
	SYNTHREG(0x04) = 0x00000311;	
	SYNTHREG(0x00) = 0x04680C00;	
	pause();
	pause();
	pause();
	pause();
	SYNTHREG(0x40) = 0x008A1200;	
	pause();
	SYNTHREG(0x50) = 0x008A1680;	
	pause();
	SYNTHREG(0x60) = 0x008A1800;	
	pause();
	SYNTHREG(0x70) = 0x008A2400;	
	pause();
	SYNTHREG(0x40) = 0x008A1800;	
	pause();
	SYNTHREG(0x50) = 0x008A1680;	
	pause();
	SYNTHREG(0x24) = 0x00000301;	
	SYNTHREG(0x20) = 0x04681200;	
	SYNTHREG(0x60) = 0x008A1200;	
	pause();
	SYNTHREG(0x70) = 0x008A2400;	
	pause();
	pause();
	pause();
	SYNTHREG(0x34) = 0x00000301;	
	SYNTHREG(0x30) = 0x04680C00;	
	pause();
	pause();
}

