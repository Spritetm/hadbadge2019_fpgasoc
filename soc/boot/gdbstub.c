// Copyright 2015-2016 Espressif Systems (Shanghai) PTE LTD
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/******************************************************************************
 * Description: A stub to make the ESP32 debuggable by GDB over the serial 
 * port, at least enough to do a backtrace on panic. This gdbstub is read-only:
 * it allows inspecting the ESP32 state 
 *******************************************************************************/

#include <stdint.h>

extern volatile uint32_t UART[];
#define UARTREG(i) UART[i/4]
#define UART_DATA_REG 0

extern volatile uint32_t LED[];


//Length of buffer used to reserve GDB commands. Has to be at least able to fit the G command, which
//implies a minimum size of about 264 bytes.
#define PBUFLEN 512

static unsigned char cmd[PBUFLEN];		//GDB command input buffer
static char chsum;						//Running checksum of the output packet


//Receive a char from the uart. Uses polling and feeds the watchdog.
static int gdbRecvChar() {
	uint32_t r;
	do {
		r=UARTREG(UART_DATA_REG);
	} while (r&0xffffff00);
	return r;
}

//Send a char to the uart.
static void gdbSendChar(char c) {
	UARTREG(UART_DATA_REG)=c;
}

//Send the start of a packet; reset checksum calculation.
static void gdbPacketStart() {
	chsum=0;
	gdbSendChar('$');
}

//Send a char as part of a packet
static void gdbPacketChar(char c) {
	if (c=='#' || c=='$' || c=='}' || c=='*') {
		gdbSendChar('}');
		gdbSendChar(c^0x20);
		chsum+=(c^0x20)+'}';
	} else {
		gdbSendChar(c);
		chsum+=c;
	}
}

//Send a string as part of a packet
static void gdbPacketStr(const char *c) {
	while (*c!=0) {
		gdbPacketChar(*c);
		c++;
	}
}

//Send a hex val as part of a packet. 'bits'/4 dictates the number of hex chars sent.
static void gdbPacketHex(int val, int bits) {
	const char *hexChars="0123456789abcdef";
	int i;
	for (i=bits; i>0; i-=4) {
		gdbPacketChar(hexChars[(val>>(i-4))&0xf]);
	}
}

//Finish sending a packet.
static void gdbPacketEnd() {
	gdbSendChar('#');
	gdbPacketHex(chsum, 8);
}

//Error states used by the routines that grab stuff from the incoming gdb packet
#define ST_ENDPACKET -1
#define ST_ERR -2
#define ST_OK -3
#define ST_CONT -4

//Grab a hex value from the gdb packet. Ptr will get positioned on the end
//of the hex string, as far as the routine has read into it. Bits/4 indicates
//the max amount of hex chars it gobbles up. Bits can be -1 to eat up as much
//hex chars as possible.
static long gdbGetHexVal(unsigned char **ptr, int bits) {
	int i;
	int no;
	unsigned int v=0;
	char c;
	no=bits/4;
	if (bits==-1) no=64;
	for (i=0; i<no; i++) {
		c=**ptr;
		(*ptr)++;
		if (c>='0' && c<='9') {
			v<<=4;
			v|=(c-'0');
		} else if (c>='A' && c<='F') {
			v<<=4;
			v|=(c-'A')+10;
		} else if (c>='a' && c<='f') {
			v<<=4;
			v|=(c-'a')+10;
		} else if (c=='#') {
			if (bits==-1) {
				(*ptr)--;
				return v;
			}
			return ST_ENDPACKET;
		} else {
			if (bits==-1) {
				(*ptr)--;
				return v;
			}
			return ST_ERR;
		}
	}
	return v;
}

//Swap an int into the form gdb wants it
static int iswap(int i) {
	int r;
	r=((i>>24)&0xff);
	r|=((i>>16)&0xff)<<8;
	r|=((i>>8)&0xff)<<16;
	r|=((i>>0)&0xff)<<24;
	return r;
}

//Read a byte from memory.
static unsigned char readbyte(unsigned int p) {
	uint8_t *i=(uint8_t*)(p);
	return *i;
}

//Write a byte to memory.
static void writeByte(unsigned int p, unsigned char c) {
	uint8_t *i=(uint8_t*)(p);
	*i=c;
}

//Set a watchpoint
static int gdbstub_set_hw_watchpoint(int loc, int mask, int access) {
	//stubbed
	return 0;
}

//Delete a watchpoint
static int gdbstub_del_hw_watchpoint(int loc) {
	//stubbed
	return 0;
}

