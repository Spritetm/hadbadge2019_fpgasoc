#include <stdint.h>
#include <stdlib.h>
#include "gloss/mach_defines.h"
#include "gloss/uart.h"
#include <stdio.h>
#include <lcd.h>
#include "ugui.h"
#include <string.h>
#include "tusb.h"
#include "flash.h"
#include "hexdump.h"

extern volatile uint32_t UART[];
#define UART_REG(i) UART[(i)/4]
extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]
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
	if (c&(1<<7)) n|=4;
	if (c&(1<<15)) n|=2;
	if (c&(1<<23)) n|=1;
	if (c&(1<<6)) n|=8;
	if (c&(1<<14)) n|=8;
	if (c&(1<<22)) n|=8;
	uint8_t o=lcdfb[(x+y*512)/2];
	if (x&1) {
		o=(o&0xf)|(n<<4);
	} else {
		o=(o&0xf0)|(n);
	}
	lcdfb[(x+y*512)/2]=o;
}
volatile char *dummy;

void usb_poll();


void main() {
	MISC_REG(MISC_LED_REG)=0xff;
	dummy=calloc(128*1024, 1);
	lcd_init();
	lcdfb=calloc(320*512/2, 1);
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)lcdfb)&0x7FFFFF;
	UG_Init(&ugui, lcd_pset, 480, 320);
	UG_FontSelect(&FONT_12X16);
	UG_SetForecolor(C_WHITE);

	tusb_init();
	printf("USB inited.\n");
	
	flash_wake(FLASH_SEL_INT);
	int id=flash_get_id(FLASH_SEL_INT);
	printf("flashid: %x\n", id);
	char text[32]="Hello world, this is a flash sector!";
	bool r;
	r=flash_erase_range(FLASH_SEL_INT, 0x300000, 32*1024);
	if (!r) printf("Erase failed\n");
	r=flash_program(FLASH_SEL_INT, 0x300000, text, 256);
	if (!r) printf("Program failed\n");
	text[0]="X";
	flash_read(FLASH_SEL_INT, 0x300000, text, 32);
	printf("Read from flash: %s\n", text);
	hexdump(text, 32);

	//loop
	int p;
	char buf[20];
	UG_PutString(0, 0, "Hello world!");
	UG_PutString(0, 320-20, "Narf!");
	UG_SetForecolor(C_GREEN);
	UG_PutString(0, 16, "This is a test of the framebuffer to HDMI and LCD thingamajig. What you see now is the framebuffer memory.");
	while(1) {
		p++;
		sprintf(buf, "%d", p);
		UG_SetForecolor(C_RED);
		UG_PutString(48, 64, buf);
		id=flash_get_id(FLASH_SEL_INT);
		sprintf(buf, "flashid: %x", id);
		UG_PutString(0, 80, buf);
		memset((void*)dummy, 0, 128*1024);
		usb_poll();
		tud_task();
	}
}
