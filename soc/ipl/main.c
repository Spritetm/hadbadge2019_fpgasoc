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

#define MEMTEST_STATE_WRITE 0
#define MEMTEST_STATE_READ 1
#define MEMTEST_STATE_DONE_OK 2
#define MEMTEST_STATE_DONE_FAIL 3


typedef struct {
	uint32_t *mem;
	int pos;
	int state;
} memtest_t;

#define MEMTEST_RET_CONT 0
#define MEMTEST_RET_OK 1
#define MEMTEST_RET_FAIL 2
#define MEMTEST_SIZE (10*1024*1024)
#define MEMTEST_IT_PER_LOOP 2048

#define SCRAMBLE(p) ((((p)<<16)|(p))^0xaaaaaaaa)

int memtest(memtest_t *t) {
	if (t->mem==NULL) {
		t->pos=0;
		t->state=MEMTEST_STATE_WRITE;
		t->mem=malloc(MEMTEST_SIZE);
		if (t->mem==NULL) return MEMTEST_RET_FAIL;
	}
	if (t->state==MEMTEST_STATE_DONE_OK) return MEMTEST_RET_OK;
	if (t->state==MEMTEST_STATE_DONE_FAIL) return MEMTEST_RET_FAIL;
	int it;
	if (t->state==MEMTEST_STATE_WRITE) {
		for (it=0; it<MEMTEST_IT_PER_LOOP; it++) {
			t->mem[t->pos]=SCRAMBLE(t->pos);
			t->pos+=4;
		}
	} else if (t->state==MEMTEST_STATE_READ) {
		for (it=0; it<MEMTEST_IT_PER_LOOP; it++) {
			if (t->mem[t->pos]!=SCRAMBLE(t->pos)) {
				t->state=MEMTEST_STATE_DONE_FAIL;
				return MEMTEST_RET_FAIL;
			}
			t->pos+=4;
		}
	}
	t->pos+=t->pos/2;  //log inc in test addr
	if (t->pos >= (MEMTEST_SIZE/4)) {
		if (t->state==MEMTEST_STATE_WRITE) {
			t->pos=0;
			t->state=MEMTEST_STATE_READ;
		} else if (t->state==MEMTEST_STATE_READ) {
			t->state=MEMTEST_STATE_DONE_OK;
		}
	}
	return MEMTEST_RET_CONT;
}


const int genio_pair[15][2]={
	{1, 16}, {2, 18}, {4, 20}, {6, 22},
	{8, 24}, {10, 26}, {12, 28}, {14, 30},
	{3, 17}, {5, 19}, {7, 21}, {9, 23},
	{11, 25}, {13, 27}, {15, 29}
};


int geniopin=0;

int test_genio() {
	geniopin++;
	if (geniopin==16) geniopin=0;
	int oe=0, out=0, ex=0;
	for (int i=0; i<15; i++) {
		int a, b;
		if (rand()&1) {
			a=1; b=0;
		} else {
			a=0; b=1;
		}
		oe|=(1<<(genio_pair[i][a]-1));
		if (rand()) {
			out|=(1<<(genio_pair[i][a]-1));
			ex|=(1<<(genio_pair[i][a]-1));
			ex|=(1<<(genio_pair[i][b]-1));
		}
	}
	MISC_REG(MISC_GENIO_OUT_REG)=out;
	MISC_REG(MISC_GENIO_OE_REG)=oe;
	volatile int m;
	for (m=0; m<16; m++) ;
	int rd=MISC_REG(MISC_GENIO_IN_REG);
	if (rd!=ex) {
		printf("OE %08X out %08X in %08X ex %08X dif %08X\n", oe, out, rd, ex, rd^ex);
		return 0;
	} else {
		return 1;
	}
}

uint32_t test_irda() {
	uint8_t r;
	uint32_t res=0;
	UART_REG(UART_IRDA_DIV_REG)=416;
	MISC_REG(MISC_GPEXT_W2S_REG)=(1<<30);
	r=UART_REG(UART_IRDA_DATA_REG);
	UART_REG(UART_IRDA_DATA_REG)=0x55;
	UART_REG(UART_IRDA_DATA_REG)=0xaa;
	r=UART_REG(UART_IRDA_DATA_REG);
	res|=(r<<24);
	UART_REG(UART_IRDA_DATA_REG)=0x5a;
	r=UART_REG(UART_IRDA_DATA_REG);
	res|=(r<<16);
	MISC_REG(MISC_GPEXT_W2C_REG)=(1<<30);
	UART_REG(UART_IRDA_DATA_REG)=0x55;
	UART_REG(UART_IRDA_DATA_REG)=0xaa;
	r=UART_REG(UART_IRDA_DATA_REG);
	res|=(r<<8);
	UART_REG(UART_IRDA_DATA_REG)=0x5a;
	r=UART_REG(UART_IRDA_DATA_REG);
	res|=(r<<0);
	return res;

}

extern int msc_capacity_passed;