//Set a breakpoint
static int gdbstub_set_hw_breakpoint(int no, int pc) {
	//stubbed
	return 0;
}

//Delete a breakpoint
static int gdbstub_del_hw_breakpoint(int no) {
	//stubbed
	return 0;
}

//strncmp local version
static int stub_strncmp(char *str1, char *str2, int len) {
	int a, b;
	do {
		a=*str1++;
		b=*str2++;
		if (a>=97 && a<=122) a-=(97-65);
		if (b>=97 && b<=122) b-=(97-65);
		if (a==0 && b==0) return 0;
	} while (a==b);
	return (a>b)?1:-1;
}

//Register file in the format gdb expects it.
//ref riscv-gdb/gdb/features/riscv/*
typedef struct {
	uint32_t x[32]; //note: pc is stored in x[0]. x0 always reads 0 in hw, so we don't need to save that.
} GdbRegFile;


//Send the reason execution is stopped to GDB.
static void sendReason(GdbRegFile *gdbRegFile) {
	//exception-to-signal mapping
//	char exceptionSignal[]={4,31,11,11,2,6,8,0,6,7,0,0,7,7,7,7};
//	int i=0;
	gdbPacketStart();
	gdbPacketChar('T');
	//ToDo: expstate on riscv
//	i=gdbRegFile.expstate&0x7f;
//	if (i<sizeof(exceptionSignal)) {
//		gdbPacketHex(exceptionSignal[i], 8); 
//	} else {
		gdbPacketHex(0, 8);
//	}
	gdbPacketEnd();
}

//Handle a command as received from GDB.
static int gdbHandleCommand(unsigned char *cmd, int len, GdbRegFile *frame) {
	//Handle a command
	int i, j, k;
	unsigned char *data=cmd+1;
	if (cmd[0]=='g') {		//send all registers to gdb
		gdbPacketStart();
		gdbPacketHex(0, 32); //x0 aka zero; can be ignored
		for (int i=1; i<32; i++) gdbPacketHex(iswap(frame->x[i]), 32); //reg 1-31
		gdbPacketHex(iswap(frame->x[0]), 32); //pc - stored at pos 0
		gdbPacketEnd();
	} else if (cmd[0]=='G') {	//receive content for all registers from gdb
		for (int i=0; i<32; i++) frame->x[i]=iswap(gdbGetHexVal(&data, 32));;
		frame->x[0]=iswap(gdbGetHexVal(&data, 32));
		gdbPacketStart();
		gdbPacketStr("OK");
		gdbPacketEnd();
	} else if (cmd[0]=='m') {	//read memory to gdb
		i=gdbGetHexVal(&data, -1);
		data++;
		j=gdbGetHexVal(&data, -1);
		gdbPacketStart();
		for (k=0; k<j; k++) {
			gdbPacketHex(readbyte(i++), 8);
		}
		gdbPacketEnd();
	} else if (cmd[0]=='M') {	//write memory from gdb
		i=gdbGetHexVal(&data, -1); //addr
		data++; //skip ,
		j=gdbGetHexVal(&data, -1); //length
		data++; //skip :
		for (k=0; k<j; k++) {
			writeByte(i, gdbGetHexVal(&data, 8));
			i++;
		}
		gdbPacketStart();
		gdbPacketStr("OK");
		gdbPacketEnd();
	} else if (cmd[0]=='x') {	//binary write memory from gdb
		i=gdbGetHexVal(&data, -1); //addr
		data++; //skip ,
		j=gdbGetHexVal(&data, -1); //length
		data++; //skip :
		for (k=0; k<j; k++) {
			writeByte(i, data[k]);
			i++;
		}
		gdbPacketStart();
		gdbPacketStr("OK");
		gdbPacketEnd();
	} else if (cmd[0]=='?') {	//Reply with stop reason
		sendReason(frame);
	} else if (stub_strncmp((char*)cmd, "vCont;c", 7)==0 || cmd[0]=='c') {	//continue execution
		gdbPacketStart();
		gdbPacketStr("OK");
		gdbPacketEnd();
		return ST_CONT;
	} else if (stub_strncmp((char*)cmd, "vCont;s", 7)==0 || cmd[0]=='s') {	//single-step instruction
//		gdbstub_savedRegs.ps=(gdbstub_savedRegs.ps & ~0xf)|(XCHAL_DEBUGLEVEL-1);
//		gdbstub_icount_ena_single_step();
		return ST_CONT;
	} else if (stub_strncmp((char*)cmd, "vCont?", 6)==0) {	//query
		gdbPacketStart();
		gdbPacketStr("vCont;c;s");
		gdbPacketEnd();
	} else if (cmd[0]=='q') {	//Extended query
		if (stub_strncmp((char*)&cmd[1], "Supported", 9)==0) { //Capabilities query
			gdbPacketStart();
			gdbPacketStr("swbreak+;hwbreak+;PacketSize=255;vContSupported+");
			gdbPacketEnd();
		} else {
			//We don't support other queries.
			gdbPacketStart();
			gdbPacketEnd();
			return ST_ERR;
		}
	} else if (cmd[0]=='Z') {	//Set hardware break/watchpoint.
		data+=2; //skip 'x,'
		i=gdbGetHexVal(&data, -1);
		data++; //skip ','
		j=gdbGetHexVal(&data, -1);
		gdbPacketStart();
		if (cmd[1]='1') { //Set breakpoint
			if (gdbstub_set_hw_breakpoint(i, j)) {
				gdbPacketStr("OK");
			} else {
				gdbPacketStr("E01");
			}
		} else if (cmd[1]=='2' || cmd[1]=='3' || cmd[1]=='4') { //Set watchpoint
			int access=0;
			int mask=0;
			if (cmd[1]=='2') access=2; //write
			if (cmd[1]=='3') access=1; //read
			if (cmd[1]=='4') access=3; //access
			if (j==1) mask=0x3F;
			if (j==2) mask=0x3E;
			if (j==4) mask=0x3C;
			if (j==8) mask=0x38;
			if (j==16) mask=0x30;
			if (j==32) mask=0x20;
			if (j==64) mask=0x00;
			if (mask!=0 && gdbstub_set_hw_watchpoint(i,mask, access)) {
				gdbPacketStr("OK");
			} else {
				gdbPacketStr("E01");
			}
		}
		gdbPacketEnd();
	} else if (cmd[0]=='z') {	//Clear hardware break/watchpoint
		data+=2; //skip 'x,'
		i=gdbGetHexVal(&data, -1);
		data++; //skip ','
		j=gdbGetHexVal(&data, -1);
		gdbPacketStart();
		if (cmd[1]=='1') {	//hardware breakpoint
			if (gdbstub_del_hw_breakpoint(i)) {
				gdbPacketStr("OK");
			} else {
				gdbPacketStr("E01");
			}
		} else if (cmd[1]=='2' || cmd[1]=='3' || cmd[1]=='4') { //hardware watchpoint
			if (gdbstub_del_hw_watchpoint(i)) {
				gdbPacketStr("OK");
			} else {
				gdbPacketStr("E01");
			}
		}
		gdbPacketEnd();
	} else {
		//We don't recognize or support whatever GDB just sent us.
		gdbPacketStart();
		gdbPacketEnd();
		return ST_ERR;
	}
	return ST_OK;
}


