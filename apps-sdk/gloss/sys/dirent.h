
typedef struct DIR DIR;
struct dirent {
	ino_t          d_ino;       /* Inode number */
	unsigned char  d_type;      /* Type of file */
	char           d_name[256]; /* Null-terminated filename */
};

#define DT_REG 0
#define DT_DIR 1
#define DT_UNKNOWN 2

DIR *opendir(const char *name);
struct dirent *readdir(DIR *dirp);
int closedir(DIR *dirp);

