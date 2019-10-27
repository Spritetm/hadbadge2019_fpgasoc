#pragma once

#include "Vvid.h"
#include <verilated_vcd_c.h>

// For GFX_* constants
#include "../ipl/gloss/mach_defines.h"

// Trace machinery
extern uint64_t ts;
double sc_time_stamp();
// tb (test bench) contains a line renderer and video memory controller
extern Vvid *tb;
// trace is non-null if verilator tracing is on
extern VerilatedVcdC *trace;

// Evaluate model, advance time and optionally trace
void tb_step(bool trace_exempt=false);

// Create the test bench
void init_test_bench(bool trace_on);

// Clock data out to a given register in video subsystem.
// This clocks the video testbench main clock without also updating pixelclk.
// For this reason, updates made while system is processing main loop may not
// be properly interpreted.
void tb_write(int addr, int data, bool trace_exempt=false);

// In sdk.h, the SDK uses the following definitions to provide access to
// registers, palette, tile memory and tile maps A & B. Most access is via 
// arrays of 32 bit integers. The GFX_REG macro provides a convenient way 
// to use the byte-numbered offsets in mach_defines.h
//
// extern volatile uint32_t GFXREG[];
// #define GFX_REG(i) GFXREG[(i)/4]
// extern uint32_t GFXPAL[];
// extern uint32_t GFXTILES[];
// extern uint32_t GFXTILEMAPA[];
// extern uint32_t GFXTILEMAPB[];
//
// We simulate these with a small set of classes
// 
// These are not a complete simulation of C++ semantics, but do allow us to
// write code that accesses this memory in a way that can be cut-and-paste
// to RiscV code.

// Simulates a uint32_t location in video_controller memory
class RegisterReference {
public:
	RegisterReference(uint64_t addr): addr(addr & ~3ULL) {}

	// Read memory not implemented
	// operator uint32_t const ();

	// Write memory
	RegisterReference& operator=(uint32_t value) {
		tb_write(addr, value);
		return *this;
	}
private:
	uint64_t addr;
};

// Simulates a pointer to uint32_t into video controller memory
// Access must be word-aligned
class RegisterPointer {
public:
	RegisterPointer(uint64_t addr): addr(addr & ~3ULL) {}

	// Do pointer-y things
	RegisterPointer operator+(size_t offset) {
		return RegisterPointer(addr + offset * 4);
	}
	RegisterReference operator*() {
		return RegisterReference(addr);
	}
	RegisterReference operator[](size_t offset) {
		return RegisterReference(addr + offset * 4);
	}

	// Assign from another pointer
	RegisterPointer& operator=(const RegisterPointer &other) {
		addr = other.addr;
	}

private:
	uint64_t addr;
};

extern RegisterPointer GFXREG;
#define GFX_REG(i) GFXREG[(i)/4]

extern RegisterPointer GFXPAL;
extern RegisterPointer GFXTILES;
extern RegisterPointer GFXTILEMAPA;
extern RegisterPointer GFXTILEMAPB;
// Sprites not actually defined in sdk.h or ldscript.ld, yet
extern RegisterPointer GFXSPRITES; 



// Send reset signal to test bench
void toggle_reset();

// Load a default palette
void load_default_palette();

// Set a sprite's position, scale and tile number
void set_sprite(int no, int x, int y, int sx, int sy, int tileno);

// Load a tile into memory from a 256 char string
// 0-9a-f are the 16 colors. 
// A-F aliases a-f
// All other characters -> lower 4 bits are used
void load_tile(int no, const char *s);
