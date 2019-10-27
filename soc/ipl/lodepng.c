#include "user_memfn.h"

#define LODEPNG_NO_COMPILE_ALLOCATORS 1

static void* lodepng_malloc(size_t size) {
	void* p=user_memfn_malloc(size);
	return p;
}

static void* lodepng_realloc(void* ptr, size_t new_size) {
	return user_memfn_realloc(ptr, new_size);
}

static void lodepng_free(void* ptr) {
	user_memfn_free(ptr);
}

#include "lodepng/lodepng.cpp"
