#include <stdint.h>
#include <stdlib.h>
#include "gloss/mach_defines.h"
#include "gloss/uart.h"
#include <stdio.h>
#include <lcd.h>
#include "ugui.h"
#include <string.h>

extern volatile uint32_t UART[];
#define UART_REG(i) UART[(i)/4]
extern volatile uint32_t LED[];
#define LED_REG(i) LED[(i)/4]
extern volatile uint32_t LCD[];
#define LCD_REG(i) LCD[(i)/4]
extern volatile uint32_t GFX[];
#define GFX_REG(i) GFX[(i)/4]

uint8_t *lcdfb;
UG_GUI ugui;

static void lcd_pset(UG_S16 x, UG_S16 y, UG_COLOR c) {
	if (lcdfb==NULL) return;
	if (x<0 || x>480) return;
	if (y<0 || y>320) return;
	int n=0;
	if (c) n=0xf;
	if (c&(1<<23)) n|=4;
	if (c&(1<<15)) n|=2;
	if (c&(1<<7)) n|=1;
	if (c&(1<<22)) n|=8;
	if (c&(1<<14)) n|=8;
	if (c&(1<<6)) n|=8;
	uint8_t o=lcdfb[(x+y*512)/2];
	if (x&1) {
		o=(o&0xf)|(n<<4);
	} else {
		o=(o&0xf0)|(n);
	}
	lcdfb[(x+y*512)/2]=o;
}
volatile char *dummy;

void main() {
	dummy=calloc(128*1024, 1);
	LED_REG(0)=0xff;
	lcd_init();
	//lcdfb=calloc(320*480/2, 1);
	lcdfb=(uint8_t*)0x407E0000;
	memset(lcdfb, 0, 480*320/2);
//	GFX_REG(GFX_FBADDR_REG)=((uint32_t)lcdfb)&0x7FFFFF;
	UG_Init(&ugui, lcd_pset, 480, 320);
	UG_FontSelect(&FONT_12X16);
	UG_SetForecolor(C_WHITE);
	for (int y=0; y<320; y+=200) UG_PutString(y, y, "Hello world!");

	memset(dummy, 0, 128*1024);
	//loop
	while(1) {
		printf("%x\n", uart_getchar());
	}
}
