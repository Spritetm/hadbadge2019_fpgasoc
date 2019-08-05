#pragma once

void uart_putchar(char c);
void uart_write(const char *buf, int len);
int uart_getchar();