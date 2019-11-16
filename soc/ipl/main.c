/*
 * Copyright 2019 Jeroen Domburg <jeroen@spritesmods.com>
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software.  If not, see <https://www.gnu.org/licenses/>.
 */
#include <stdint.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include "gloss/mach_defines.h"
#include "gloss/mach_interrupt.h"
#include "gloss/uart.h"
#include <stdio.h>
#include <lcd.h>
#include <sys/types.h>
#include <dirent.h>
#include <math.h>
#include <string.h>
#include "tusb.h"
#include "usb_descriptors.h"
#include "hexdump.h"
#include "fs.h"
#include "flash.h"
#include "loadapp.h"
#include "gloss/newlib_stubs.h"
#include "lodepng/lodepng.h"
#include "gfx_load.h"
#include "cache.h"
#include "user_memfn.h"
#include "badgetime.h"

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
extern uint32_t GFXCOPPEROPS[];

extern volatile uint32_t SYNTH[];
#define SYNTHREG(i) SYNTH[i/4]

// When USE_8_BIT_TRIG is defined, IPL will calculate position of main menu's
// animated letters using the less accurate but fast 8-bit sin/cos functions
// copied from the FastLED library: https://github.com/FastLED/FastLED
// The reduced accuracy is not critical for animation purposes but the speed
// increase allows us to spend more time on USB tasks. This allows the USB mass
// storage device to mount faster, copy ELF faster, etc.
#define USE_8_BIT_TRIG

uint8_t *lcdfb;


void usb_poll();

typedef void (*main_cb)(int argc, char **argv);


int simulated() {
	return MISC_REG(MISC_SOC_VER)&0x8000;
}

//When in verilator, this starts a trace of the SoC.
void verilator_start_trace() {
	MISC_REG(MISC_SOC_VER)=1;
}

extern uint32_t rom_cart_boot_flag;

int booted_from_cartridge() {
	return rom_cart_boot_flag;
}

void boot_fpga_bitstream(int from_cart) {
	int src=0;
	if (from_cart) src=MISC_FLASH_SEL_CARTFLASH;
	MISC_REG(MISC_FLASH_SEL_REG)=src;
	volatile int w;
	for (w=0; w<16; w++) ;
	MISC_REG(MISC_FLASH_SEL_REG)=src|MISC_FLASH_SEL_FPGARELOAD_MAGIC;
}

extern char _binary_bgnd_tga_start;
extern char _binary_bgnd_tga_end;
extern char _binary_tileset_default_tga_start;
extern char _binary_tileset_default_tga_end;

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

#ifdef USE_8_BIT_TRIG
// sin8_c and cos8_C are 8-bit low-precision approximation of trig functions
// from the FastLED library: https://github.com/FastLED/FastLED
const uint8_t b_m16_interleave[] = { 0, 49, 49, 41, 90, 27, 117, 10 };
uint8_t sin8_C( uint8_t theta)
{
    uint8_t offset = theta;
    if( theta & 0x40 ) {
        offset = (uint8_t)255 - offset;
    }
    offset &= 0x3F; // 0..63

    uint8_t secoffset  = offset & 0x0F; // 0..15
    if( theta & 0x40) secoffset++;

    uint8_t section = offset >> 4; // 0..3
    uint8_t s2 = section * 2;
    const uint8_t* p = b_m16_interleave;
    p += s2;
    uint8_t b   =  *p;
    p++;
    uint8_t m16 =  *p;

    uint8_t mx = (m16 * secoffset) >> 4;

    int8_t y = mx + b;
    if( theta & 0x80 ) y = -y;

    y += 128;

    return y;
}
uint8_t cos8_C( uint8_t theta)
{
    return sin8_C( theta + 64);
}
#endif // USE_8_BIT_TRIG

void set_sprite(int no, int x, int y, int sx, int sy, int tileno, int palstart) {
	x+=64;
	y+=64;
	GFXSPRITES[no*2]=(y<<16)|x;
	GFXSPRITES[no*2+1]=sx|(sy<<8)|(tileno<<16)|((palstart/4)<<25);
}

#define ITEM_MAX 256

