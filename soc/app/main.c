#include <stdint.h>
#include <stdlib.h>
#include "gloss/mach_defines.h"
#include "gloss/uart.h"
#include <stdio.h>
#include <lcd.h>
#include "ugui.h"

extern volatile uint32_t UART[];
#define UART_REG(i) UART[(i)/4]
extern volatile uint32_t LED[];
#define LED_REG(i) LED[(i)/4]
extern volatile uint32_t LCD[];
#define LCD_REG(i) LCD[(i)/4]

uint32_t *lcdfb;
UG_GUI ugui;

static void lcd_pset(UG_S16 x, UG_S16 y, UG_COLOR c) {
	if (lcdfb==NULL) return;
	if (x<0 || x>480) return;
	if (y<0 || y>320) return;
	lcdfb[x+y*480]=c;
}

void main() {
	LED_REG(0)=0xff;
	LCD_REG(LCD_CONTROL_REG)=1; //enable bl, un-reset, enable cs
	lcd_init();
	lcdfb=calloc(320*480,4);
	UG_Init(&ugui, lcd_pset, 480, 320);
	UG_FontSelect(&FONT_12X16);
	UG_SetForecolor(C_WHITE);
	UG_PutString(0, 0, "Hello world!");
	lcd_write_fb(lcdfb);
	//loop
	while(1) {
		printf("%x\n", uart_getchar());
	}
}
