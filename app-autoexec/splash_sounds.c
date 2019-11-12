#include "libsynth.h"
#include "synth_utils.h"
#include "midi_note_increments.h"
#include "splash_sounds.h"

void synth_play_gameboy_monochrome(void){
	synth_now->samplerate_div = (1000 - 2);	/* 48M / 1000 = 48 kHz */
	synth_now->volume = 255;			/* Max volume */

	synth_queue->voice[0].ctrl     = SYNTH_VOICE_CTRL_ENABLE | SYNTH_VOICE_CTRL_TRIANGLE;
	synth_queue->voice[0].volume   = SYNTH_VOICE_VOLUME(255,255);
	synth_queue->voice[0].attack   = 0xFFFF; // instant
	synth_queue->voice[0].decay    = 0x20; // slow
	synth_queue->voice[0].phase_cmp= (1 << 13); 
	
	synth_queue->cmd_wait = 500 * 256; // factor to line up sample clocks and duration counts
	synth_queue->cmd_wait = 500 * 256; // factor to line up sample clocks and duration counts
	synth_queue->cmd_wait = 500 * 256; // factor to line up sample clocks and duration counts
	synth_queue->cmd_wait = 500 * 256; // factor to line up sample clocks and duration counts
	synth_queue->cmd_wait = 50 * 256; // factor to line up sample clocks and duration counts

	synth_queue->voice[0].duration = 20;   // ~ quarter note at 125 BPM 
	synth_queue->voice[0].phase_inc = midi_table[89];
	synth_queue->voice_start = (1 << 0);
	synth_queue->cmd_wait = 15 * 256; // factor to line up sample clocks and duration counts

	synth_queue->voice[0].duration = 90;   // ~ quarter note at 125 BPM 
	synth_queue->voice[0].phase_inc = midi_table[96];
	synth_queue->voice_start = (1 << 0);
	synth_queue->cmd_wait = 150 * 256; // factor to line up sample clocks and duration counts
}

void synth_play_gameboy_color(void){
	;
}
void synth_play_switch(void){
	;
}
void synth_play_sega(void){
	;
}
void synth_play_playstation(void){
	;
}
void synth_play_xbox(void){
	;
}

