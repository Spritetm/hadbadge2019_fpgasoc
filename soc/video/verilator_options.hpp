#pragma once

// Setup function routines
typedef void (*setup_fn)();

// This is defined in verilator_main.cpp
// Null terminated array of pointers. Assume has at least one non-null entry
extern setup_fn setups[];

unsigned int setup_count();

// Contains found command line options
class CmdLineOptions {
public:
	CmdLineOptions() {};

	// Option fields - all public
	// For how many fields to run
	unsigned int num_fields = 3;

	// Which setup function to run
	setup_fn setup = setups[0];

	// Whether we should trace (generates large files)
	bool trace_on = false;

	// Factory method: creates from command line
	static CmdLineOptions parse(int argc, char**argv);

	// Dumps value to stdout
	void dump();
};

