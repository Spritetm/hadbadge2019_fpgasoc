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
#include "cache.h"

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
extern uint32_t GFXSPRITES[];

uint8_t *lcdfb;


void usb_poll();

typedef void (*main_cb)(int argc, char **argv);


int simulated() {
	return MISC_REG(MISC_SOC_VER)&0x8000;
}

void cdc_task();

extern char _binary_bgnd_png_start;
extern char _binary_bgnd_png_end;
extern char _binary_tileset_default_png_start;
extern char _binary_tileset_default_png_end;

#define FB_PAL_OFFSET 256

void gfx_set_xlate_val(int layer, int xcenter, int ycenter, float scale, float rot) {
	float scale_inv=(1.0/scale);
	float dx_x=cos(rot)*scale_inv;
	float dx_y=-sin(rot)*scale_inv;
	float dy_x=sin(rot)*scale_inv;
	float dy_y=cos(rot)*scale_inv;
	float start_x=-xcenter;
	float start_y=-ycenter;
	
	int i_dx_x=64.0*dx_x;
	int i_dx_y=64.0*dx_y;
	int i_dy_x=64.0*dy_x;
	int i_dy_y=64.0*dy_y;
	int i_start_x=(-start_x+start_x*dx_x-start_y*dx_y)*64.0;
	int i_start_y=(-start_y+start_y*dy_y-start_x*dy_x)*64.0;
	
	GFX_REG(GFX_TILEA_OFF)=(i_start_y<<16)+(i_start_x&0xffff);
	GFX_REG(GFX_TILEA_INC_COL)=(i_dx_y<<16)+(i_dx_x&0xffff);
	GFX_REG(GFX_TILEA_INC_ROW)=(i_dy_y<<16)+(i_dy_x&0xffff);
}

void set_sprite(int no, int x, int y, int sx, int sy, int tileno, int palstart) {
	x+=64;
	y+=64;
	GFXSPRITES[no*2]=(y<<16)|x;
	GFXSPRITES[no*2+1]=sx|(sy<<8)|(tileno<<16)|((palstart/4)<<25);
}

#define SCR_PITCH 20