#define ITEM_FLAG_SELECTABLE (1<<0)
#define ITEM_FLAG_ON_CART (1<<1)
#define ITEM_FLAG_BITSTREAM (1<<2)
#define ITEM_FLAG_FORMAT (1<<3)

typedef struct {
	int no_items;
	int flag[ITEM_MAX];
	char *item[ITEM_MAX];
} menu_data_t;


void menu_add_apps(menu_data_t *s, char *path, int flag) {
	DIR *d=opendir(path);
	struct dirent *ed;
	int found=0;
	while (ed=readdir(d)) {
		if (strcmp(ed->d_name, "autoexec.elf")!=0 && strlen(ed->d_name)>4 && strcasecmp(&ed->d_name[strlen(ed->d_name)-4], ".elf")==0) {
			s->item[s->no_items]=strdup(ed->d_name);
			s->flag[s->no_items++]=flag;
			found=1;
		}
	}
	if (!found) {
		s->item[s->no_items]=strdup("*NO FILES*");
		s->flag[s->no_items++]=flag;
	}
	closedir(d);
}

int cart_has_fpga_image() {
	const char magic[]="\xFF\x00Part: LFE5U-45F-8CABGA381";
	char buf[128];
	flash_wake(FLASH_SEL_CART);
	flash_read(FLASH_SEL_CART, 0, buf, sizeof(magic));
	return memcmp(buf, magic, sizeof(magic))==0;
}

//If the first 512 bytes of the tjftl partition are 0xff, we assume it's an unerased cart and we're free
//to create the tjftl part. If not, we assume it's used for 'other' stuff and we hide the option.
int cart_tjftl_creatable() {
	char buf[512];
	flash_read(FLASH_SEL_CART, 0x200000, buf, 512);
	for (int x=0; x<512; x++) {
		if (buf[x]!=0xff) return 0;
	}
	return 1;
}

extern uint32_t rom_cart_boot_flag;

void read_menu_items(menu_data_t *s) {
	//First, clean struct
	for (int i=0; i<s->no_items; i++) free(s->item[i]);
	s->no_items=0;
	//Check if external memory is available.
	int has_cart=(flash_get_uid(FLASH_SEL_CART)!=0);
	if (has_cart) {
		s->flag[s->no_items]=0;
		s->item[s->no_items++]=strdup("- CARTRIDGE -");
		if (!booted_from_cartridge() &&  cart_has_fpga_image()) {
			s->flag[s->no_items]=ITEM_FLAG_SELECTABLE|ITEM_FLAG_ON_CART|ITEM_FLAG_BITSTREAM;
			s->item[s->no_items++]=strdup("Boot FPGA bitstream");
		}
		if (fs_cart_ftl_active()) {
			//Add cart items
			menu_add_apps(s, "/cart/", ITEM_FLAG_SELECTABLE|ITEM_FLAG_ON_CART);
		} else if (cart_tjftl_creatable()) {
			s->flag[s->no_items]=ITEM_FLAG_SELECTABLE|ITEM_FLAG_ON_CART|ITEM_FLAG_FORMAT;
			s->item[s->no_items++]=strdup("Format filesystem");
		}
		s->flag[s->no_items]=0;
		s->item[s->no_items++]=strdup("- INTERNAL -");
		if (booted_from_cartridge()) {
			s->flag[s->no_items]=ITEM_FLAG_SELECTABLE|ITEM_FLAG_BITSTREAM;
			s->item[s->no_items++]=strdup("Boot FPGA bitstream");
		}
	}
	menu_add_apps(s, "/int/", ITEM_FLAG_SELECTABLE);
}

void load_tiles() {
	//ToDo: loading pngs takes a long time... move over to pcx instead.
	printf("Loading tiles...\n");
	gfx_load_tiles_tga_mem(GFXTILES, &GFXPAL[0], &_binary_tileset_default_tga_start, (&_binary_tileset_default_tga_end-&_binary_tileset_default_tga_start));
	printf("Tiles initialized\n");
}

#define SCR_PITCH 20 //Scoller letter pitch