void main() {
	syscall_reinit();
	printf("IPL running.\n");
	lcd_init();
	lcdfb=calloc(320*512/2, 1);
	GFX_REG(GFX_FBADDR_REG)=((uint32_t)lcdfb)&0x7FFFFF;
	UG_Init(&ugui, lcd_pset, 480, 320);
	UG_FontSelect(&FONT_12X16);
	UG_SetForecolor(C_WHITE);

	tusb_init();
	printf("USB inited.\n");
	
	fs_init();
	usb_msc_on();
	MISC_REG(MISC_LED_REG)=0xfffff;

	uint32_t irda_res=test_irda();
	int adcdiv=2;
	
	//loop
	int p;
	char buf[200];
	MISC_REG(MISC_ADC_CTL_REG)=MISC_ADC_CTL_DIV(adcdiv)|MISC_ADC_CTL_ENA;
	memtest_t mt={0};
	int adc_avg=32767;
	int btn_ok=0;
	MISC_REG(MISC_GPEXT_W2C_REG)=(1<<30);

//	uint8_t cols[]={0x9A, 0xc0, 0xf0};
	uint8_t cols[]={0x12, 0x40, 0x70};
	for (int y=0; y<320; y++) {
		for (int x=0; x<480; x+=2) {
			lcdfb[(x+y*512)/2]=cols[(x+y)%3];
		}
	}
	UG_SetForecolor(C_WHITE);
	UG_PutString(0, 0, "Hackaday Supercon Badge HW test");
	while(1) {
		p++;

		
		UG_SetForecolor(C_BLUE);
		sprintf(buf, "%d %06X", mt.state, mt.pos);
		UG_PutString(220, 32, buf);

		UG_SetForecolor(C_YELLOW);
		int r=memtest(&mt);
		UG_PutString(8, 32, "RAM");
		if (r==MEMTEST_RET_CONT) {
			UG_SetForecolor(C_YELLOW);
			UG_PutString(160, 32, "...");
		} else if (r==MEMTEST_RET_OK) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 32, "OK!");
		} else  {
			UG_SetForecolor(C_RED);
			UG_PutString(160, 32, "ERROR!");
		}

		UG_SetForecolor(C_YELLOW);
		UG_PutString(8, 48, "USB");
		if (msc_capacity_passed) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 48, "OK!");
		} else  {
			UG_SetForecolor(C_YELLOW);
			UG_PutString(160, 48, "...");
		}

		UG_SetForecolor(C_YELLOW);
		UG_PutString(8, 64, "USB VBUS");
		if (MISC_REG(MISC_GPEXT_IN_REG)&(1<<31)) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 64, "OK!");
		} else  {
			UG_SetForecolor(C_YELLOW);
			UG_PutString(160, 64, "...");
		}

		UG_SetForecolor(C_BLUE);
		sprintf(buf, "%08X", irda_res);
		UG_PutString(220, 80, buf);
		UG_SetForecolor(C_YELLOW);
		UG_PutString(8, 80, "IRDA");
		if ((irda_res&0xffff0000)==0xffff0000 && (irda_res&0xffff)!=0xffff) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 80, "OK!");
		} else  {
			UG_SetForecolor(C_RED);
			UG_PutString(160, 80, "ERR");
		}

		r=MISC_REG(MISC_ADC_VAL_REG);
		adc_avg=(adc_avg*15+r)/16;
		UG_SetForecolor(C_YELLOW);
		UG_PutString(8, 96, "ADC");
		if (adc_avg>5 && adc_avg<65530) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 96, "OK!");
		} else  {
			UG_SetForecolor(C_RED);
			UG_PutString(160, 96, "ERROR!");
		}

		int btn=MISC_REG(MISC_BTN_REG);
		for (int i=0; i<8; i++) {
			if (btn == (1<<i)) btn_ok|=btn;
		}
		UG_SetForecolor(C_YELLOW);
		UG_PutString(8, 112, "BUTTONS");
		if (btn_ok==0xff) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 112, "OK!");
		} else  {
			UG_SetForecolor(C_YELLOW);
			UG_PutString(160, 112, "...");
		}
		for (int i=0; i<8; i++) {
			if (btn&(1<<i)) {
				UG_SetForecolor(C_YELLOW);
				sprintf(buf, "%d!", i+1);
			} else if (btn_ok&(1<<i)) {
				UG_SetForecolor(C_GREEN);
				sprintf(buf, "%dV", i+1);
			} else {
				UG_SetForecolor(C_RED);
				sprintf(buf, "%d.", i+1);
			}
			UG_PutString(160+32*i, 128, buf);
		}


		uint64_t id_int=flash_get_uid(FLASH_SEL_INT);
		uint64_t id_ext=flash_get_uid(FLASH_SEL_CART);
		UG_SetForecolor(C_BLUE);
		sprintf(buf, "i: %016llX", id_int);
		UG_PutString(220, 144, buf);
		sprintf(buf, "e: %016llX", id_ext);
		UG_PutString(220, 160, buf);
		UG_SetForecolor(C_YELLOW);
		UG_PutString(8, 144, "FLASH");
		if (id_int==0 || ~id_int==0 || id_ext==0 || ~id_ext==0 || id_int==id_ext) {
			UG_SetForecolor(C_RED);
			UG_PutString(160, 144, "ERR");
		} else  {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 144, "OK!");
		}

		UG_SetForecolor(C_YELLOW);
		UG_PutString(8, 176, "CART IO");
		if (test_genio()) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 176, "OK!");
		} else  {
			UG_SetForecolor(C_RED);
			UG_PutString(160, 176, "ERR");
		}


		cache_flush(lcdfb, lcdfb+320*480/2);
		for (int i=0; i<500; i++) {
			usb_poll();
			tud_task();
		}
	}
}
