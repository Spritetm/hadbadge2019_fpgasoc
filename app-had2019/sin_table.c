// sin_table.c

#include "sin_table.h"
#include "math.h"

#define SIN_TABLE_SIZE  512
float sin_vals[SIN_TABLE_SIZE]; // from 0 to 2*pi

void init_sin_table(void) {
	for (int i = 0; i < SIN_TABLE_SIZE; ++i) {
		sin_vals[i] = sinf(i * 2 * PI / SIN_TABLE_SIZE);
	}
}

float table_sin(float x) {
	int index = (int)(x / (2 * PI) * SIN_TABLE_SIZE) % SIN_TABLE_SIZE;
	return sin_vals[index];
}
