#include <stdlib.h>
#include "user_memfn.h"

extern int main(int argc, char **argv);

int app_start(int argc, char **argv) {
	user_memfn_set(malloc, realloc, free);
	return main(argc, argv);
}
