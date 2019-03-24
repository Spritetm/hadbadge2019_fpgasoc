#include <stdint.h>
#include "xprintf.h"
#include "mach_defines.h"

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

//todo: calibrate delay, or use a timer like a civilized person.
static void Delay(int n) {
//	xprintf("Dly %d\n", n);
	for (int i=0; i<n; i++) {
		for (volatile int t=0; t<(1<<11); t++);
	}
}

void lcd_init() {
	WriteComm(0x11);
	Delay(130);	
	WriteComm(0x13);
	Delay(120);

	WriteComm(0x00D0);
	WriteData(0x0007);//P115
	WriteData(0x0045);//P115
	WriteData(0x0018);//P115-116
	WriteComm( 0x00D1);
	WriteData( 0x0003);
	WriteData( 0x0010);//VCM
	WriteData( 0x000f);//VDV

// 	WriteComm(0x00D1);//VCOM Control，有3个参数，P117
// 	WriteData(0x0000);//P118
// 	WriteData(0x0001);//P117
// 	WriteData(0x001F);//P117-118

	WriteComm(0x00D2);//Power Setting for Normal Mode，有2个参数，P119
	WriteData(0x0001);//P118
	WriteData(0x0011);//P119

	WriteComm(0x00C0);//Panel Driving Setting，有6个参数，P102，主要设置行扫描
	WriteData(0x0000);//P102-103 GS=0
	WriteData(0x003B);//P103，(0x3B + 1) * 8 = 480行
	WriteData(0x0000);//P103
	WriteData(0x0000);//P103
	WriteData(0x0011);//P103-104
	WriteData(0x0000);//P103-104

	WriteComm(0x00C1);//Didsplay Timing Setting for Normal Mode，有3个参数，P106
	WriteData(0x0010);//P106
	WriteData(0x000B);//P106
	WriteData(0x0088);//P107

	WriteComm(0x00C5);//Frame Rate and Inversion control，有1个参数，P112
	WriteData(0x0000);//P112

	WriteComm(0x00C8);//Gamma Setting，有12个参数，P114
	WriteData(0x0000);//P114
	WriteData(0x0014);//P114
	WriteData(0x0033);//P114
	WriteData(0x0010);//P114
	WriteData(0x0000);//P114
	WriteData(0x0016);//P114
	WriteData(0x0044);//P114
	WriteData(0x0036);//P114
	WriteData(0x0077);//P114
	WriteData(0x0000);//P114
	WriteData(0x000F);//P114
	WriteData(0x0000);//P114
	 

	WriteComm(0x36); //Set_address_mode
	WriteData(0x48); //
  
	WriteComm(0x3A);//Set Pixel Format
	WriteData(0x66);//18bpp all-around

	Delay(120);
	WriteComm(0x29);

	Delay(10);
	WriteComm(0x21);

	Delay(10);
	WriteComm(0x36); //Set_address_mode
	WriteData(0xE0); //


	WriteComm(0x2B);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x01);
	WriteData(0x3F);

	WriteComm(0x2A);
	WriteData(0x00);
	WriteData(0x00);
	WriteData(0x01);
	WriteData(0xDF);

	WriteComm(0x2c); //Write mem start
	for (int y=0; y<320; y++) {
		for (int x=0; x<480; x++) {
			WriteData((y&0x3f)+(x<<12)+(((x+y)/4)<<6));
		}
	}
}
