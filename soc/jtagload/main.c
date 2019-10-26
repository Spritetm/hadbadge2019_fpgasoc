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
#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <byteswap.h>

int main(int argc, char **argv) {
	printf("HDR	0;\nHIR	0;\nTDR	0;\nTIR	0;\nENDDR	IDLE;\nENDIR	IDLE;\n");
	printf("STATE	IDLE;\n");
	printf("SIR 8 TDI (38);\n");
//	printf("SDR 32 TDI (407E0000);\n");
//	printf("SDR 32 TDI (10000000);\n");
	printf("SDR 32 TDI (40002000);\n");
	printf("SIR 8 TDI (32);\n");
	uint32_t v;
	while (fread(&v, 1, 4, stdin)>0) {
		printf("SDR 32 TDI (%X);\n", v);
	}
	printf("SIR 8 TDI (38);\n");
	printf("SDR 32 TDI (40000000);\n");
	printf("SIR 8 TDI (32);\n");
	printf("SDR 32 TDI (%X);\n", 0xdeadbeef);
	printf("SDR 32 TDI (%X);\n", 0xdeadbeef);
}
