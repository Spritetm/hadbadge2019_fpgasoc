/*
 * Copyright 2019 Jeroen Domburg <jeroen@spritesmods.com>
 * This is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software.  If not, see <https://www.gnu.org/licenses/>.
 */
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/times.h>
#include <unistd.h>
#include <sys/timeb.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <utime.h>


#include "uart.h"
#include "../fatfs/source/ff.h"
#include "../loadapp.h"
#include "console_out.h"
#include "mach_defines.h"

#include "tusb.h"

int remap_fatfs_errors(FRESULT f) {
	if (f==FR_OK) return 0;
	switch (f) {
		case FR_NO_FILE         : errno = ENOENT;   break;
		case FR_NO_PATH         : errno = ENOENT;   break;
		case FR_INVALID_NAME	: errno = EINVAL;	break;
		case FR_INVALID_DRIVE	: errno = ENODEV;	break;
		case FR_DENIED			: errno = EACCES;	break;
		case FR_EXIST			: errno = EEXIST;	break;
		case FR_NOT_READY		: errno = EIO;		break;
		case FR_WRITE_PROTECTED : errno = EACCES;	break;
		case FR_DISK_ERR		: errno = EIO;		break;
		case FR_NOT_ENABLED		: errno = EIO;		break;
		case FR_NO_FILESYSTEM	: errno = EIO;		break;
		case FR_INVALID_OBJECT	: errno = EBADF;	break;
		default					: errno = EIO;		break;
	}
	return -1;
}

#define FD_TYPE_DBGUART 0
#define FD_TYPE_USBUART 1
#define FD_TYPE_CONSOLE 2
#define FD_TYPE_FATFS 3

#define FD_FLAG_OPEN (1<<0)
#define FD_FLAG_WRITABLE (1<<1)

#define MAX_FD 32

typedef struct {
	short flags;
	short type;
	FIL *fatfcb;
} fd_t;

static fd_t fd_entry[MAX_FD]={0};

//Prepares state here for first app, or load of a new app.
void syscall_reinit() {
	//Close and clear all entries
	for (int i=0; i<MAX_FD; i++) {
		if (fd_entry[i].flags & FD_FLAG_OPEN) close(i);
		memset(&fd_entry[i], 0, sizeof(fd_t));
	}
	//Open stdin/out/error
	for (int i=0; i<3; i++) {
		fd_entry[i].type=FD_TYPE_DBGUART;
		fd_entry[i].flags=FD_FLAG_OPEN|FD_FLAG_WRITABLE;
	}
}


int _access(const char *file, int mode) {
	FILINFO fi;
	FRESULT r=f_stat(file, &fi);
	return remap_fatfs_errors(r);
}

int _chdir(const char *path) {
	FRESULT r=f_chdir(path);
	return remap_fatfs_errors(r);
}

int _chmod(const char *path, mode_t mode) {
	//nope
	return -1;
}

int _chown(const char *path, uid_t owner, gid_t group) {
	//not a chance
	return -1;
}



