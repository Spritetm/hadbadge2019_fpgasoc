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

#include "../fatfs/source/ff.h"
#include "newlib_stubs.h"
#include "sys/dirent.h"

typedef struct {
	F_DIR dir;
	FILINFO finfo;
	struct dirent de;
} mydir_t;

DIR *opendir(const char *name) {
	FRESULT r;
	mydir_t *dp=calloc(sizeof(mydir_t), 1);
	r=f_opendir(&dp->dir, name);
	if (r!=FR_OK) {
		free(dp);
		remap_fatfs_errors(r);
		return NULL;
	}
	return (DIR*)dp;
}

struct dirent *readdir(DIR *dirp) {
	mydir_t *md=(mydir_t*)dirp;
	FRESULT r=f_readdir(&md->dir, &md->finfo);
	if (r!=FR_OK) {
		remap_fatfs_errors(r);
		return NULL;
	}
	if (md->finfo.fname[0]==0) {
		//f_readdir indicates end
		remap_fatfs_errors(FR_OK);
		return NULL;
	}
	md->de.d_ino=0;
	strncpy(md->de.d_name, md->finfo.fname, sizeof(md->finfo.fname));
	md->de.d_type=(md->finfo.fattrib&AM_DIR)?DT_DIR:DT_REG;
	return &md->de;
}

int closedir(DIR *dirp) {
	mydir_t *md=(mydir_t*)dirp;
	free(md);
	return 0;
}

