#include <stdio.h>
#include <stdlib.h>
#include "my_basic.h"
#include "extensions.h"

uint8_t *load_file(const char *filename) {
	FILE *f=fopen(filename, "r");
	fseek(f, 0, SEEK_END);
	uint32_t size=ftell(f);
	fseek(f, 0, SEEK_SET);
	uint8_t *ret=malloc(size);
	if (!ret) return NULL;
	fread(ret, size, 1, f);
	fclose(f);
	return ret;
}


static void _on_error(struct mb_interpreter_t* s, mb_error_e e, const char* m, const char* f, int p, unsigned short row, unsigned short col, int abort_code) {
	mb_unrefvar(s);
	mb_unrefvar(p);

	if(e != SE_NO_ERR) {
		if(f) {
			if(e == SE_RN_WRONG_FUNCTION_REACHED) {
				printf( "Error:\n    Ln %d, Col %d in Func: %s\n    Code %d, Abort Code %d\n    Message: %s.\n",
					row, col, f, e, abort_code, m);
			} else {
				printf("Error:\n    Ln %d, Col %d in File: %s\n    Code %d, Abort Code %d\n    Message: %s.\n",
					row, col, f, e, e == SE_EA_EXTENDED_ABORT ? abort_code - MB_EXTENDED_ABORT : abort_code, m);
			}
		} else {
			printf("Error:\n    Ln %d, Col %d\n    Code %d, Abort Code %d\n    Message: %s.\n",
				row, col, e, e == SE_EA_EXTENDED_ABORT ? abort_code - MB_EXTENDED_ABORT : abort_code, m );
		}
	}
}

static int _on_stepped(struct mb_interpreter_t* s, void** l, const char* f, int p, unsigned short row, unsigned short col) {
	mb_unrefvar(s);
	mb_unrefvar(l);
	mb_unrefvar(f);
	mb_unrefvar(p);
//	mb_unrefvar(row);
//	mb_unrefvar(col);
	printf("trace: r %d c %d\n", row, col);

	return MB_FUNC_OK;
}


int main(int argc, char **argv) {
	uint8_t *basfile=load_file("program.bas");
	struct mb_interpreter_t* bas = NULL;
	mb_init();
	mb_open(&bas);
	mybasicext_install(bas);
	mb_load_string(bas, basfile, true);
	mb_set_error_handler(bas, _on_error);
//	mb_debug_set_stepped_handler(bas, _on_stepped);
	mb_run(bas, true);
	mb_close(&bas);
	mb_dispose();
	printf("Basic program ended.\n");
//	do_test();
	while(1);
}
