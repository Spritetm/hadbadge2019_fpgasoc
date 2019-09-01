#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <dirent.h>

void showdir(const char *path) {
	DIR *d=opendir(path);
	if (d==NULL) {
		printf("Opendir failed.\n");
		return;
	}
	struct dirent *de;
	while ((de=readdir(d))!=NULL) {
		printf("%s\n", de->d_name);
	}
	printf("End.\n");
	closedir(d);
}


void readtxtfile(const char *file) {
	FILE *f=fopen(file, "r");
	if (f==NULL) {
		printf("opening\n");
		perror(file);
		return;
	}
	char buff[1024];
	if (fgets(buff, 1024, f)==NULL) {
		printf("reading\n");
		perror(file);
		return;
	}
	printf("Text file contents: %s", buff);
	fclose(f);
}


void main(int argc, char **argv) {
	fprintf(stderr, "Hello from app!\n");
	readtxtfile("hello.txt");
	showdir("/");
}
