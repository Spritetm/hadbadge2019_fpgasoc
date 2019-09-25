#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

int main(int argc, char **argv) {
	if (argc != 3) {
		fprintf(stderr, "Usage: %s [infile] [outfile]\n", argv[0]);
		exit(1);
	}

	FILE *in = fopen(argv[1], "rb");
	if (!in) {
		perror("unable to open source file");
		exit(2);
	}

	FILE *out = fopen(argv[2], "wb");
	if (!out) {
		perror("unable to open output file");
		exit(3);
	}

	while (1) {
		uint32_t word = 0;
		if (!fread(&word, sizeof(word), 1, in))
			break;
		if (!fprintf(out, "%08X\n", word)) {
			perror("unable to write to file");
			break;
		}
	}
	fclose(in);
	fclose(out);
	return 0;
}
