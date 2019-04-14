#include <stdint.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/times.h>
#include <unistd.h>
#include <sys/timeb.h>
#include <stdio.h>
#include "uart.h"

int _access(const char *file, int mode) {
	return 0;
}

int _chdir(const char *path) {
	return -1;
}
int _chmod(const char *path, mode_t mode) {
  return -1;
}

int _chown(const char *path, uid_t owner, gid_t group) {
	return -1;
}

int _close(int file) {
	return 0;
}

int _execve(const char *name, char *const argv[], char *const env[]) {
  errno = ENOMEM;
  return -1;
}

void _exit(int exit_status) {
  while (1);
}

int _faccessat(int dirfd, const char *file, int mode, int flags) {
	return -1;
}

int _fork() {
  errno = EAGAIN;
  return -1;
}

int _fstatat(int dirfd, const char *file, struct stat *st, int flags) {
	return -1;
}

int _fstat(int file, struct stat *st) {
	return -1;
}

int _ftime(struct timeb *tp) {
  tp->time = tp->millitm = 0;
  return 0;
}

char *_getcwd(char *buf, size_t size) {
  return NULL;
}

int _getpid() {
  return 1;
}

int _gettimeofday(struct timeval *tp, void *tzp) {
	return -1;
}

int _isatty(int file) {
	return 0;
}

int _kill(int pid, int sig) {
  errno = EINVAL;
  return -1;
}

int _link(const char *old_name, const char *new_name) {
	return -1;
}

off_t _lseek(int file, off_t ptr, int dir) {
	return -1;
}

int _lstat(const char *file, struct stat *st) {
	return -1;
}

int _openat(int dirfd, const char *name, int flags, int mode) {
	return -1;
}

int _open(const char *name, int flags, int mode) {
	return -1;
}

ssize_t _read(int file, void *ptr, size_t len) {
	return -1;
}

static char *heap_ptr=0;
extern char _stack_end;
extern char _end;

char * _sbrk (int nbytes) {
	char *base;
	if (!heap_ptr) {
		heap_ptr = (char *)&_end;
	}
	base = heap_ptr;
	heap_ptr += nbytes;
	if (heap_ptr > &_stack_end) {
		printf("ERROR: Malloc is out of memory! (heap_start=%p heap_ptr=%p stack_end=%p\n", &_end, heap_ptr, &_stack_end);
		abort();
	}
	return base;
}

int _stat(const char *file, struct stat *st) {
	return -1;
}

long _sysconf(int name) {
  return -1;
}

clock_t _times(struct tms *buf) {
	return 0;
}

int _unlink(const char *name) {
	return -1;
}

int _utime(const char *path, const struct utimbuf *times) {
  return -1;
}

int _wait(int *status) {
  errno = ECHILD;
  return -1;
}

ssize_t _write(int file, const void *ptr, size_t len) {
	if (file>=0 && file<=3) {
		uart_write((const char*)ptr, len);
		return len;
	}
	return -1;
}

