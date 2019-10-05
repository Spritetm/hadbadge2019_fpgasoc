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
#include "ugui.h"
#include <string.h>
#include "tusb.h"
#include "hexdump.h"
#include "fs.h"
#include "flash.h"
#include "loadapp.h"
#include "gloss/newlib_stubs.h"
#include "lodepng/lodepng.h"

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
UG_GUI ugui;

void cache_flush(void *addr_start, void *addr_end) {
	volatile uint32_t *p = (volatile uint32_t*)(((uint32_t)addr_start & ~3) - MACH_RAM_START + MACH_FLUSH_REGION);
	*p=(uint32_t)addr_end-MACH_RAM_START;
}


static void lcd_pset_4bit(UG_S16 x, UG_S16 y, UG_COLOR c) {
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

static void lcd_pset_8bit(UG_S16 x, UG_S16 y, UG_COLOR c) {
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
	lcdfb[x+y*512]=n;
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


static inline uint8_t resolve_pixel(unsigned char *pdat, int x, int y, int w, int h, int bpp) {
	int adr=x+w*y;
	if (bpp==8) {
		return pdat[adr];
	} else if (bpp==4) {
		int c=pdat[adr/2];
		if ((adr&1)==0) return (c>>4)&0xf;
		if ((adr&1)==1) return (c>>0)&0xf;
	} else if (bpp==2) {
		int c=pdat[adr/4];
		if ((adr&3)==0) return (c>>6)&0x3;
		if ((adr&3)==1) return (c>>4)&0x3;
		if ((adr&3)==2) return (c>>2)&0x3;
		if ((adr&3)==3) return (c>>0)&0x3;
	} else if (bpp==1) {
		int c=pdat[adr/8];
		return c>>(7-(adr&7));
	} else {
		return 0;
	}
}


int gfx_load_bgnd_mem(uint8_t *fbmem, char *pngstart, int pnglen) {
	unsigned char *decoded;
	unsigned int w, h;
	LodePNGState st={0};
	st.info_raw.colortype=LCT_PALETTE;
	st.info_raw.bitdepth=8;
	st.info_raw.palette=NULL;
	st.info_raw.palettesize=0;
	int i=lodepng_decode(&decoded, &w, &h, &st, pngstart, pnglen);
	printf("lodepng_decode: %d, w=%d, h=%d\n", i, w, h);
	unsigned char *p=decoded;
	for (int i=0; i<st.info_png.color.palettesize; i++) {
		int p=0;
		p=st.info_png.color.palette[i*4];
		p|=st.info_png.color.palette[i*4+1]<<8;
		p|=st.info_png.color.palette[i*4+2]<<16;
		p|=(0xff-st.info_png.color.palette[i*4+3])<<24;
		GFXPAL[i]=p;
	}
	for (int y=0; y<h; y++) {
		for (int x=0; x<w; x++) {
			fbmem[x+y*512]=resolve_pixel(decoded, x,y,w,h,st.info_png.color.bitdepth);
		}
	}
	free(decoded);
	return 1;
}

int gfx_load_tilemem(uint32_t *tilemem, uint32_t *palettemem, char *pngstart, int pnglen) {
	unsigned char *decoded;
	unsigned int w, h;
	LodePNGState st={0};
	st.info_raw.colortype=LCT_PALETTE;
	st.info_raw.bitdepth=8;
	st.info_raw.palette=NULL;
	st.info_raw.palettesize=0;
	int i=lodepng_decode(&decoded, &w, &h, &st, pngstart, pnglen);
	printf("lodepng_decode: %d, w=%d, h=%d\n", i, w, h);
	int palct=st.info_png.color.palettesize;
	if (palct>16) {
		printf("Warning: tileset has more than 16 colors (%d) in palette. Only using first 16.\n", st.info_png.color.palettesize);
		palct=16;
	}
	for (int i=0; i<palct; i++) {
		int p=0;
		p=st.info_png.color.palette[i*4];
		p|=st.info_png.color.palette[i*4+1]<<8;
		p|=st.info_png.color.palette[i*4+2]<<16;
		p|=(0xff-st.info_png.color.palette[i*4+3])<<24;
		palettemem[i]=p;
	}
	//Loop over all the tiles and dump the 16x16 pictures in tilemem.
	int tx=0, ty=0;
	int t=0;
	while (ty+15<h) {
		for (int y=0; y<16; y++) {
			uint64_t tp;
			for (int x=0; x<16; x++) {
				int c=resolve_pixel(decoded, x+tx,y+ty,w,h,st.info_png.color.bitdepth);;
				if (c>15) c=0;
				tp=(tp>>4)|((uint64_t)c<<60UL);
			}
			tilemem[t++]=tp;
			tilemem[t++]=tp>>32;
		}
		tx+=16;
		if (tx+15>w) {
			tx=0;
			ty+=16;
		}
	}
	printf("Loaded %d tiles.\n", t/32);
	free(decoded);
	return 1;
}

int simulated() {
	return MISC_REG(MISC_SOC_VER)&0x8000;
}

void cdc_task();

extern char _binary_bgnd_png_start;
extern char _binary_bgnd_png_end;
extern char _binary_tileset_default_png_start;
extern char _binary_tileset_default_png_end;


void main() {
	MISC_REG(MISC_LED_REG)=0xfffff;
	syscall_reinit();
	printf("IPL running.\n");
	lcdfb=malloc(320*512);
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)lcdfb)&0xFFFFFF;
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEB|GFX_LAYEREN_TILEA|GFX_LAYEREN_FB_8BIT;
	gfx_load_tilemem(GFXTILES, &GFXPAL[256], &_binary_tileset_default_png_start, (&_binary_tileset_default_png_end-&_binary_tileset_default_png_start));
	for (int i=0; i<64*64; i++) GFXTILEMAPA[i]=32|(1<<17);
	for (int i=0; i<64*64; i++) GFXTILEMAPB[i]=33|(1<<17);
	const char *msg="Hello world, from tilemap A!";
	const char *msg2="This is tilemap B.";
	for (int i=0; msg[i]!=0; i++) GFXTILEMAPA[i+64]=msg[i]|(1<<17);
	for (int i=0; msg[i]!=0; i++) GFXTILEMAPA[i+64*32]=msg[i]|(1<<17);
	for (int i=0; msg2[i]!=0; i++) GFXTILEMAPB[i+64]=msg2[i]|(1<<17);
	GFX_REG(GFX_TILEA_INC_COL)=(2<<16)+64;
	GFX_REG(GFX_TILEA_INC_ROW)=(60<<16)+2;
	GFX_REG(GFX_TILEB_INC_COL)=(2<<16)+64;
	GFX_REG(GFX_TILEB_INC_ROW)=(60<<16)+2;
	printf("Tiles initialized\n");

	lcd_init(simulated());
	UG_Init(&ugui, lcd_pset_8bit, 480, 320);
	if (!simulated) memset(lcdfb, 0, 320*512);
	MISC_REG(MISC_SOC_VER)=1;
	cache_flush(lcdfb, lcdfb+320*512);
	MISC_REG(MISC_SOC_VER)=0;

	UG_FontSelect(&FONT_12X16);
	UG_SetForecolor(C_WHITE);
	UG_PutString(0, 0, "Hello world!");
	UG_PutString(0, 320-20, "Narf.");
	if (!simulated()) {
		UG_SetForecolor(C_GREEN);
		UG_PutString(0, 16, "This is a test of the framebuffer to HDMI and LCD thingamajig. What you see now is the framebuffer memory.");
	}
	cache_flush(lcdfb, lcdfb+320*512);
	printf("GFX inited. Yay!!\n");


	tusb_init();
	printf("USB inited.\n");
	
	fs_init();

	printf("Loading bgnd...\n");
	gfx_load_bgnd_mem(lcdfb, &_binary_bgnd_png_start, (&_binary_bgnd_png_end-&_binary_bgnd_png_start));
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
