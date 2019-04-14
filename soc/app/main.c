#include <stdint.h>
#include "gloss/mach_defines.h"
#include "gloss/uart.h"
#include <stdio.h>
#include <lcd.h>

extern volatile uint32_t UART[];
#define UART_REG(i) UART[(i)/4]
extern volatile uint32_t LED[];
#define LED_REG(i) LED[(i)/4]
extern volatile uint32_t LCD[];
#define LCD_REG(i) LCD[(i)/4]

//uint32_t lcdfb[480*320];

void main() {
	LED_REG(0)=0xff;
	printf("Hello world!\n");
	LED_REG(0)=0x5;
	LCD_REG(LCD_CONTROL_REG)=1; //enable bl, un-reset, enable cs
//	lcd_init();
	printf("SoC ver reg: %x\n", LCD_REG(0));
	printf("Done!\n");
	//Crash test
	while(1) {
		printf("%x\n", uart_getchar());
	}
}