int _open(const char *name, int flags, int mode) {
	int i;
	for (i=0; i<MAX_FD; i++) {
		if ((fd_entry[i].flags & FD_FLAG_OPEN) == 0) break;
	}
	if (i==MAX_FD) {
		errno=ENFILE;
		return -1;
	}
	// Special cases for device files
	if (!strcmp(name, "/dev/ttyUSB")) {
		fd_entry[i].type=FD_TYPE_USBUART;
		fd_entry[i].flags=FD_FLAG_OPEN;
		if ((flags+1) & (O_WRONLY+1)) fd_entry[i].flags|=FD_FLAG_WRITABLE;
	} else if (!strcmp(name, "/dev/ttyserial")){
		fd_entry[i].type=FD_TYPE_DBGUART;
		fd_entry[i].flags=FD_FLAG_OPEN;
		if ((flags+1) & (O_WRONLY+1)) fd_entry[i].flags|=FD_FLAG_WRITABLE;
	} else if (!strcmp(name, "/dev/console")){
		fd_entry[i].type=FD_TYPE_CONSOLE;
		fd_entry[i].flags=FD_FLAG_OPEN;
	} else {
		int fmode=0;
		if (flags & O_APPEND) fmode|=FA_OPEN_APPEND;
		if (flags & O_CREAT) fmode|=FA_OPEN_ALWAYS;
		if (flags & O_EXCL) fmode|=FA_CREATE_NEW;
		if (flags & O_TRUNC) fmode|=FA_CREATE_ALWAYS;
		//madness, O_RDONLY=0, O_WRONLY=1, O_RDWR=2. Adding one makes it into a bitmap.
		if ((flags+1) & (O_RDONLY+1)) fmode|=FA_READ;
		if ((flags+1) & (O_WRONLY+1)) fmode|=FA_WRITE;
		fd_entry[i].fatfcb=calloc(sizeof(FIL), 1);
		FRESULT r=f_open(fd_entry[i].fatfcb, name, fmode);
		if (r==F_OK) {
			fd_entry[i].flags=FD_FLAG_OPEN;
			fd_entry[i].type=FD_TYPE_FATFS;
		} else {
			free(fd_entry[i].fatfcb);
			i=-1;
		}
		remap_fatfs_errors(r);
	}
	return i;
}

#define CHECK_IF_FATFS_FD(fd) if (fd<0 || fd>=MAX_FD || \
		((fd_entry[fd].flags & FD_FLAG_OPEN)==0) || \
		(fd_entry[fd].type!=FD_TYPE_FATFS)) return remap_fatfs_errors(FR_INVALID_OBJECT)

#define CHECK_IF_VALID_FD(fd) if (fd<0 || fd>=MAX_FD || \
		((fd_entry[fd].flags & FD_FLAG_OPEN)==0)) return remap_fatfs_errors(FR_INVALID_OBJECT)


off_t _lseek(int file, off_t ptr, int dir) {
	CHECK_IF_FATFS_FD(file);
	FRESULT r=FR_INVALID_OBJECT;
	if (dir==SEEK_SET) {
		r=f_lseek(fd_entry[file].fatfcb, ptr);
	} else if (dir==SEEK_CUR) {
		FSIZE_t curpos=f_tell(fd_entry[file].fatfcb);
		r=f_lseek(fd_entry[file].fatfcb, curpos+ptr);
	} else if (dir==SEEK_END) {
		FSIZE_t endpos=f_size(fd_entry[file].fatfcb);
		r=f_lseek(fd_entry[file].fatfcb, endpos+ptr);
	}
	return f_tell(fd_entry[file].fatfcb);
}


//ToDo: can also read from UART...
ssize_t _read(int file, void *ptr, size_t len) {
	CHECK_IF_FATFS_FD(file);
	UINT rlen;
	FRESULT r=f_read(fd_entry[file].fatfcb, ptr, len, &rlen);
	remap_fatfs_errors(r);
	return (r!=F_OK)?-1:rlen;
}

ssize_t _write(int file, const void *ptr, size_t len) {
	CHECK_IF_VALID_FD(file);
	if (fd_entry[file].type==FD_TYPE_DBGUART) {
		uart_write((const char*)ptr, len);
		return len;
	} else if (fd_entry[file].type==FD_TYPE_USBUART) {
		return tud_cdc_write(ptr, len);
	} else if (fd_entry[file].type==FD_TYPE_CONSOLE) {
		return console_write(ptr, len);
	} else if (fd_entry[file].type==FD_TYPE_FATFS) {
		UINT rlen;
		FRESULT r=f_write(fd_entry[file].fatfcb, ptr, len, &rlen);
		remap_fatfs_errors(r);
		return (r!=FR_OK)?-1:rlen;
	}
	return remap_fatfs_errors(FR_INVALID_OBJECT);
}

