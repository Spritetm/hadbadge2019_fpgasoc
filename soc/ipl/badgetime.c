#include <stdint.h>

#define CYCLES_PER_SECOND 48000000 // SOC runs at a constant 48 MHz
#define CYCLES_PER_MS     48000

// RISC V instruction set includes ability to retrieve CSR with the number
// of clock cycles executed since an arbitrary point in the past. In our
// case since initial power-up. Badge SOC clock speed is constant (no sleep
// mode, no slower power-saving modes, etc) so we will be using this clock
// count to derive real world time.
uint64_t cycle() {
    uint32_t high1, high2, low;
    uint64_t cycle;
    
    // There is a small chance that we read these registers just as the low 32
    // bits overflowed, incrementing the high 32 bits. If not compensated for,
    // we risk returning a time roughly 90 seconds differ from actual time.
    // We detect this condition by reading the high 32 bits twice: once before
    // and once after reading the low 32 bits.
    asm volatile ("rdcycleh %0" : "=r"(high1));
    asm volatile ("rdcycle %0" : "=r"(low));
    asm volatile ("rdcycleh %0" : "=r"(high2));

    if (high1 != high2) {
        // If the high 32 bits have indeed changed, we re-read the low 32 bits.
        // This should be faster than trying to do math and figure out if the
        // previous value was large (just before overflow) or small (just after)
        asm volatile ("rdcycle %0" : "=r"(low));
    }

    // Assemble the second value of high 32 bits with the low 32 bits.
    cycle = high2;
    cycle = (cycle<<32) | low;

    return cycle;
}

uint32_t millis() {
    return (cycle() / CYCLES_PER_MS) & 0xFFFFFFFF;
}