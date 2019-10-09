#include <stdio.h>
#include <stdlib.h>
#include "uart.h"

extern int main(int argc, char **argv);

void cpu_start() {
	main(0, NULL);
}

void exited_to_ipl(int errorcode) {
	printf("App exited with error code %d\n", errorcode);
	main(0, NULL);
}