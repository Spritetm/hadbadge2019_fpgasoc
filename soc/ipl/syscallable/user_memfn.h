#include <stddef.h>

typedef void* (malloc_fn_t)(size_t size);
typedef void* (realloc_fn_t)(void *ptr, size_t new_size);
typedef void (free_fn_t)(void *ptr);

//note: only usable in IPL; symbols won't resolve in app.
extern malloc_fn_t *user_memfn_malloc;
extern realloc_fn_t *user_memfn_realloc;
extern free_fn_t *user_memfn_free;

void user_memfn_set(malloc_fn_t malloc_fn, realloc_fn_t realloc_fn, free_fn_t free_fn);