int show_main_menu(char *app_name, int *ret_flags) {
	menu_data_t menu={0};

	//First read of available items
	usb_msc_off();
	read_menu_items(&menu);

	//Allocate fb memory
	lcdfb=malloc(320*512/2);


	//Set up the framebuffer address.
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)lcdfb)&0xFFFFFF;
	//We're going to use a pitch of 512 pixels, and the fb palette will start at 256.
	GFX_REG(GFX_FBPITCH_REG)=(FB_PAL_OFFSET<<GFX_FBPITCH_PAL_OFF)|(512<<GFX_FBPITCH_PITCH_OFF);
	//Blank out fb while we're loading stuff.
	GFX_REG(GFX_LAYEREN_REG)=0;

	//Load up the default tileset and font.
	load_tiles();

	//Open the console driver for output to screen.
	FILE *console=fopen("/dev/console", "w");
	setvbuf(console, NULL, _IOLBF, 1024); //make console line buffered
	if (console==NULL) {
		printf("Error opening console!\n");
	}
	fprintf(console, "\0331M\033C\0330A"); //Set map to tilemap B, clear tilemap, set attr to 0

	//Erase tilemaps
	for (int x=0; x<64*64; x++) GFXTILEMAPA[x]=0x20;
	for (int x=0; x<64*64; x++) GFXTILEMAPB[x]=0x20;

	printf("GFX inited. Yay!!\n");

	printf("Loading bgnd...\n");
	//This is the Hackaday logo background
	gfx_load_fb_tga_mem(lcdfb, &GFXPAL[FB_PAL_OFFSET], 4, 512, &_binary_bgnd_tga_start, (&_binary_bgnd_tga_end-&_binary_bgnd_tga_start));

	//Nuke the palette animation indexes to be black.
	for (int x=0; x<10; x++) GFXPAL[FB_PAL_OFFSET+6+x]=0;
	//Make sure image is in psram
	cache_flush(lcdfb, lcdfb+320*512/2);
	printf("bgnd loaded.\n");

	GFX_REG(GFX_TILEB_OFF)=(0<<16)+(0&0xffff);
	GFX_REG(GFX_TILEB_INC_COL)=(0<<16)+(64&0xffff);
	GFX_REG(GFX_TILEB_INC_ROW)=(64<<16)+(0&0xffff);


	//Enable layers needed
	GFX_REG(GFX_LAYEREN_REG)=GFX_LAYEREN_FB|GFX_LAYEREN_TILEB|GFX_LAYEREN_TILEA|GFX_LAYEREN_SPR;
	GFXPAL[0]=0x00ff00ff; //Transparency layer for tiles - somehow this doesn't get set correctly.
	GFXPAL[0x1ff]=0x00ff00ff; //Color the sprite layer uses when no sprites are drawn - 100% transparent.

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

	//Generate copper list to transform the center of the screen into a barrel-ish
	//shape for tile layer B.
	uint32_t *cmem=GFXCOPPEROPS;
	for (int y=60; y<240; y++) {
		//X offset follows a circle
		int xof=sqrt((100*100)-(y-160)*(y-160));
		//Y offset is fudged because I can't be bothered to do the math
		int yoff=0;
		if (y<100) yoff=(y-100)*16;
		if (y>200) yoff=(y-200)*16;
		//Have copper wait for the selected Y coordinate.
		*cmem++=COPPER_OP_WAIT(0, y);
		//When that is reached, write the desired X and Y offset into the TILEB_OFF register
		*cmem++=COPPER_OP_WRITE(&GFX_REG(GFX_TILEB_OFF), 1),
		*cmem++=((((yoff)&0xffff)<<16)+((xof*32)&0xffff));
	}
	//Finally, we probably want the screen to start with an offset of 0.
	*cmem++=COPPER_OP_WAIT(0, 0);
	*cmem++=COPPER_OP_WRITE(&GFX_REG(GFX_TILEB_OFF), 1),
	*cmem++=0;
	//Last instruction: loop back to start
	*cmem++=COPPER_OP_RESET;
	//Enable copper so it can... errm... cop.
	GFX_REG(GFX_COPPER_CTL_REG)=GFX_COPPER_CTL_RUN;

	while(!done) {
		//Record what frame we are on right now.
		uint32_t cur_vbl_ctr=GFX_REG(GFX_VBLCTR_REG);

		//This does the 'radar' effect around the skull'n'wrenches. The radar waves are encoded in the
		//pallete, in entries that have been blanked out earlier (index 10 - 16). If bgnd_pal_state is one
		//of those entries, we copy color index 5 into it (the brown from the main skull) otherwise we keep
		//blanking it.
		bgnd_pal_state++;
		if (bgnd_pal_state==200) bgnd_pal_state=0;
		for (int x=0; x<10; x++) {
			GFXPAL[FB_PAL_OFFSET+6+x] = (x==bgnd_pal_state)?GFXPAL[FB_PAL_OFFSET+5]:GFXPAL[FB_PAL_OFFSET+0];
		}

		//The menu header is printed to tilemap A. We jiggle it around by moving the entirety of tilemap A around.
		p++;
		#ifdef USE_8_BIT_TRIG
		float angle_scale = p*0.2;
		float angle_rotate = p*0.11;
		uint8_t angle8_scale = angle_scale*40;
		uint8_t angle8_rotate = angle_rotate*40;
		float sin8_scale = (sin8_C(angle8_scale)-0x7F)/128.0;
		float sin8_rotate = (sin8_C(angle8_rotate)-0x7F)/128.0;
		gfx_set_xlate_val(0, 240,24, 1+sin8_scale*0.1, sin8_rotate*0.1);
		#else
		gfx_set_xlate_val(0, 240,24, 1+sin(p*0.2)*0.1, sin(p*0.11)*0.1);
		#endif

		//This sets up all the sprites for the sinusodial scroller at the bottom.
		int sprno=0;
		for (int x=-(scrpos%SCR_PITCH); x<480; x+=SCR_PITCH) {
			float a=x*0.02+scrpos*0.1;
			#ifdef USE_8_BIT_TRIG
			// Convert the angle input from floating point [-PI, PI] to [0,255]
			// 127 / 3.14 = 40.44, rounding down to 40 as our multiplier.
			uint8_t angle8 = a*40+0x7F;
			// Convert sin/cosine output from [0,255] to [-1.0, 1,0]
			float sin8 = (sin8_C(angle8)-0x7F)/128.0;
			float cos8 = (cos8_C(angle8)-0x7F)/128.0;
			set_sprite(sprno++, x, 280+sin8*20, 16+cos8*8, 16+cos8*8, scrtxt[scrpos/SCR_PITCH+sprno], 0);
			#else
			set_sprite(sprno++, x, 280+sin(a)*20, 16+cos(a)*8, 16+cos(a)*8, scrtxt[scrpos/SCR_PITCH+sprno], 0);
			#endif
		}
		if (scrtxt[scrpos/SCR_PITCH+sprno]==0) scrpos=0;
		scrpos+=2;

		int usbstate=MISC_REG(MISC_GPEXT_IN_REG)&(1<<31);
		if (usbstate!=old_usbstate) {
			if (usbstate) {
				usb_msc_on();
				fprintf(console, "\0330M\033C\0330A"); //Set map to tilemap A, clear tilemap, set attr to 0
				fprintf(console, "\0338;1PUSB CONNECTED"); //Menu header.
				selected=-1;
			} else {
				usb_msc_off();
				read_menu_items(&menu);
				fprintf(console, "\0330M\033C\0330A"); //Set map to tilemap A, clear tilemap, set attr to 0
				fprintf(console, "\0338;1PSELECT AN APP\n\n"); //Menu header.
				selected=-1;
			}
		}
		old_usbstate=usbstate;

		int btn=MISC_REG(MISC_BTN_REG);
		int need_redraw=0;
		if (selected==-1) {
			need_redraw=1;
			selected=0;
		}
		int movedir=0;
		if (btn&BUTTON_A && !(old_btn&BUTTON_A)) {
			//start up app
			done=1;
		} else if (btn & BUTTON_UP && !(old_btn&BUTTON_UP)) {
			movedir=-1;
			need_redraw=1;
		} else if (btn & BUTTON_DOWN && !(old_btn&BUTTON_DOWN)) {
			movedir=1;
			need_redraw=1;
		}
		//Note: This assumes there's always one selectable item in the menu.
		do {
			selected+=movedir;
			if (selected<0) selected=menu.no_items-1;
			if (selected>=menu.no_items) selected=0;
			if (movedir==0) movedir=1; //if we loop we need to go somewhere
		} while((menu.flag[selected] & ITEM_FLAG_SELECTABLE)==0);

		if (need_redraw) {
			fprintf(console, "\0331M\033C\n"); //select tilemap B, clear menu

			int start=selected-5;
			for (int i=0; i<11; i++) {
				const char *itm;
				itm="";
				if (i+start>=0 && i+start<menu.no_items) itm=menu.item[i+start];
				fprintf(console, "\0338;%dP %c %s\n", i+4, (i+start)==selected?16:32, itm);
			}
		}

		//Idle doing USB stuff while the current frame is still active.
		wait_for_next_frame(cur_vbl_ctr+1); //we run at 30fps
		old_btn=btn;
	}
	
	if (selected>=0) {
		if (menu.flag[selected]&ITEM_FLAG_ON_CART) {
			sprintf(app_name, "/cart/%s", menu.item[selected]);
		} else {
			sprintf(app_name, "/int/%s", menu.item[selected]);
		}
		*ret_flags=menu.flag[selected];
	}
	for (int i=0; i<menu.no_items; i++) free(menu.item[i]);

	//Set tilemaps to default 1-to-1 mapping
	GFX_REG(GFX_TILEA_OFF)=(0<<16)+(0&0xffff);
	GFX_REG(GFX_TILEA_INC_COL)=(0<<16)+(64&0xffff);
	GFX_REG(GFX_TILEA_INC_ROW)=(64<<16)+(0&0xffff);
	GFX_REG(GFX_TILEB_OFF)=(0<<16)+(0&0xffff);
	GFX_REG(GFX_TILEB_INC_COL)=(0<<16)+(64&0xffff);
	GFX_REG(GFX_TILEB_INC_ROW)=(64<<16)+(0&0xffff);
	GFX_REG(GFX_COPPER_CTL_REG)=0; //disable copper
	for (int i=0; i<128*2; i++) GFXSPRITES[i]=0; //reset sprites
	//Clear console
	fprintf(console, "\0330M\033C\0330A"); //Set map to tilemap A, clear tilemap, set attr to 0

	//..and close it.
	fclose(console);
	free(lcdfb);
	return 0;
}

