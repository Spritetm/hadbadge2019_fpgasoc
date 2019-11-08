#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "mach_defines.h"
#include "gfx_load.h"
#include "cache.h"

// Copy these files into your project to use them
#include "audiolib.h"

//hardware addresses imported manually
extern volatile uint32_t MISC[];
#define MISC_REG(i) MISC[(i)/4]

static inline void pause(uint32_t duration){
	for (volatile uint32_t i=0; i<duration; i++){;}
}
#define SHORT    0x00040000
#define MIDDLE   0x00080000
#define LONG     0x00100000


void main(int argc, char **argv) {
	// So you can play the synthesizer the easy way or the hard way...
	// For the hard way, see the documentation in soc/audio/README.html or 
	//  in soc/ipl/gloss/mach_defines.h
	// But the gist is play registers for the 8 voices are on even 16s
	// AUDIO_CORE_BASE + 0x30 is the register for voice 3
	// Write the high 16 bits with the duration and the low 16 bits with the pitch.
	// And off it goes.  
	// You just need to feed the synth a string of notes/durations on time.
	// This could be done in any kind of repeating regular loop that fits.

	/* Voices are (from mach_defines.h) */ 
	/* #define AUDIO_VOICE_SAW1   0x00 */
	/* #define AUDIO_VOICE_SAW2   0x10 */
	/* #define AUDIO_VOICE_PULSE  0x20 */
	/* #define AUDIO_VOICE_SQUARE 0x30 */
	/* #define AUDIO_VOICE_TRI1   0x40 */
	/* #define AUDIO_VOICE_TRI2   0x50 */
	/* #define AUDIO_VOICE_TRI3   0x60 */
	/* #define AUDIO_VOICE_TRI4   0x70 */

	// set volume
	SYNTHREG(AUDIO_CONFIG_VOLUME) = 0x0200; // a good volume for four voices

	/* The 'hard' way: voice 4, duration in 1.35 ms, pitch in crazy units */
	/* SYNTHREG(0x40) = 0x001516DC; */	
	/* ... or the easy way */
	SYNTHREG(AUDIO_VOICE_TRI1) = AUDIO_PITCH(5852) + AUDIO_DURATION(0x0015);
	SYNTHREG(AUDIO_VOICE_TRI2) = AUDIO_PITCH(7374) + AUDIO_DURATION(0x0025);
	SYNTHREG(AUDIO_VOICE_TRI3) = AUDIO_PITCH(8769) + AUDIO_DURATION(0x0035);
	SYNTHREG(AUDIO_VOICE_TRI4) = AUDIO_PITCH(11705) + AUDIO_DURATION(0x0045);
	pause(MIDDLE);
	/* or the musical way */

	// set a slow attack/release on SAW1
	// SYNTHREG(AUDIO_VOICE_SAW1 + AUDIO_CONFIG_REG_OFFSET) = 0x00000311;	
	set_dynamics(0, 0x03, 0x11);
	// instrument 0 (SAW1) play C3, note 48, for 1000 ms
	play_midi_note(0, 48, 1000);
	pause(LONG);
	play_midi_note(4, 52, 200);	
	pause(SHORT);
	play_midi_note(5, 55, 200);	
	pause(SHORT);
	play_midi_note(6, 60, 200);	
	pause(SHORT);
	play_midi_note(7, 64, 200);	
	pause(SHORT);
	play_midi_note(4, 52, 200);	
	pause(SHORT);
	play_midi_note(5, 55, 200);	
	pause(SHORT);
	set_dynamics(3, 0x03, 0x01);
	play_midi_note(3, 48, 1000);
	pause(LONG);
	pause(LONG);
	pause(LONG);


	// random noise in PCM channel as test
	// super loud!
	set_volume(0x0010);
	for (uint32_t i=0; i<5000; i++){
		SYNTHREG(AUDIO_PCM) = MISC_REG(MISC_RNG_REG);
		// or pcm_audio(MISC_REG(MISC_RNG_REG));
		for (volatile uint32_t j=1; j<100; j++){;}  // measures at 11.65 kHz on my scope
	}
}

