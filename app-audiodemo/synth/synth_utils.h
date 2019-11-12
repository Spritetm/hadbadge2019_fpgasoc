
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "libsynth.h"

#define SECONDS 48000000
#define MILLIS  48000

/* Higher-level synthesizer utility functions begin here */

// Sets up numvoices to bland triangle waves
void synth_init(uint8_t numvoices);

// Turns all voices off, now.
void synth_all_off();

uint32_t time();

void synth_set_waveform(uint8_t voice, uint8_t waveform);
void synth_play(uint8_t voice, uint8_t note, uint16_t duration);
void synth_play_queued(uint8_t voice, uint8_t note, uint16_t duration, uint32_t wait_until);
void synth_set_dynamics(uint8_t voice, uint8_t attack_rate, uint8_t decay_rate);

int scale_major(uint8_t scale_degree);