void start_app(const char *app) {
	uintptr_t max_app_addr=0;
	uintptr_t la=load_new_app(app, &max_app_addr);
	if (la==0) {
		printf("Loading app %s failed!\n", app);
		return;
	}
	sbrk_app_set_heap_start(max_app_addr);
	user_memfn_set(NULL, NULL, NULL);
	syscall_reinit();
	main_cb maincall=(main_cb)la;
	maincall(0, NULL);
	user_memfn_set(malloc, realloc, free);
	syscall_reinit();
	//Disable all but USB interrupt and error handlers
	mach_int_dis(~((1<<INT_NO_USB)|(1<<INT_NO_ILLINSTR)|(1<<INT_NO_UNALIG)|(1<<INT_NO_BUSERR)));
}

static void
usb_setup_serial_no(void)
{
	extern char const* string_desc_arr[];
	uint64_t serial = flash_get_uid(FLASH_SEL_INT);
	sprintf((void*)string_desc_arr[3], "%016llx", serial);
}

int read_leds_on() {
	FILE *f=fopen("ledval.txt", "r");
	if (!f) {
		return 0xAA|(1<<8)|(1<<9); //only light blue, power and 'the other' LED
	}
	char buf[10];
	fgets(buf, 10, f);
	fclose(f);
	return atoi(buf);
}

