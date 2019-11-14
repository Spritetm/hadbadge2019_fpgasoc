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
#include <stdio.h>
#include "gloss/mach_defines.h"
#include "badgetime.h"

extern volatile uint32_t LCD[];
#define LCD_REG(i) LCD[(i)/4]

static void WriteComm(uint16_t c) {
//	xprintf("Cmd %x\n", c);
	LCD_REG(LCD_COMMAND_REG)=c;
}
static void WriteData(uint32_t c) {
//	xprintf("Dat %x\n", c);
	LCD_REG(LCD_DATA_REG)=c;
}

void lcd_init(int nowait) {
	LCD_REG(LCD_CONTROL_REG)=1; //enable bl, un-reset, enable cs
	if (!nowait) delay(10);
	WriteComm(0xF0);
	WriteData(0x5A);
	WriteData(0x5A);
	
	WriteComm(0xF1);
	WriteData(0x5A);
	WriteData(0x5A);
	
	WriteComm(0xF2);
	WriteData(0x3B);
	WriteData(0x40);
	WriteData(0x03);
	WriteData(0x04);
	WriteData(0x02);
	WriteData(0x08);
	WriteData(0x08);
	WriteData(0x00);
	WriteData(0x08);
	WriteData(0x08);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x40);
	WriteData(0x08);
	WriteData(0x08);
	WriteData(0x08);
	WriteData(0x08);
	
	
	WriteComm(0xF4);
	WriteData(0x08);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x6d);
	WriteData(0x03);
	WriteData(0x00);
	WriteData(0x70);
	WriteData(0x03);
	
	
	WriteComm(0xF5);
	WriteData(0x00);
	WriteData(0x54);//Set VCOMH
	WriteData(0x73);//Set VCOM Amplitude
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x04);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x04);
	WriteData(0x00);
	WriteData(0x53);
	WriteData(0x71);
	
	WriteComm(0xF6);
	WriteData(0x04);
	WriteData(0x00);
	WriteData(0x08);
	WriteData(0x03);
	WriteData(0x01);
	WriteData(0x00);
	WriteData(0x01);
	WriteData(0x00);
	
	WriteComm(0xF7);
	WriteData(0x48);
	WriteData(0x80);
	WriteData(0x10);
	WriteData(0x02);
	WriteData(0x00);
	
	WriteComm(0xF8);
	WriteData(0x11);
	WriteData(0x00);
	
	WriteComm(0xF9); //Gamma Selection
	WriteData(0x27);
	
	WriteComm(0xFA); //Positive Gamma Control
	WriteData(0x0B);
	WriteData(0x0B);
	WriteData(0x0F);
	WriteData(0x26);
	WriteData(0x2A);
	WriteData(0x30);
	WriteData(0x33);
	WriteData(0x12);
	WriteData(0x1F);
	WriteData(0x25);
	WriteData(0x31);
	WriteData(0x30);
	WriteData(0x24);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x01);
	
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x01);
	WriteData(0x3F);
	
	WriteComm(0x2a);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x01);
	WriteData(0xDF);
	
	WriteComm(0x2b);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x01);
	WriteData(0x3F);
	
	WriteComm(0x36);//Memory Data Access Control
	WriteData(0xA0);
	
	WriteComm(0x3A);//SET 16bit Color
	WriteData(0x55); //55=16bit, 66=18bit, 77=24bit
	//Note: The display is wired for 18-bit mode wrt data lines, however, the IM lines are
	//wired in such a way *this* controller only accepts 16-bit writes.
	
	WriteComm(0x11); 
	if (!nowait) delay(120);
	
	WriteComm(0x29);//Display on

	//Connect to FB mem
	WriteComm(0x2c); //Write mem start
	LCD_REG(LCD_CONTROL_REG)=1|LCD_CONTROL_FBENA|LCD_CONTROL_FBSTART; //start automatically sending framebuffer
}



