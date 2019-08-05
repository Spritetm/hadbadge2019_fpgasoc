#ifndef HEXDUMP_H
#define HEXDUMP_H

#ifdef __cplusplus
extern "C" {
#endif


void hexdump(void *mem, int len);
void hexdumpFrom(void *mem, int len, int addrFrom);

#ifdef __cplusplus
}
#endif


#endif