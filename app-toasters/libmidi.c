
#include "libmidi.h"

static uint16_t song_step     = 0;
static uint8_t  gates         = 0;
static uint32_t last_time     = 0;
static uint32_t time_interval = 0;
static uint32_t delta         = 0;
static uint32_t voice         = 0;
static uint32_t note          = 255;

uint16_t midi_play_song(uint16_t songArray[][3], uint16_t songLength, uint32_t clocksPerClick){
	// Update only if enough time has elapsed
	if (time() - last_time >= time_interval ){
		last_time = time();

		// Reset
		if (song_step > (songLength-1)){
			song_step = 0;
		}

		// Play note or turn note off, accordingly
		if (note < 128){ // range valid midi notes
			synth_now->voice[voice].phase_inc = midi_table[note];
			gates |= (1 << voice);
		}
		else {
			gates  &= ~(1 << voice);
		}
		synth_now->voice_force = gates;

		// Get parameters
		delta = songArray[song_step][0];
		voice = songArray[song_step][1];
		note  = songArray[song_step][2];

		// Set next timer, take step
		time_interval = clocksPerClick*delta; 
		song_step++;
	}
	return song_step;
}

void midi_reset(void) {
	song_step     = 0;
	gates         = 0;
	last_time     = 0;
	time_interval = 0;
	delta         = 0;
	voice         = 0;
	note          = 255;
	synth_all_off();
}