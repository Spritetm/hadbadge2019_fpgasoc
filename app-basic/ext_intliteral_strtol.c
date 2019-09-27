#include <stdlib.h>
#include <string.h>
#include <stdio.h>

//Replacement strtol that understands the qb/vb/... literal hex/binary/octal formats:
//print &h10 -> 16
//print &o10 -> 8
//print &b10 -> 2

long int vbequiv_strtol(const char *nptr, char **endptr, int base) {
	if (strlen(nptr)>2 && nptr[0]=='&') {
		if ((nptr[1]=='h' || nptr[1]=='H') && (base==0 || base==16)) {
			return strtol(nptr+2, endptr, 16);
		}
		if ((nptr[1]=='o' || nptr[1]=='O') && (base==0 || base==8)) {
			return strtol(nptr+2, endptr, 8);
		}
		if ((nptr[1]=='b' || nptr[1]=='B') && (base==0 || base==2)) {
			return strtol(nptr+2, endptr, 2);
		}
	}
	return strtol(nptr, endptr, base);
}
