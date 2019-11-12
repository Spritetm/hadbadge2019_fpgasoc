#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "libsynth.h"
#include "synth_utils.h"
#include "midi_note_increments.h"
#include "mach_defines.h"
#include "cache.h"
#include "sdk.h"

// A quick note on timing.  Everything here is in duration counts.

// A duration count is 5.33 ms, or 1000 * 256 / 48MHz 
// On a musical scale, a quarter note at 120 BPM is 500 ms
//  so 80 durations is a quarter note at 140.625 BPM (fast)
//     90 durations is a quarter note at 125     BPM
//    100 durations is a quarter note at  93.75  BPM (mellow)

// Blocking wait. The worst way to go!
// In your code, test for elapsed time, else return
// Or use the synth_play_queued function -- read on!
void wait(uint32_t duration_counts){
	uint32_t timenow = time();
	while (time() - timenow <= duration_counts * 256 * 1000){;}
}

// Table of contents:
#define INTRO     1
#define DYNAMICS  1
#define WAVEFORMS 1
#define QUEUE     1
#define FREAKOUT  1

// All of the higher-level functions are defined in synth/synth_utils.c
// And all of the lower-level registers in synth/libsynth.h


void main(int argc, char **argv)
{
	synth_init(8); // set up 8 voices	



#if INTRO
	//  and then the simplest way to play is just notes:
	//  a lookup table converts MIDI note numbers to pitches:
	// void synth_play(uint8_t voice, uint8_t note, uint16_t duration)
	synth_play(0, 69, 80);  
	wait(80);

	synth_play(0, 73, 40);  
	wait(60);

	synth_play(0, 76, 40); 
	wait(60);

	// Of course, we have 8 voices
	synth_play(0, 69, 160);  // about 270 ms
	synth_play(1, 73, 160);  
	synth_play(2, 76, 160); 
	synth_play(3, 81, 160); 
	wait(320);

	// Remembering MIDI note number is kinda lame
	// Instead use key and scale degree?
	for (uint8_t i=1; i<=8; i++){
		synth_play(0, 69 + scale_major(i), 40);
		wait(60);
	}

#endif

#if DYNAMICS
	// Now, you can change the dynamics of each voice by tweaking voice registers
	// These you'll find in libsynth.h
	// The synth has a queuing system (more soon!) but you if you want it to happen
	// now, you use synth_now.
	// Here, the voices come in smooth and fade away (decay, ok, really release) fast
	// The attack/decay rates can be set with just the low byte, as here.
	for (uint8_t i=0; i<4; i++){
		synth_now->voice[i].attack   = 0x20; // slow
		synth_now->voice[i].decay    = 0xFF; // fast
	}
	synth_play(0, 69 + scale_major(1), 320);
	synth_play(1, 69 + scale_major(3), 320);
	synth_play(2, 69 + scale_major(5), 320);
	synth_play(3, 69 + scale_major(8), 320);
	wait(600);

	// And vice-versa
	for (uint8_t i=0; i<4; i++){
		synth_now->voice[i].attack   = 0xFF; // fast
		synth_now->voice[i].decay    = 0x10; // slow
	}
	synth_play(0, 69 + scale_major(1), 320);
	synth_play(1, 69 + scale_major(3), 320);
	synth_play(2, 69 + scale_major(5), 320);
	synth_play(3, 69 + scale_major(8), 320);
	wait(1200);

	// Middle ground, demo of convenience function
	for (uint8_t i=0; i<4; i++){
		synth_set_dynamics(i, 0x80, 0x80);
	}

	// Special needs only:
	// The top byte is interpreted as signed, and controls how often the envelope is updated:
	//   0x00 is every 16 samples, 0x01 every 32.  
	//   Any negative numbers (0x80-0xFF) are super-fast: updating every sample.

#endif


#if WAVEFORMS
	// Etc. 
	//
	// There are multiple waveforms to choose from:
	// Sawtooth you've just heard, triangle is a lot mellower,
	// pulse is even jaggier, 
	// and pulse + suboctave only really good on big speakers.
	// There is also a wavetable, where you can load your own waveforms.
	// The standard waves: 
	// SYNTH_VOICE_CTRL_SAWTOOTH, SYNTH_VOICE_CTRL_TRIANGLE
	// SYNTH_VOICE_CTRL_PULSE, SYNTH_VOICE_CTRL_SUBOCTAVE
	// void synth_set_waveform(uint8_t voice, uint8_t waveform)

	synth_set_waveform(0, SYNTH_VOICE_CTRL_SAWTOOTH);
	synth_play(0, 60 + scale_major(1), 320);
	wait(320);
	synth_set_waveform(0, SYNTH_VOICE_CTRL_TRIANGLE);
	synth_play(0, 60 + scale_major(1), 320);
	wait(320);
	synth_set_waveform(0, SYNTH_VOICE_CTRL_PULSE);
	synth_play(0, 60 + scale_major(1), 320);
	wait(320);
	synth_set_waveform(0, SYNTH_VOICE_CTRL_SUBOCTAVE);
	synth_play(0, 60 + scale_major(1), 320);
	wait(320);

	// Back to "normal"
	synth_set_waveform(0, SYNTH_VOICE_CTRL_SAWTOOTH);
#endif

#if QUEUE
	// Finally, there is a queue system that gets rid of all of the wait statements, 
	// and completely unburdens the CPU.  
	// You pile commands in and they execute, with one difference:
	//  each command takes an additional wait_until value, and it waits until
	//  that time has elapsed to play.
	// This means that the wait_until value of the next note will determine
	//  the length of the current one if you re-use the voice.
	// If you need overlap, just use another voice. 

	// synth_play_queued(uint8_t voice, uint8_t note, uint16_t duration, uint32_t wait_until);
	synth_play_queued(0, 60 + scale_major(1), 40, 40);
	synth_play_queued(0, 60 + scale_major(3), 40, 40);
	synth_play_queued(0, 60 + scale_major(5), 40, 40);
	// raw register command, changing the decay (release) to make the next note ring
	synth_queue->voice[0].decay = 0x8080; 
	synth_play_queued(0, 60 + scale_major(8), 40, 40);

	// Note that you can do anything arbitrarily fancy with the queue, 
	// sending it any command that you would otherwise, including voicing and parameter changes.
	//
	// It can run at the same time as synth_now commands.

	// You can even set the queue to trigger interrupts on particular notes or when it's empty
	// This makes it possible to re-fill the queue automatically, running in eternal loop.
	
	// But if you're one-shotting it, and nothing else is happening in your program, 
	// you want to wait for it to finish.
	wait(320);

#endif

#if FREAKOUT
	// PWM, phasing, swapping waveforms, crazy shenanigans
	// A classic effect with square/pulse waves is varying the pulse-width over time
	// The full phase is 2**14 bits, so a square wave with half of that has a phase_cmp of (1<<13)
	// We're going to modulate from 1/2 to 1/16th duty cycle 

	synth_set_waveform(0, SYNTH_VOICE_CTRL_PULSE);
	synth_now->voice[0].phase_cmp=(1<<13); // start off square

	synth_now->voice_force = (1 << 0); // play now until turned off
	uint32_t phase_max;
	for (uint8_t j=0; j<4; j++){
		for (phase_max = (1<<13) ; phase_max > (1<<10); phase_max=phase_max*15/16){
			synth_now->voice[0].phase_cmp=phase_max;
			wait(4-j);
		}
		for (phase_max = (1<<10) ; phase_max < (1<<13); phase_max=phase_max*16/15){
			synth_now->voice[0].phase_cmp=phase_max;
			wait(4-j);
		}
	}
	synth_now->voice_force = 0; // all off
	wait(120);

	// Phasing: two oscillators, especially sawtooths, can produce a similar sound
	// The oscs are slightly detuned and can sound really great/droney.  We have eight.
	// We'll need to access the phase increment (pitch) register directly
	synth_set_waveform(0, SYNTH_VOICE_CTRL_SAWTOOTH);
	synth_now->voice[0].phase_inc = midi_table[36]; 

	synth_set_waveform(1, SYNTH_VOICE_CTRL_SAWTOOTH);
	synth_now->voice[1].phase_inc = midi_table[36] + 7; 

	synth_now->voice_force = ( (1 << 0) | (1 << 1) ); // voice 0 and 1
	wait(1200);
	// Or with suboctave pulse?
	synth_set_waveform(0, SYNTH_VOICE_CTRL_SUBOCTAVE);
	synth_now->voice[0].phase_inc = midi_table[48]; 
	synth_set_waveform(1, SYNTH_VOICE_CTRL_SUBOCTAVE);
	synth_now->voice[1].phase_inc = midi_table[48] + 7; 
	wait(1200);
	synth_now->voice_force = 0; 
	wait(120);

	// Dive bomb?
	synth_set_waveform(0, SYNTH_VOICE_CTRL_PULSE);
	synth_now->voice[0].phase_cmp=(1 << 13);
	synth_now->voice_force = (1 << 0); 
	for (uint32_t pitch = midi_table[68+12]; pitch > midi_table[68-36] ; pitch=pitch*31/32){
		synth_now->voice[0].phase_inc = pitch; 
		wait(4);
	}
	synth_now->voice_force = 0; 
	wait(240);

	// As bass drum.  Game-boy style.
	// (watch out for max queue depth of 512)!
	synth_set_waveform(0, SYNTH_VOICE_CTRL_SAWTOOTH);
	synth_now->voice_force = (1 << 0); 
	for (uint32_t pitch = midi_table[64] ; pitch > midi_table[64-36] ; pitch=(pitch*15/16)){
		synth_queue->voice[0].phase_inc = pitch; 
		synth_queue->cmd_wait = 250; 
	}
	synth_queue->voice_force = 0; 
	wait(40);

	// What else?  Random bleeps?  

#endif

	// Finito bandito!
	wait(320);
	synth_now->voice_force = 0; 
}

