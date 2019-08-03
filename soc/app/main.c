#include <stdint.h>
#include <stdlib.h>
#include "gloss/mach_defines.h"
#include "gloss/uart.h"
#include <stdio.h>
#include <lcd.h>
#include "ugui.h"
#include <string.h>
#include "tusb.h"

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

static inline uint8_t flash_send_recv(uint8_t data) {
	MISC_REG(MISC_FLASH_WDATA_REG)=data;
	while (!(MISC_REG(MISC_FLASH_CTL_REG)&MISC_FLASH_CTL_IDLE));
	return MISC_REG(MISC_FLASH_RDATA_REG);
}

int flash_get_id() {
	int id=0;
	MISC_REG(MISC_FLASH_CTL_REG)=MISC_FLASH_CTL_CLAIM;
	flash_send_recv(0x9F);
	id=flash_send_recv(0)<<16;
	id|=flash_send_recv(0)<<8;
	id|=flash_send_recv(0);
	MISC_REG(MISC_FLASH_CTL_REG)=0;
	return id;
}


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
		int id=flash_get_id();
		sprintf(buf, "flashid: %x", id);
		UG_PutString(0, 80, buf);
		memset((void*)dummy, 0, 128*1024);
		usb_poll();
		tud_task();
	}
}
