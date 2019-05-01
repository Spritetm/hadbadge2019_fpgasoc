/*
Verilator doesn't like the bus output Yosys generates. This normalizes it a bit to what Verilator does
grok.

CC0-licensed, if you really need to re-use this hack.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_fields(char *name, char **fields, int no) {
	printf("    .%s ({", name);
	for (int i=no-1; i>=0; i--) {
		if (fields[i]) {
			printf("%s%s", fields[i], i!=0?",":"");
		} else {
			printf("0%s", i!=0?",":"");
		}
		free(fields[i]);
		fields[i]=NULL;
	}
	printf("}),\n"); //ToDo: comma is not always needed
}

int main() {
	char buff[10240];
	char *name=NULL;
	char *fields[128]={NULL};
	int no_fields=0;
	while(fgets(buff, sizeof(buff), stdin)) {
		char *namestart=strstr(buff, ".\\");
		if (namestart!=NULL) {
			namestart+=2; //skip past . and backslash
			char *nameend=strstr(buff, "[");
			if (name!=NULL && strncmp(namestart, name, nameend-namestart)!=0) {
				write_fields(name, fields, no_fields);
				free(name);
				name=NULL;
			}
			if (name==NULL) {
				name=strndup(namestart, nameend-namestart);
			}
			int idx=atoi(nameend+1);
			char *connstart=strstr(nameend, "(");
			char *connend=strstr(connstart, ")");
			fields[idx]=strndup(connstart+1, connend-connstart-1);
			if (no_fields<=idx) no_fields=idx+1;
		} else {
			if (name!=NULL) {
				write_fields(name, fields, no_fields);
				free(name);
				name=NULL;
			};
			printf("%s", buff);
		}
	}
}