int show_main_menu(char *app_name) {
	//Allocate fb memory
	lcdfb=malloc(320*512/2);

	//Set up the framebuffer address.
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)lcdfb)&0xFFFFFF;
	//We're going to use a pitch of 512 pixels, and the fb palette will start at 256.
	GFX_REG(GFX_FBPITCH_REG)=(FB_PAL_OFFSET<<GFX_FBPITCH_PAL_OFF)|(512<<GFX_FBPITCH_PITCH_OFF);
	//Blank out fb while we're loading stuff.
	GFX_REG(GFX_LAYEREN_REG)=0;

	//Load up the default tileset and font.
	//ToDo: loading pngs takes a long time... move over to pcx instead.
	printf("Loading tiles...\n");
	gfx_load_tiles_mem(GFXTILES, &GFXPAL[0], &_binary_tileset_default_png_start, (&_binary_tileset_default_png_end-&_binary_tileset_default_png_start));
	printf("Tiles initialized\n");

	//Open the console driver for output to screen.
	FILE *console=fopen("/dev/console", "w");
	setvbuf(console, NULL, _IOLBF, 1024); //make console line buffered
	if (console==NULL) {
		printf("Error opening console!\n");
	}

	//Initialize the LCD
	lcd_init(simulated());
	printf("GFX inited. Yay!!\n");


	printf("Loading bgnd...\n");
	//This is the Hackaday logo background
	gfx_load_fb_mem(lcdfb, &GFXPAL[FB_PAL_OFFSET], 4, 512, &_binary_bgnd_png_start, (&_binary_bgnd_png_end-&_binary_bgnd_png_start));
	//Nuke the palette animation indexes to be black.
	for (int x=0; x<10; x++) GFXPAL[FB_PAL_OFFSET+6+x]=0;
	//Make sure image is in psram
	cache_flush(lcdfb, lcdfb+320*512/2);
	printf("bgnd loaded.\n");

	//Enable layers needed
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEB|GFX_LAYEREN_TILEA|GFX_LAYEREN_SPR;
	GFXPAL[FB_PAL_OFFSET+0x100]=0x00ff00ff; //Note: For some reason, the sprites use this as default bgnd. ToDo: fix this...
	GFXPAL[FB_PAL_OFFSET+0x1ff]=0x40ff00ff; //so it becomes this instead.

	//loop
	int p=0;
	int old_btn=0xfffff; //assume all buttons are pressed, so we need to see a release first before reacting.
	int old_usbstate=-1; //trigger change of usb state whatever state was
	int bgnd_pal_state=10;
	int selected=-1;
	int done=0;
	const char scrtxt[]="                       "
						"Welcome to the Hackaday Supercon 2019 IPL menu thingy! Select an app "
						"or insert an USB cable to modify the files on the flash. Have fun!"
						"                       ";
	int scrpos=0;
	while(!done) {
		p++;

		bgnd_pal_state++;
		if (bgnd_pal_state==200) bgnd_pal_state=0;
		for (int x=0; x<10; x++) {
			GFXPAL[FB_PAL_OFFSET+6+x] = (x==bgnd_pal_state)?GFXPAL[FB_PAL_OFFSET+5]:GFXPAL[FB_PAL_OFFSET+0];
		}

		gfx_set_xlate_val(0, 240,24, 1+sin(p*0.2)*0.1, sin(p*0.11)*0.1);

		int sprno=0;
		for (int x=-(scrpos%SCR_PITCH); x<480; x+=SCR_PITCH) {
			float a=x*0.02+scrpos*0.1;
			set_sprite(sprno++, x, 280+sin(a)*20, 16+cos(a)*8, 16+cos(a)*8, scrtxt[scrpos/SCR_PITCH+sprno], 0);
		}
		if (scrtxt[scrpos/SCR_PITCH+sprno]==0) scrpos=0;
		scrpos+=2;
//		set_sprite(65, 0, 0, 16, 16, 132, 0);


		int usbstate=MISC_REG(MISC_GPEXT_IN_REG)&(1<<31);
		if (usbstate!=old_usbstate) {
			if (usbstate) {
				usb_msc_on();
				fprintf(console, "\0330M\033C\0330A"); //Set map to tilemap A, clear tilemap, set attr to 0
				fprintf(console, "\0338;1PUSB CONNECTED"); //Menu header.
				fprintf(console, "\0331M\033C\n"); //clear menu
			} else {
				usb_msc_off();
				fprintf(console, "\0330M\033C\0330A"); //Set map to tilemap A, clear tilemap, set attr to 0
				fprintf(console, "\0338;1PSELECT AN APP\n\n"); //Menu header.
				fprintf(console, "\0331M\033C\n"); //clear menu
				selected=-1;
			}
		}
		old_usbstate=usbstate;

		int btn=MISC_REG(MISC_BTN_REG);
		//ToDo: we possibly want to store the list of files, so we can select an app even when USB is connected. This will 
		//help for apps which e.g. use the usb cdc-acm
		if (!usbstate) {
			int need_redraw=0;
			if (selected==-1) {
				need_redraw=1;
				selected=0;
				app_name[0]=0;
			}
			if (btn&BUTTON_A && !(old_btn&BUTTON_A)) {
				//start up app
				done=1;
			} else if (btn & BUTTON_UP && !(old_btn&BUTTON_UP)) {
				selected=selected-1;
				if (selected==-1) selected=0;
				need_redraw=1;
			} else if (btn & BUTTON_DOWN && !(old_btn&BUTTON_DOWN)) {
				selected=selected+1;
				need_redraw=1;
			}

			while (need_redraw) {
				fprintf(console, "\033C");
				DIR *d=opendir("/");
				struct dirent *ed;
				int n=0;
				while (ed=readdir(d)) {
					fprintf(console, "\0338;%dP %c %s\n", n+4, n==selected?16:32, ed->d_name);
					if (n==selected) strcpy(app_name, ed->d_name);
					n++;
				}
				closedir(d);
				if (n<=selected) {
					selected=n-1;
				} else {
					need_redraw=0;
				}
			}
		}

		while ((GFX_REG(GFX_VIDPOS_REG)>>16)<318) {
			usb_poll();
			cdc_task();
			tud_task();
		}
		old_btn=btn;
	}

	//Set tilemaps to default 1-to-1 mapping
	GFX_REG(GFX_TILEA_OFF)=(0<<16)+(0&0xffff);
	GFX_REG(GFX_TILEA_INC_COL)=(0<<16)+(64&0xffff);
	GFX_REG(GFX_TILEA_INC_ROW)=(64<<16)+(0&0xffff);
	GFX_REG(GFX_TILEB_OFF)=(0<<16)+(0&0xffff);
	GFX_REG(GFX_TILEB_INC_COL)=(0<<16)+(64&0xffff);
	GFX_REG(GFX_TILEB_INC_ROW)=(64<<16)+(0&0xffff);

	//Clear console
	fprintf(console, "\0330M\033C\0330A"); //Set map to tilemap A, clear tilemap, set attr to 0

	//..and close it.
	fclose(console);
	free(lcdfb);
}

void start_app(char *app) {
	uintptr_t max_app_addr=0;
	uintptr_t la=load_new_app(app, &max_app_addr);
	if (la==0) {
		printf("Loading app %s failed!\n", app);
		return;
	}
	sbrk_app_set_heap_start(max_app_addr);
	main_cb maincall=(main_cb)la;
	maincall(0, NULL);
}

void main() {
	//Initialize USB subsystem
	tusb_init();
	printf("USB inited.\n");
	
	//Initialize filesystem (fatfs, flash translation layer)
	fs_init();
	printf("Filesystem inited.\n");
	while(1) {
		MISC_REG(MISC_LED_REG)=0xfffff;
		syscall_reinit();
		printf("IPL running.\n");
		char app_name[256];
		show_main_menu(app_name);
		printf("IPL: starting app %s\n", app_name);
		usb_msc_off();
		syscall_reinit();
		start_app(app_name);
		printf("IPL: App %s returned.\n", app_name);
	}
}


void cdc_task(void) {
	if (tud_cdc_connected()) {
		tud_cdc_write_flush();
	}
}

//Invoked when cdc when line state changed e.g connected/disconnected
void tud_cdc_line_state_cb(uint8_t itf, bool dtr, bool rts) {
	(void) itf;

	// connected
	if (dtr) {
		// switch stdout/stdin/stderr
		for (int i=0;i<3;i++) {
			close(i);
			open("/dev/ttyUSB", O_RDWR);
		}
	}

	if (!dtr) {
		// switch back to serial
		for (int i=0; i<3; i++) {
			close(i);
			open("/dev/ttyserial", O_RDWR);
		}
	}
}

// Invoked when CDC interface received data from host
void tud_cdc_rx_cb(uint8_t itf) {
	(void)itf;
}
