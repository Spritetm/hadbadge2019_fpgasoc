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

int test_sao() {
	int v=rand()&0x3F;
	int r;
	volatile int w;
	if (rand()&1) {
		MISC_REG(MISC_GPEXT_OE_REG)=0xFF00;
		MISC_REG(MISC_GPEXT_OUT_REG)=v<<8;
		for (w=0; w<10; w++) ;
		r=MISC_REG(MISC_GPEXT_IN_REG)&0x3F;
	} else {
		MISC_REG(MISC_GPEXT_OE_REG)=0xFF;
		MISC_REG(MISC_GPEXT_OUT_REG)=v;
		for (w=0; w<10; w++) ;
		r=(MISC_REG(MISC_GPEXT_IN_REG)>>8)&0x3f;
	}
	if (r!=v) printf("SAO: %02x %02x\n", r, v);
	return r==v;
}

int test_pmod() {
	int v=rand()&0xF;
	int r;
	volatile int w;
	if (rand()&1) {
		MISC_REG(MISC_GPEXT_OE_REG)=0xF0000;
		MISC_REG(MISC_GPEXT_OUT_REG)=v<<16;
		for (w=0; w<10; w++) ;
		r=(MISC_REG(MISC_GPEXT_IN_REG)>>20)&0xf;
	} else {
		MISC_REG(MISC_GPEXT_OE_REG)=0xF00000;
		MISC_REG(MISC_GPEXT_OUT_REG)=v<<20;
		for (w=0; w<10; w++) ;
		r=(MISC_REG(MISC_GPEXT_IN_REG)>>16)&0xf;
	}
	if (r!=v) printf("PMOD: %x %x\n", r, v);
	return r==v;
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

void boot_cart() {
	MISC_REG(MISC_FLASH_SEL_REG)=MISC_FLASH_SEL_CARTFLASH;
	volatile int w;
	for (w=0; w<16; w++) ;
	MISC_REG(MISC_FLASH_SEL_REG)=MISC_FLASH_SEL_CARTFLASH|MISC_FLASH_SEL_FPGARELOAD_MAGIC;
}

#define  TEST_THR 5

int check_test(int res, int *ctr) {
	if (*ctr<0) {
		if (res) *ctr=TEST_THR; else *ctr=0;
	} else if (res) {
		(*ctr)++;
	} else {
		(*ctr)=0;
	}
	return ((*ctr)>=TEST_THR);
}

extern int msc_capacity_passed;
void usb_poll();

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
	char buf[400];
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
	
	uint8_t sig[8];
	uint8_t sig_chk[8]="FLASHCAR";
	flash_read(FLASH_SEL_CART, 0x17f000, sig, 8);
	for (int i=0; i<32; i++) printf("%02X ", sig[i]);
	printf("\n");
	if (memcmp(sig, sig_chk, 8)==0) {
		boot_cart();
	}
	//Evil compensation for delay on ext flash lines...
	for (int i=0; i<8; i++) sig_chk[i]=sig_chk[i]>>1;
	if (memcmp(sig, sig_chk, 8)==0) {
		boot_cart();
	}


	int allokpossible=1;
	UG_SetForecolor(C_WHITE);
	UG_PutString(0, 0, "Hackaday Supercon Badge HW test");
	UG_SetForecolor(C_YELLOW);
	UG_PutString(8, 32, "RAM");
	UG_SetForecolor(C_YELLOW);
	UG_PutString(8, 48, "USB");
	UG_SetForecolor(C_YELLOW);
	UG_PutString(8, 64, "USB VBUS");
	UG_SetForecolor(C_YELLOW);
	UG_PutString(8, 96, "ADC");
	UG_SetForecolor(C_YELLOW);
	UG_PutString(8, 112, "BUTTONS");
	UG_SetForecolor(C_YELLOW);
	UG_PutString(8, 128, "FLASH");
	UG_SetForecolor(C_YELLOW);
	UG_PutString(8, 144, "CART IO");
	UG_SetForecolor(C_YELLOW);
	UG_PutString(8, 160, "J9/J10");
	UG_SetForecolor(C_YELLOW);
	UG_PutString(8, 176, "J11");


	/* IRDA */
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
		allokpossible=0;
	}


	int sao_ok=-1, genio_ok=-1, pmod_ok=-1;
	int lastok=-1;
	while(1) {
		p++;

		int allok=allokpossible;
		UG_SetForecolor(C_BLUE);
		sprintf(buf, "%d %06X", mt.state, mt.pos);
		UG_PutString(220, 32, buf);

		// * RAM *
		int r=memtest(&mt);
		if (r==MEMTEST_RET_CONT) {
			UG_SetForecolor(C_YELLOW);
			UG_PutString(160, 32, "...");
			allok=0;
		} else if (r==MEMTEST_RET_OK) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 32, "OK!");
		} else  {
			UG_SetForecolor(C_RED);
			UG_PutString(160, 32, "ERROR!");
			allok=0;
		}

		// * USB *
		if (msc_capacity_passed) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 48, "OK!");
		} else  {
			UG_SetForecolor(C_YELLOW);
			UG_PutString(160, 48, "...");
			allok=0;
		}

		// * USB VBUS
		if (MISC_REG(MISC_GPEXT_IN_REG)&(1<<31)) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 64, "OK!");
		} else  {
			UG_SetForecolor(C_YELLOW);
			UG_PutString(160, 64, "...");
			allok=0;
		}


		// * ADC *
		r=MISC_REG(MISC_ADC_VAL_REG);
		adc_avg=(adc_avg*15+r)/16;
		if (adc_avg>5 && adc_avg<65530) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 96, "OK!");
		} else  {
			UG_SetForecolor(C_RED);
			UG_PutString(160, 96, "ERROR!");
			allok=0;
		}

		// * BUTTONS *
		int btn=MISC_REG(MISC_BTN_REG);
		for (int i=0; i<8; i++) {
			if (btn == (1<<i)) btn_ok|=btn;
		}
		if (btn_ok==0xff) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 112, "OK!");
		} else  {
			UG_SetForecolor(C_YELLOW);
			UG_PutString(160, 112, "...");
			allok=0;
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
			UG_PutString(220+32*i, 112, buf);
		}

		// * FLASH *
		uint64_t id_int=flash_get_uid(FLASH_SEL_INT);
		uint64_t id_ext=flash_get_uid(FLASH_SEL_CART);
		UG_SetForecolor(C_BLUE);
		sprintf(buf, "i: %016llX", id_int);
		UG_PutString(220, 128, buf);
		sprintf(buf, "e: %016llX", id_ext);
		UG_PutString(220, 144, buf);
		if (id_int==0 || ~id_int==0 || id_ext==0 || ~id_ext==0 || id_int==id_ext) {
			UG_SetForecolor(C_RED);
			UG_PutString(160, 128, "ERR");
			allok=0;
		} else  {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 128, "OK!");
		}

		// * CART IO *
		if (check_test(test_genio(), &genio_ok)) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 144, "OK!");
		} else  {
			UG_SetForecolor(C_RED);
			UG_PutString(160, 144, "ERR");
			allok=0;
		}

		// * J9/J10
		if (check_test(test_sao(), &sao_ok)) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 160, "OK!");
		} else  {
			UG_SetForecolor(C_RED);
			UG_PutString(160, 160, "ERR");
			allok=0;
		}

		// * J11 *
		if (check_test(test_pmod(), &pmod_ok)) {
			UG_SetForecolor(C_GREEN);
			UG_PutString(160, 176, "OK!");
		} else  {
			UG_SetForecolor(C_RED);
			UG_PutString(160, 176, "ERR");
			allok=0;
		}


		if (lastok!=allok) {
			lastok=allok;
			for (int y=200; y<300; y++) {
				for (int x=50; x<150; x+=2) {
					lcdfb[(x+y*512)/2]=cols[(x+y)%3];
				}
			}
			if (allok) {
				UG_SetForecolor(C_GREEN);
				UG_FillCircle(100, 250, 48, C_GREEN);
				UG_PutString(160, 242, " PASS! ");
			} else {
				UG_SetForecolor(C_RED);
				UG_PutString(160, 242, "NO PASS");
				for (int x=0; x<20; x++) {
					UG_DrawLine(50+x, 200, 130+x, 299, C_RED);
					UG_DrawLine(130+x, 200, 50+x, 299, C_RED);
				}
			}
		}

		cache_flush(lcdfb, lcdfb+320*480/2);
		for (int i=0; i<500; i++) {
			usb_poll();
			tud_task();
		}
	}
}
