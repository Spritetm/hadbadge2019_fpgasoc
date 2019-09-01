#include "../fatfs/source/ff.h"
void syscall_reinit();
int remap_fatfs_errors(FRESULT f);
void sbrk_app_set_heap_start(uintptr_t heapstart);
