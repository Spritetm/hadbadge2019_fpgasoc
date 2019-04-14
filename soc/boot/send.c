#include <sys/types.h>
#include <sys/stat.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <signal.h>
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <sys/ioctl.h>
#include <readline/readline.h>
#include <readline/history.h>

/*
Protocol:
W nhi nlo - write n bytes to 0x200
R nhi nlo - read n bytes from 0x200
G ahi alo - jump to a
*/


#define BAUDRATE B115200
#define _POSIX_SOURCE 1 /* POSIX compliant source */

int serOpen(char *port) {
	int com;
	struct termios oldtio,newtio;
	com = open(port, O_RDWR | O_NOCTTY );
	if (com <0) {
		perror(port); 
		exit(1); 
	}
	tcgetattr(com,&oldtio); // save current port settings
	bzero(&newtio, sizeof(newtio));
	newtio.c_cflag =  (CS8 | CREAD | CLOCAL);
	newtio.c_lflag = 0;
	newtio.c_iflag = IGNPAR;
	newtio.c_oflag = 0;
	cfsetospeed(&newtio,BAUDRATE);
	
	newtio.c_cc[VTIME]    = 0;   // inter-character timer unused 
	newtio.c_cc[VMIN]     = 1;   // blocking read until 1 chars received 
	
	tcflush(com,TCIFLUSH);
	tcsetattr(com,TCSANOW,&newtio);

	return com;
}

void getOk(int com, char okval, int addr) {
	fd_set rfds;
	FD_ZERO(&rfds);
	FD_SET(com, &rfds);
	struct timeval to;
	to.tv_sec=2;
	to.tv_usec=0;
	int n=select(com+1, &rfds, NULL, NULL, &to);
	if (!n) {
		printf("Timeout: No response from dev! (addr = 0x%X)\n", addr);
		exit(1);
	}
	char buf=0;
	read(com, &buf, 1);
	if (buf!=okval) {
		printf("Unknown response %x (%c), expected %x (%c) @ addr 0x%X\n", buf, buf, okval, okval, addr);
		exit(1);
	}
	return;
}


int main(int argc, char** argv) {
	if (argc<3) {
		printf("Usage: %s file.bin /dev/ttyUSBx\n", argv[0]);
		exit(0);
	}
	FILE *f=fopen(argv[1], "r");
	if (f==NULL) {
		perror(argv[1]);
		exit(1);
	}
//	fseek(f, 0x200, SEEK_SET);
	int com=serOpen(argv[2]);
	char buff[1024*8];
	int no_bytes=fread(buff, 1, sizeof(buff), f);
	printf("Sending %d bytes to RAM...\n", no_bytes);
	char cmd[4]={'w', (no_bytes>>16)&0xff, (no_bytes>>8)&0xff, no_bytes&0xff};
	write(com, cmd, 4);
	char *p=buff;
	int n=no_bytes;
	int a=0x200;
	while (n) {
		int m=n;
		if (m>32) m=32;
		write(com, p, m);
		printf("%04X\n", a);
		for (int i=0; i<m; i++) getOk(com, 'B', i+a);
		p+=m;
		n-=m;
		a+=m;
	}
	printf("Getting final write ack...\n");
	getOk(com, 'K', 0);
#if 0
	printf("Doing readback of %d bytes...\n", no_bytes);
	char rcmd[4]={'r', (no_bytes>>16)&0xff, (no_bytes>>8)&0xff, no_bytes&0xff};
	write(com, rcmd, 4);
	for (int i=0; i<no_bytes; i++) {
		printf("%x\n", i);
		getOk(com, buff[i], i);
	}
	getOk(com, 'K', 0);
#endif
	printf("Starting program...\n");
	char goCmd[4]={'g', 0x00, 0x04, 0x00};
	write(com, goCmd, 4);
	getOk(com,'K', 0);
	printf("Running. Dumping serial output, press ctrl-c to exit.\n");
	setvbuf(stdout, NULL, _IONBF, 0);
	while(1) {
		char buf;
		read(com, &buf, 1);
		if (buf>=32 && buf<128) {
			putchar(buf);
		} else {
			printf("<%02X>", buf&0xff);
			if (buf=='\n') printf("\n");
		}
	}
}