int _fstat(int file, struct stat *st) {
	CHECK_IF_FATFS_FD(file);
	memset(st, 0, sizeof(struct stat));
	st->st_size=f_size(fd_entry[file].fatfcb);
	return 0;
}

int _close(int file) {
	CHECK_IF_VALID_FD(file);
	if (fd_entry[file].type==FD_TYPE_FATFS) {
		f_close(fd_entry[file].fatfcb);
		free(fd_entry[file].fatfcb);
	}
	memset(&fd_entry[file], 0, sizeof(fd_t));
	return 0;
}

int _stat(const char *file, struct stat *st) {
	FILINFO nfo;
	FRESULT r=f_stat(file, &nfo);
	if (r!=F_OK) return remap_fatfs_errors(r);
	memset(st, 0, sizeof(struct stat));
	st->st_size=nfo.fsize;
	return 0;
}

//no symlinks supported so alias for stat
int _lstat(const char *file, struct stat *st) {
	return stat(file, st);
}


//no support for _*at functions yet
int _openat(int dirfd, const char *name, int flags, int mode) {
	return -1;
}

//no support for _*at functions yet
int _faccessat(int dirfd, const char *file, int mode, int flags) {
	return -1;
}

//no support for _*at functions yet
int _fstatat(int dirfd, const char *file, struct stat *st, int flags) {
	return -1;
}

//ToDo: clear all fds, load new app
int _execve(const char *name, char *const argv[], char *const env[]) {
	errno = ENOMEM;
	return -1;
}

//Unload app, return to IPL... we can fake it by jumping to a secondary IPL entry point 
//in memory, like the primary one the bootloader does.
void exit_to_ipl(int exit_status); //defined in crt0.S
void _exit(int exit_status) {
	exit_to_ipl(exit_status);
}

//Nein.
int _fork() {
	errno = EAGAIN;
	return -1;
}

//No RTC, sorry.
int _ftime(struct timeb *tp) {
	tp->time = tp->millitm = 0;
	return 0;
}

char *_getcwd(char *buf, size_t size) {
	FRESULT r=f_getcwd(buf, size);
	return (r==F_OK)?buf:NULL;
}

int _getpid() {
	return 1;
}

int _gettimeofday(struct timeval *tp, void *tzp) {
	return -1;
}

int _isatty(int file) {
	CHECK_IF_VALID_FD(file);
	if (fd_entry[file].type==FD_TYPE_DBGUART) return 1;
	if (fd_entry[file].type==FD_TYPE_USBUART) return 1;
	if (fd_entry[file].type==FD_TYPE_CONSOLE) return 1;
	return 0;
}

int _kill(int pid, int sig) {
	errno = EINVAL;
	return -1;
}

int _link(const char *old_name, const char *new_name) {
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

//Note! This sbrk implementation is only used in the IPL itself.

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
		printf("ERROR: _sbrk (IPL): Malloc is out of memory! (heap_start=%p heap_ptr=%p stack_end=%p\n", &_end, heap_ptr, &_stack_end);
		//Don't abort as it will just re-enter the IPL with the heap chock full.
		volatile int *p=0;
		*p=1;
	}
	return base;
}

static char *app_heap_ptr=0;

void sbrk_app_set_heap_start(uintptr_t heapstart) {
	heapstart=(heapstart+3)&(~3);
	app_heap_ptr=(char*)heapstart;
}

char * sbrk_app (int nbytes) {
	char *base;
	base = app_heap_ptr;
	app_heap_ptr += nbytes;
	if (app_heap_ptr > (void*)(MACH_RAM_START+MACH_RAM_SIZE)) {
		printf("ERROR: sbrk_app: Malloc is out of memory! (heap_ptr=%p stack_end=%p\n", app_heap_ptr, &_stack_end);
		abort();
	}
	return base;
}



