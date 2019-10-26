#include "verilator_options.hpp"
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>

CmdLineOptions::CmdLineOptions(): 
	num_fields(3), trace_on(false) {}

void CmdLineOptions::dump() {
	printf("CmdLineOptions{%u, %s}", num_fields, trace_on ? "true" : "false");
}

static void errExit(char *prog_name, const char *msg, char opt) {
    fprintf(stderr, "Option '%c': %s\n"
    	"Usage: %s [-f fields] [-t]\n"
    	"  -f: number of HDMI fields to run consecutively\n"
    	"  -t: trace execution to a .vcd file\n",
    	   opt, msg, prog_name);
    exit(EXIT_FAILURE);	
}

static unsigned int readPosNum(char *prog_name, char opt, char *s) {
	if (s == NULL) {
		errExit(prog_name, "Must provide a positive number", opt);
		return 0;
	}
	unsigned int result = atoi(s);
	if (result <= 0) {
		errExit(prog_name, "Must provide a positive number", opt);
		return 0;
	}
	return result;
}

CmdLineOptions CmdLineOptions::parse(int argc, char**argv) {
	CmdLineOptions result;
	int opt;
	while ((opt = getopt(argc, argv, "f:t")) != -1) {
    	switch (opt) {
		case 'f':
			result.num_fields = readPosNum(argv[0], 'f', optarg);
			break;
		case 't':
			result.trace_on = true;
			break;
        default: /* '?' */
            errExit(argv[0], "Unknown", opt);
		}
	}
	return result;
}