#include <stdint.h>
#include "xprintf.h"
#include "mach_defines.h"

extern volatile uint32_t UART[];
#define UART_REG(i) UART[(i)/4]
extern volatile uint32_t LED[];
#define LED_REG(i) LED[(i)/4]
extern volatile uint32_t LCD[];
#define LCD_REG(i) LCD[(i)/4]

//uart is initialized in bootloader already
void uart_putc(unsigned char c) {
	UART_REG(UART_DATA_REG)=(uint32_t)c;
}

uint32_t lcdfb[480*320];

void app_main() {
	LED_REG(0)=0xff;
	xdev_out(uart_putc);
	xprintf("Hello world!\n");
	xprintf("SoC ver reg: %x\n", LCD_REG(0));
	LCD_REG(LCD_CONTROL_REG)=1; //enable bl, un-reset, enable cs
	xprintf("Main power turn ON!\n");
	lcd_init();
	xprintf("Done!\n");
}
