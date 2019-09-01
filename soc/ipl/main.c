#include <stdint.h>
#include <stdlib.h>
#include "gloss/mach_defines.h"
#include "gloss/uart.h"
#include <stdio.h>
#include <lcd.h>
#include <sys/types.h>
#include <dirent.h>
#include "ugui.h"
#include <string.h>
#include "tusb.h"
#include "hexdump.h"
#include "fs.h"
#include "flash.h"
#include "loadapp.h"
#include "gloss/newlib_stubs.h"


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

void cache_flush(void *addr_start, void *addr_end) {
	volatile uint32_t *p = (volatile uint32_t*)(((uint32_t)addr_start & ~3) - MACH_RAM_START + MACH_FLUSH_REGION);
	*p=(uint32_t)addr_end-MACH_RAM_START;
}


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

typedef void (*main_cb)(int argc, char **argv);

void start_app(char *app) {
	uintptr_t max_app_addr=0;
	uintptr_t la=load_new_app(app, &max_app_addr);
	if (la==0) {
		printf("Loading app %s failed!\n", app);
		return;
	}
	printf("Loaded app %s, entry point is 0x%x, max addr used is 0x%X. Running...\n", app, la, max_app_addr);
	sbrk_app_set_heap_start(max_app_addr);
	main_cb maincall=(main_cb)la;
	printf("Go!\n");
	maincall(0, NULL);
	printf("App returned.\n");
}

void main() {
	syscall_reinit();
	printf("IPL running.\n");
	MISC_REG(MISC_LED_REG)=0xff;
	lcd_init();
	lcdfb=calloc(320*512/2, 1);
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)lcdfb)&0x7FFFFF;
	UG_Init(&ugui, lcd_pset, 480, 320);
	UG_FontSelect(&FONT_12X16);
	UG_SetForecolor(C_WHITE);

	tusb_init();
	printf("USB inited.\n");
	
	int id=flash_get_id(FLASH_SEL_INT);
	printf("flashid: %x\n", id);
	fs_init();

	printf("Your random numbers are:\n");
	for (int i=0; i<16; i++) {
		uint32_t r=MISC_REG(MISC_RNG_REG);
		printf("%d: %08X (%d)\n", i, r, r);
	}


	//loop
	int p;
	char buf[20];
	UG_PutString(0, 0, "Hello world!");
	UG_PutString(0, 320-20, "Narf.");
	UG_SetForecolor(C_GREEN);
	UG_PutString(0, 16, "This is a test of the framebuffer to HDMI and LCD thingamajig. What you see now is the framebuffer memory.");
	usb_msc_on();
	while(1) {
		p++;
		sprintf(buf, "%d", p);
		UG_SetForecolor(C_RED);
		UG_PutString(48, 64, buf);
		int btn=MISC_REG(MISC_BTN_REG);
		sprintf(buf, "%d", btn);
		if (btn&BUTTON_A) {
			usb_msc_off();
			start_app("autoexec.elf");
			usb_msc_on();
		}
		UG_PutString(48, 96, buf);
		cache_flush(lcdfb, lcdfb+320*480/2);
		for (int i=0; i<500; i++) {
			usb_poll();
			tud_task();
		}
	}
}
