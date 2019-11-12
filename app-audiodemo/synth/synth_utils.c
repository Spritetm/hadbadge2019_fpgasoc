#include "synth_utils.h"
#include "midi_note_increments.h"

// Bunch of defaults that render the synth engine immediately playable on any of the voices
// If you know what you want, you might not need this.  
// But if you just want something to start with, this ia a good bet.
// synth_init(4) will set you up with four sawtooth-wave voices.  Bam!
void synth_init(uint8_t numvoices){
	synth_now->samplerate_div = (1000 - 2);	/* 48M / 1000 = 48 kHz */
	synth_now->volume = 255;			/* Max volume */

	// Sensible defaults?
	for (uint8_t j=0; j<numvoices; j++) {
		synth_now->voice[j].ctrl     = SYNTH_VOICE_CTRL_ENABLE | SYNTH_VOICE_CTRL_SAWTOOTH;
		synth_now->voice[j].volume   = SYNTH_VOICE_VOLUME(255,255);
		synth_now->voice[j].duration = 90;   // ~ quarter note at 125 BPM 
		synth_now->voice[j].attack   = 0x80; // moderate
		synth_now->voice[j].decay    = 0x80;
		// width of pulse waveform: phase accumulator is 2**14, default square wave
		synth_now->voice[j].phase_cmp= (1 << 12); 
		synth_now->voice[j].phase_inc = midi_table[60]; // middle C
	}
}

void synth_set_waveform(uint8_t voice, uint8_t waveform){
	synth_now->voice[voice].ctrl = SYNTH_VOICE_CTRL_ENABLE | waveform;
}

void synth_all_off(){
	synth_now->voice_force = 0;	
}


uint32_t time() {
	uint32_t cycles;
	asm volatile ("rdcycle %0" : "=r"(cycles));
	return cycles;
}

void synth_play(uint8_t voice, uint8_t note, uint16_t duration){
	synth_now->voice[voice].phase_inc = midi_table[note]; 
	// 0-127 : 60 is middle C
	synth_now->voice[voice].duration = duration; 
	// about 5.35 ms/tick
	synth_now->voice_start |= (1 << voice); 
	// plays as soon as it gets the start
}

void synth_set_dynamics(uint8_t voice, uint8_t attack_rate, uint8_t decay_rate){
	// sorry about the confusion between release and decay.
	// It's really release, but it got called "decay" early on in development.
	synth_now->voice[voice].attack = attack_rate;
	synth_now->voice[voice].decay = decay_rate;
}

void synth_play_queued(uint8_t voice, uint8_t note, uint16_t duration, uint32_t wait_until){
	synth_queue->cmd_wait = wait_until * 256; // factor to line up sample clocks and duration counts
	synth_queue->voice[voice].phase_inc = midi_table[note];
	synth_queue->voice[voice].duration = duration; 
	synth_queue->voice_start = (1 << voice);
}

int scale_major(uint8_t scale_degree){
	// Note that the 1st degree of the scale is the zero'th entry in the table.
	if (scale_degree == 0){scale_degree = 1;}
	uint8_t index = scale_degree - 1;
	uint8_t scale_table_major[] = {0, 2, 4, 5, 7, 9, 11};
	return (index/7)*12 + scale_table_major[index % 7];
}

