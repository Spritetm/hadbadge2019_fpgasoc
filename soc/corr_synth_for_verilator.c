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


void fix_module_line(char *line) {
	//module (bla, \yadda[0] , \yadda[1], ..) -> module bla, yadda -> module bla, [1:0] yadda)
	char *field[1024]={NULL};
	int fieldcnt[1024]={0};
	int fieldpos=0;

	char buf[10240];
	char *p=strstr(line, "(")+1;
	strncpy(buf, line, p-line);
	buf[p-line]=0;
	printf("%s", buf);
	while(p!=NULL) {
		//find end of field
		char *fe=strstr(p, ",");
		if (!fe) fe=strstr(p, ")");
		while (*fe==' ') fe--;

		strcpy(buf, p);
		buf[fe-p]=0;
		char *brackstart=strstr(buf, "[");
		if (brackstart==NULL) {
			field[fieldpos]=strdup(buf);
			fieldcnt[fieldpos]=0;
			fieldpos++;
		} else {
			*brackstart=0;
			int idx=atoi(brackstart+1);
			int found=0;
			for (int i=0; i<fieldpos; i++) {
				if (strcmp(field[i], buf)==0) {
					if (fieldcnt[i]<idx) fieldcnt[i]=idx;
					found=1;
					break;
				}
			}
			if (!found) {
				field[fieldpos]=strdup(buf);
				fieldcnt[fieldpos]=idx;
				fieldpos++;
			}
		}
		//next ele
		p=strstr(p, ",");
		if (p!=NULL) {
			p++; //skip comma
			while (*p==' ' || *p=='\\') p++; //skip spaces and escape
		}
	}
	for (int i=0; i<fieldpos; i++) {
		if (fieldcnt[i]==0) {
			printf("%s", field[i]);
		} else {
			printf("input [%d:0] %s", fieldcnt[i], field[i]);
		}
		if (i!=fieldpos-1) printf(", ");
	}
	printf(");\n");
}


int main() {
	char buff[10240];
	char *name=NULL;
	char *fields[128]={NULL};
	int no_fields=0;
	int had_module_line=0;
	while(fgets(buff, sizeof(buff), stdin)) {
		char *namestart=strstr(buff, ".\\");
		if (!had_module_line && (strstr(buff, "module ")!=NULL)) {
			fix_module_line(buff);
		} else if (namestart!=NULL) {
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