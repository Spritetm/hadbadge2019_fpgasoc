/*
Sometimes, IPL functions are called from app context, and these functions want to allocate memory.
Because we have separate heaps for the app and the IPL, they would normally allocate on the (limited!)
IPL memory and perhaps run out of RAM. Instead, we can change them to use these functions instead; as
the app will call user_memfn_set with their local malloc/free/... on startup, if they use these
functions they will allocate on the apps heap.
*/
#include <stdlib.h>
#include "user_memfn.h"

malloc_fn_t *user_memfn_malloc;
realloc_fn_t *user_memfn_realloc;
free_fn_t *user_memfn_free;


void user_memfn_set(malloc_fn_t malloc_fn, realloc_fn_t realloc_fn, free_fn_t free_fn) {
	user_memfn_malloc=malloc_fn;
	user_memfn_realloc=realloc_fn;
	user_memfn_free=free_fn;
	printf("Redirected malloc/realloc/free: %p %p %p\n", malloc_fn, realloc_fn, free_fn);
}
