#include <stdio.h>
#include <stdlib.h>
#include "uart.h"

extern int main(int argc, char **argv);

void cpu_start() {
//	printf("CPU started!\n");
	main(0, NULL);
//	printf("Main exited, all done.\n");
//	abort();
}