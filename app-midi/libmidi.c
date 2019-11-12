
#include "libmidi.h"


void midi_play_song(uint16_t songArray[][3], uint16_t songLength, uint32_t clocksPerClick){
	static uint16_t song_step     = 0;
	static uint8_t  gates         = 0;
	static uint32_t last_time     = 0;
	static uint32_t time_interval = 0;
	uint32_t delta, voice, note;

	// Update only if enough time has elapsed
	if (time() - last_time >= time_interval ){
		song_step++;

		// Reset
		if (song_step > (songLength-1)){
			song_step = 0;
		}

		// Get parameters
		delta = songArray[song_step][0];
		voice = songArray[song_step][1];
		note  = songArray[song_step][2];

		// Set next timer
		last_time = time();
		time_interval = clocksPerClick*delta; 

		// Play note or turn note off, accordingly
		if (note < 128){ // range valid midi notes
			synth_now->voice[voice].phase_inc = midi_table[note];
			synth_now->voice_force |= (1 << voice);
		}
		else {
			synth_now->voice_force  &= ~(1 << voice);
		}
	}
}
