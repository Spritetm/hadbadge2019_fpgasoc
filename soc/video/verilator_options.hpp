#pragma once

// Contains found command line options
class CmdLineOptions {
public:
	CmdLineOptions();

	// Option fields - all public
	// For how many fields to run
	unsigned int num_fields;

	// Factory method: creates from command line
	static CmdLineOptions parse(int argc, char**argv);

	// Dumps value to stdout
	void dump();
};

