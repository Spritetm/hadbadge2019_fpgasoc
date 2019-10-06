#include <stdint.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include "gloss/mach_defines.h"
#include "gloss/uart.h"
#include <stdio.h>
#include <lcd.h>
#include <sys/types.h>
#include <dirent.h>
#include <math.h>
#include <string.h>
#include "tusb.h"
#include "hexdump.h"
#include "fs.h"
#include "flash.h"
#include "loadapp.h"
#include "gloss/newlib_stubs.h"
#include "lodepng/lodepng.h"
#include "gfx_load.h"

extern volatile uint32_t UART[];
#define UART_REG(i) UART[(i)/4]
extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]
extern volatile uint32_t LCD[];
#define LCD_REG(i) LCD[(i)/4]
extern volatile uint32_t GFXREG[];
#define GFX_REG(i) GFXREG[(i)/4]
extern uint32_t GFXPAL[];
extern uint32_t GFXTILES[];
extern uint32_t GFXTILEMAPA[];
extern uint32_t GFXTILEMAPB[];

uint8_t *lcdfb;

void cache_flush(void *addr_start, void *addr_end) {
	volatile uint32_t *p = (volatile uint32_t*)(((uint32_t)addr_start & ~3) - MACH_RAM_START + MACH_FLUSH_REGION);
	*p=(uint32_t)addr_end-MACH_RAM_START;
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
	sbrk_app_set_heap_start(max_app_addr);
	main_cb maincall=(main_cb)la;
	printf("Go!\n");
	maincall(0, NULL);
	printf("App returned.\n");
}


int simulated() {
	return MISC_REG(MISC_SOC_VER)&0x8000;
}

void cdc_task();

extern char _binary_bgnd_png_start;
extern char _binary_bgnd_png_end;
extern char _binary_tileset_default_png_start;
extern char _binary_tileset_default_png_end;

#define FB_PAL_OFFSET 256

