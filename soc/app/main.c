#include <stdint.h>
#include "xprintf.h"
#include "mach_defines.h"

extern volatile uint32_t UART[];
#define UART_REG(i) UART[(i)/4]
extern volatile uint32_t LED[];
#define LED_REG(i) LED[(i)/4]
extern volatile uint32_t LCD[];
#define LCD_REG(i) LCD[(i)/4]

void uart_putc(unsigned char c) {
	UART_REG(UART_DATA_REG)=(uint32_t)c;
}

void app_main() {
	xdev_out(uart_putc);
	xprintf("Hello world!\n");
	LCD_REG(LCD_CONTROL_REG)=1; //enable bl, un-reset, enable cs
	xprintf("Main power turn ON!\n");
	lcd_init();
	xprintf("Done!\n");
}
