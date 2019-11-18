#pragma once

#include <stdint.h>
#include "libsynth.h"
#include "synth_utils.h"
#include "midi_note_increments.h"

// Our brand of MIDI song data has three uint16_ts per event
// Delay in clocks per quarter note (480 / quarter note standard)
// Which voice to act on
// What MIDI note to play: 0-127 are note on events, 255 is note off
// See the Python routine in app-midi for a converter
//   and lots of examples

// 48000000 clock speed / 120 BPM / 480 clocks per quarter note
#define BPM(x)    (48000000 / x * 60 / 480)

// Takes song data, plays it.  
// This needs to be polled at least as often 
// as the fastest time interval between events.
// If not, it'll come in late, but it's not buffered.
// I.e. if these stack up, things drift out of sync
// For most music, this is OK.  But only you know for sure.
// Given an array with the music for Tetris in it:
// midi_play_song(tetris, SONGLENGTH(tetris), BPM(120)); 
//
// Returns which step in the song just played
uint16_t midi_play_song(uint16_t songArray[][3], uint16_t length, uint32_t clocksPerClick);

// stops music playback and resets to initial conditions allowing changing
// to a new song
void midi_reset(void);