void main() {
	MISC_REG(MISC_LED_REG)=0xfffff;
	syscall_reinit();
	printf("IPL running.\n");
	lcdfb=malloc(320*512);
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)lcdfb)&0xFFFFFF;
	GFX_REG(GFX_FBPITCH_REG)=(FB_PAL_OFFSET<<GFX_FBPITCH_PAL_OFF)|(512<<GFX_FBPITCH_PITCH_OFF);
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEB|GFX_LAYEREN_TILEA|GFX_LAYEREN_FB_8BIT;
	gfx_load_tiles_mem(GFXTILES, &GFXPAL[0], &_binary_tileset_default_png_start, (&_binary_tileset_default_png_end-&_binary_tileset_default_png_start));
	for (int i=0; i<64*64; i++) GFXTILEMAPA[i]=32;
	for (int i=0; i<64*64; i++) GFXTILEMAPB[i]=32;
	const char *msg="Hello world, from tilemap A!";
	for (int i=0; msg[i]!=0; i++) GFXTILEMAPA[i+64]=msg[i];
	for (int i=0; msg[i]!=0; i++) GFXTILEMAPA[i+64*32]=msg[i];
	GFX_REG(GFX_TILEA_INC_COL)=(2<<16)+64;
	GFX_REG(GFX_TILEA_INC_ROW)=(60<<16)+2;
	GFX_REG(GFX_TILEB_INC_COL)=64;
	GFX_REG(GFX_TILEB_INC_ROW)=(64<<16);
	printf("Tiles initialized\n");

	FILE *console=fopen("/dev/console", "w");
	setvbuf(console, NULL, _IOLBF, 1024); //make console line buffered
	if (console==NULL) {
		printf("Error opening console!\n");
	}
	fprintf(console, "\0331M\033C\0330A"); //Set map to tilemap B, clear tilemap, set attr to 0
	fprintf(console, "Hello World!\n");

	lcd_init(simulated());
	printf("GFX inited. Yay!!\n");

	tusb_init();
	printf("USB inited.\n");
	
	fs_init();
	printf("Filesystem inited.\n");

	printf("Loading bgnd...\n");
	gfx_load_fb_mem(lcdfb, &GFXPAL[FB_PAL_OFFSET], 8, 512, &_binary_bgnd_png_start, (&_binary_bgnd_png_end-&_binary_bgnd_png_start));
	cache_flush(lcdfb, lcdfb+320*512);
	printf("bgnd loaded.\n");

	//loop
	int p;
	char buf[200];
	usb_msc_on();
	UART_REG(UART_IRDA_DIV_REG)=416;
	int adcdiv=2;
	MISC_REG(MISC_ADC_CTL_REG)=MISC_ADC_CTL_DIV(adcdiv)|MISC_ADC_CTL_ENA;
	int cur_layer=0;
	int old_btn=0;
	float rot=0;
	while(1) {
		p++;

		rot+=0.1;
		int dx=64*cos(rot);
		int dy=64*sin(rot);
		GFX_REG(GFX_TILEA_OFF)=(2<<16)+64;
		GFX_REG(GFX_TILEA_INC_COL)=((dy&0xffff)<<16)|(dx&0xffff);
		GFX_REG(GFX_TILEA_INC_ROW)=((dx&0xffff)<<16)|((-dy)&0xffff);

		UART_REG(UART_IRDA_DATA_REG)=p;
		int r=UART_REG(UART_IRDA_DATA_REG);
		if (r!=-1) {
			fprintf(console, "\0333Y%d: IR %d   \n", p, r);
		}

		int btn=MISC_REG(MISC_BTN_REG);
		fprintf(console, "\0334Ybtn: %d  \n", btn);

		int id_int=flash_get_id(FLASH_SEL_INT);
		int id_ext=flash_get_id(FLASH_SEL_CART);
		fprintf(console, "flashid: %x / %x    \n", id_int, id_ext);

		r=MISC_REG(MISC_ADC_VAL_REG);
		//ADC measures BAT/2 with a ref of 3.3V (or whatever Vio is) corresponding to 1023
		//int bat=((r/1023)*3.3)*2;
		int bat=(r*3300*2)/(65535);
		fprintf(console, "%x BAT %d mV (%d)   \n", MISC_REG(MISC_ADC_CTL_REG), bat, r);


		if (btn&BUTTON_A) {
			usb_msc_off();
			start_app("autoexec.elf");
			usb_msc_on();
		}
		if ((btn&BUTTON_B) && !(old_btn&BUTTON_B)) {
			cur_layer=(cur_layer+1)&0xf;
			GFX_REG(GFX_LAYEREN_REG)=cur_layer|GFX_LAYEREN_FB_8BIT;;
			printf("i %d\n", cur_layer);
		}

		cache_flush(lcdfb, lcdfb+320*512);
		for (int i=0; i<500; i++) {
			usb_poll();
			cdc_task();
			tud_task();
		}
		old_btn=btn;
	}
}

void cdc_task(void)
{
	if ( tud_cdc_connected() )
	{
		tud_cdc_write_flush();
	}
}

// Invoked when cdc when line state changed e.g connected/disconnected
void tud_cdc_line_state_cb(uint8_t itf, bool dtr, bool rts)
{
  (void) itf;

  // connected
	if ( dtr )
	{
		// print initial message when connected
		tud_cdc_write_str("TinyUSB CDC MSC HID device example\r\n");

		// switch stdout/stdin/stderr
		for (int i=0;i<3;i++) {
			close(i);
			open("/dev/ttyUSB", O_RDWR);
		}
	}

	if (!dtr) {
		// switch back to serial
		for (int i=0;i<3;i++) {
			close(i);
			open("/dev/ttyserial", O_RDWR);
		}
	}
}

// Invoked when CDC interface received data from host
void tud_cdc_rx_cb(uint8_t itf)
{
	(void) itf;
}