extern uint32_t *irq_stack_ptr;

#define IRQ_STACK_SIZE (16*1024)

void main() {
	syscall_reinit();
	user_memfn_set(malloc, realloc, free);
	verilator_start_trace();
	//When testing in Verilator, put code that pokes your hardware here.

	if (pic_load_run_file("/cart/pic_firmware.bin")) {
		printf("Found and loaded PIC payload from cart.\n");
	} else if (pic_load_run_file("/int/pic_firmware.bin")) {
		printf("Found and loaded PIC payload from internal flash.\n");
	}

	LCD_REG(LCD_BL_LEVEL_REG)=0x5000; //save some power by lowering the backlight

	//Initialize IRQ stack to be bigger than the bootrom stack
	uint32_t *int_stack=malloc(IRQ_STACK_SIZE);
	irq_stack_ptr=int_stack+(IRQ_STACK_SIZE/sizeof(uint32_t));

	//Initialize filesystem (fatfs, flash translation layer)
	fs_init();
	printf("Filesystem inited.\n");

	if (pic_load_run_file("/cart/pic_firmware.bin")) {
		printf("Found and loaded PIC payload from cart.\n");
	} else if (pic_load_run_file("/int/pic_firmware.bin")) {
		printf("Found and loaded PIC payload from internal flash.\n");
	}


	//Initialize the LCD
	lcd_init(simulated());
	
	int leds_on=read_leds_on();
	MISC_REG(MISC_LED_REG) = leds_on;

	// Basic startup chime.
	SYNTHREG(0xF0) = 0x00000200;
	SYNTHREG(0x40) = 0x00151800;
	SYNTHREG(0x50) = 0x00251E00;
	SYNTHREG(0x60) = 0x00352400;
	SYNTHREG(0x70) = 0x00453000;
    
	//Skip autoexec when user is holding down the designated bypass key
	if(!(MISC_REG(MISC_BTN_REG)&BUTTON_B)) {
		//See if there's an autoexec.elf we can run.
		const char *autoexec;
		if (booted_from_cartridge()) {
			autoexec="/cart/autoexec.elf";
		} else {
			autoexec="/int/autoexec.elf";
		}
		FILE *f=fopen(autoexec, "r");
		if (f!=NULL) {
			fclose(f);
			printf("Found %s. Executing\n", autoexec);
			load_tiles();
			usb_msc_off();
			start_app(autoexec);
			printf("%s done.\n", autoexec);
		} else {
			printf("No %s found; not running\n", autoexec);
		}
	}

	//Initialize USB subsystem
	printf("IPL main function. Booted from %s.\n", booted_from_cartridge()?"cartridge":"internal memory");
	usb_setup_serial_no();
	tusb_init();
	printf("USB inited.\n");

	//Main loop
	while(1) {
		MISC_REG(MISC_LED_REG) = leds_on;
		printf("IPL running.\n");
		char app_name[256]="*na*";
		int flags=0;
		show_main_menu(app_name, &flags);
		if (flags&ITEM_FLAG_BITSTREAM) {
			printf("Booting cart bitstream...\n");
			boot_fpga_bitstream(flags&ITEM_FLAG_ON_CART);
		} else if (flags&ITEM_FLAG_FORMAT) {
			printf("Formatting cart...\n");
			fs_cart_initialize_fat();
		} else {
			printf("IPL: starting app %s\n", app_name);
			usb_msc_off();
			start_app(app_name);
			printf("IPL: App %s returned.\n", app_name);
		}
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

// Invoked on DFU_DETACH request to reboot to the bootloader
void tud_dfu_rt_reboot_to_dfu(void)
{
	volatile uint32_t *psram  = (volatile uint32_t *)(MACH_RAM_START);
	volatile uint32_t *reboot = (volatile uint32_t *)(MISC_OFFSET + MISC_FLASH_SEL_REG);

	// Debug
	printf("REBOOT\n");

	// Set MAGIC value in PSRAM
	psram[0] = 0x46464444;
	psram[1] = 0x21215555;
	cache_flush((void*)&psram[0], (void*)&psram[2]);

	// Reboot
	*reboot = 0xD0F1A500;

	// Wait indefinitely
	while (1);
}

// Invoked when received VENDOR control request
bool tud_vendor_control_request_cb(uint8_t rhport, tusb_control_request_t const * request)
{
  switch (request->bRequest)
  {
    case VENDOR_REQUEST_MICROSOFT:
      if ( request->wIndex == 7 )
      {
        // Get Microsoft OS 2.0 compatible descriptor
        uint16_t total_len;
        memcpy(&total_len, desc_ms_os_20+8, 2);

        return tud_control_xfer(rhport, request, (void*) desc_ms_os_20, total_len);
      }else
      {
        return false;
      }

    default:
      // stall unknown request
      return false;
  }

  return true;
}

// Invoked when DATA Stage of VENDOR's request is complete
bool tud_vendor_control_complete_cb(uint8_t rhport, tusb_control_request_t const * request)
{
  (void) rhport;
  (void) request;

  // nothing to do
  return true;
}
