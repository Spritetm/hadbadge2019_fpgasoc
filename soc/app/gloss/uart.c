#include <stdint.h>
#include "mach_defines.h"
#include "uart.h"

extern volatile uint32_t UART[];
#define UARTREG(i) UART[i/4]

void uart_putchar(char c) {
//	while (!(UARTREG(UART_FLAG_REG)&UART_FLAG_TXDONE)) ;
	UARTREG(UART_DATA_REG)=c;
}

void uart_write(const char *buf, int len) {
	while(len) {
		uart_putchar(*buf++);
		len--;
	}
}

int uart_getchar() {
	return UARTREG(UART_DATA_REG);
}