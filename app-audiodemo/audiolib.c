
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "mach_defines.h"
#include "gfx_load.h"
#include "cache.h"
#include "audiolib.h"
#include "midi_note_increments.h"

//hardware addresses I really need to dump into an include or something...
extern volatile uint32_t SYNTH[];
#define SYNTHREG(i) SYNTH[i/4]

// Play voices 0-7, for duration milliseconds, at pitch
// To get any real accuracy, you want to use fixed point for the pitch:
// say 10.3 fixed point.  What this means is that you multiply the pitch by 8
// Our slow clock is about 4/3 of a millisecond
void play(uint8_t voice, uint16_t pitch, uint16_t duration){
	uint32_t pitch_increment;
	uint16_t duration_count;
	pitch_increment = (pitch * 358) >> 7;   
	duration_count = (duration * 3) >> 2 ;
	SYNTHREG(0x10 * voice) = AUDIO_PITCH(pitch) + AUDIO_DURATION(duration);
}


// Same thing, but instead of raw frequencies, looks up frequency from the MIDI note number
// Less flexible, easier to play in tune.  60 is Middle C.
// https://newt.phys.unsw.edu.au/jw/notes.html
// Here, I just calculate each pitch increment directly
void play_midi_note(uint8_t voice, uint8_t midi_note_num, uint16_t duration){
	uint16_t pitch_increment = midi_table[midi_note_num] ;
	uint16_t duration_count ;
	duration_count = (duration * 3) >> 2 ;
	SYNTHREG(0x10 * voice) = AUDIO_PITCH(pitch_increment) + AUDIO_DURATION(duration_count);
}

void set_dynamics(uint8_t voice, uint8_t attack, uint8_t release){
	SYNTHREG(0x10 * voice + AUDIO_CONFIG_REG_OFFSET) = \
		AUDIO_ATTACK(attack) + AUDIO_RELEASE(release);	
}

void set_volume(uint16_t volume){
	SYNTHREG(AUDIO_CONFIG_VOLUME) = volume; 
}

void pcm_audio(uint16_t sample){
	SYNTHREG(AUDIO_PCM) = sample;
}