//Lower layer: grab a command packet and check the checksum
//Calls gdbHandleCommand on the packet if the checksum is OK
//Returns ST_OK on success, ST_ERR when checksum fails, a 
//character if it is received instead of the GDB packet
//start char.
static int gdbReadCommand(GdbRegFile *frame) {
	unsigned char c;
	unsigned char chsum=0, rchsum;
	unsigned char sentchs[2];
	int p=0;
	unsigned char *ptr;
	c=gdbRecvChar();
	if (c!='$') return c;
	while(1) {
		c=gdbRecvChar();
		if (c=='#') {	//end of packet, checksum follows
			cmd[p]=0;
			break;
		}
		chsum+=c;
		if (c=='$') {
			//Wut, restart packet?
			chsum=0;
			p=0;
			continue;
		}
		if (c=='}') {		//escape the next char
			c=gdbRecvChar();
			chsum+=c;
			c^=0x20;
		}
		cmd[p++]=c;
		if (p>=PBUFLEN) return ST_ERR;
	}
	//A # has been received. Get and check the received chsum.
	sentchs[0]=gdbRecvChar();
	sentchs[1]=gdbRecvChar();
	ptr=&sentchs[0];
	rchsum=gdbGetHexVal(&ptr, 8);
	if (rchsum!=chsum) {
		gdbSendChar('-');
		return ST_ERR;
	} else {
		gdbSendChar('+');
		return gdbHandleCommand(cmd, p, frame);
	}
}

GdbRegFile *gdb_panic_handler(GdbRegFile *frame, uint32_t reason) {
	sendReason(frame);
	while(gdbReadCommand(frame)!=ST_CONT);
	LED[0]=0x3A;
	return frame;
}

