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
#include "ugui.h"
#include <string.h>
#include "tusb.h"
#include "hexdump.h"
#include "fs.h"
#include "flash.h"
#include "loadapp.h"
#include "gloss/newlib_stubs.h"
#include "font-8x16.h"

extern volatile uint32_t UART[];
#define UART_REG(i) UART[(i)/4]
extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]
extern volatile uint32_t LCD[];
#define LCD_REG(i) LCD[(i)/4]
extern volatile uint32_t GFXREG[];
#define GFX_REG(i) GFXREG[(i)/4]
extern volatile uint32_t GFXPAL[];
extern uint32_t GFXTILES[];
extern uint32_t GFXTILEMAPA[];
extern uint32_t GFXTILEMAPB[];

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

void pal_init_egacolors(int offset) {
	GFXPAL[offset+0] =0x101000;
	GFXPAL[offset+1] =0x00007f;
	GFXPAL[offset+2] =0x007f00;
	GFXPAL[offset+3] =0x007f7f;
	GFXPAL[offset+4] =0x7f0000;
	GFXPAL[offset+5] =0x7f007f;
	GFXPAL[offset+6] =0x7f7f00;
	GFXPAL[offset+7] =0x7f7f7f;
	GFXPAL[offset+8] =0x4f4f4f;
	GFXPAL[offset+9] =0x0000ff;
	GFXPAL[offset+10]=0x00ff00;
	GFXPAL[offset+11]=0x00ffff;
	GFXPAL[offset+12]=0xff0000;
	GFXPAL[offset+13]=0xff00ff;
	GFXPAL[offset+14]=0xffff00;
	GFXPAL[offset+15]=0xffffff;
}

void load_font() {
	int ix=0;
	int col;
	for (int ch=0; ch<256; ch++) {
		for (int y=0; y<16; y++) {
			uint32_t p;
			col=0x7;
			uint8_t c=vga_font[ch*16+y];
			for (int n=0; n<8; n++) {
				p<<=4;
				if (c&1) {
					p|=col;
					col=0xf;
				} else {
					col=0x7;
				}
				c>>=1;
			}
			if ((ch&1)==0) {
				GFXTILES[(ch/2)*32+y*2]=p;
			} else {
				GFXTILES[(ch/2)*32+y*2+1]=p;
			}
			GFXTILES[(ch+256)*32+y*2]=p;
			GFXTILES[(ch+256)*32+y*2+1]=0;
		}
	}
}

int simulated() {
	return MISC_REG(MISC_SOC_VER&0x8000);
}

void cdc_task();

void main() {
	MISC_REG(MISC_LED_REG)=0xfffff;
	syscall_reinit();
	printf("IPL running.\n");
	lcdfb=malloc(320*512/2);
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)lcdfb)&0xFFFFFF;
	GFX_REG(GFX_LAYEREN_REG)=(GFX_LAYEREN_FB&0)|GFX_LAYEREN_TILEA|GFX_TILEA_8x16;
//	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_TILEA_8x16;
	for (int i=0; i<512; i+=16) pal_init_egacolors(i);
	for (int i=0; i<64*64; i++) GFXTILEMAPA[i]=32;
	for (int i=0; i<64*64; i++) GFXTILEMAPB[i]=32;
	const char *msg="Hello world, from tilemap A!";
	const char *msg2="This is tilemap B.";
	for (int i=0; msg[i]!=0; i++) GFXTILEMAPA[i+64]=msg[i];
	for (int i=0; msg2[i]!=0; i++) GFXTILEMAPB[i+64]=msg2[i]+256;
	load_font();
	printf("Tiles initialized\n");

	UG_Init(&ugui, lcd_pset, 480, 320);
	if (!simulated) memset(lcdfb, 0, 320*512/2);
	UG_FontSelect(&FONT_12X16);
	UG_SetForecolor(C_WHITE);
	UG_PutString(0, 0, "Hello world!");
	UG_PutString(0, 320-20, "Narf.");
	if (!simulated()) {
		UG_SetForecolor(C_GREEN);
		UG_PutString(0, 16, "This is a test of the framebuffer to HDMI and LCD thingamajig. What you see now is the framebuffer memory.");
		lcd_init();
	}
	cache_flush(lcdfb, lcdfb+320*480/2);
	printf("GFX inited. Yay!!\n");

	while(1) {
		for (int i=0; i<4; i++) {
			GFX_REG(GFX_LAYEREN_REG)=(1<<i)|GFX_TILEA_8x16;
			printf("i %d\n", i);
			volatile int m=simulated()?(1<<5):(1<<20);
			while (m) m--;
			while ((GFX_REG(GFX_VIDPOS)>>16)<319) ;
		}
	}


	tusb_init();
	printf("USB inited.\n");
	

	printf("Your random numbers are:\n");
	for (int i=0; i<16; i++) {
		uint32_t r=MISC_REG(MISC_RNG_REG);
		printf("%d: %08X (%d)\n", i, r, r);
	}

	fs_init();


	//loop
	int p;
	char buf[200];
	usb_msc_on();
	UART_REG(UART_IRDA_DIV_REG)=416;
	int adcdiv=2;
	MISC_REG(MISC_ADC_CTL_REG)=MISC_ADC_CTL_DIV(adcdiv)|MISC_ADC_CTL_ENA;
	while(1) {
		p++;

		UART_REG(UART_IRDA_DATA_REG)=p;
		int r=UART_REG(UART_IRDA_DATA_REG);
		if (r!=-1) {
			sprintf(buf, "%d: IR %d   ", p, r);
			UG_SetForecolor(C_RED);
			UG_PutString(48, 148, buf);
		}

//		MISC_REG(MISC_LED_REG)=p;
		sprintf(buf, "%d", p);
		UG_SetForecolor(C_RED);
		UG_PutString(48, 64, buf);
		int btn=MISC_REG(MISC_BTN_REG);
		sprintf(buf, "%d   ", btn);
		UG_PutString(48, 96, buf);

		int id_int=flash_get_id(FLASH_SEL_INT);
		int id_ext=flash_get_id(FLASH_SEL_CART);
		sprintf(buf, "flashid: %x / %x      ", id_int, id_ext);
		UG_PutString(48, 128, buf);

		r=MISC_REG(MISC_ADC_VAL_REG);
		//ADC measures BAT/2 with a ref of 3.3V (or whatever Vio is) corresponding to 1023
		//int bat=((r/1023)*3.3)*2;
		int bat=(r*3300*2)/(65535);
		sprintf(buf, "%x BAT %d mV (%d)   ", MISC_REG(MISC_ADC_CTL_REG), bat, r);
		UG_SetForecolor(C_BLUE);
		UG_PutString(0, 170, buf);


		if (btn&BUTTON_A) {
			usb_msc_off();
			start_app("autoexec.elf");
			usb_msc_on();
		}
		cache_flush(lcdfb, lcdfb+320*480/2);
		for (int i=0; i<500; i++) {
			usb_poll();
			cdc_task();
			tud_task();
		}
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
