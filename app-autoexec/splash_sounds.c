#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "libsynth.h"
#include "synth_utils.h"
#include "midi_note_increments.h"
#include "splash_sounds.h"

extern char _binary_switch_raw_start;
extern char _binary_switch_raw_end;
extern char _binary_sega_raw_start;
extern char _binary_sega_raw_end;
extern char _binary_playstation_raw_start;
extern char _binary_playstation_raw_end;
extern char _binary_xbox_raw_start;
extern char _binary_xbox_raw_end;


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
	synth_now->samplerate_div = (1000 - 2);	/* 48M / 1000 = 48 kHz */
	synth_now->volume = 255;			/* Max volume */

	synth_queue->voice[0].ctrl     = SYNTH_VOICE_CTRL_ENABLE | SYNTH_VOICE_CTRL_TRIANGLE;
	synth_queue->voice[0].volume   = SYNTH_VOICE_VOLUME(255,255);
	synth_queue->voice[0].attack   = 0xFFFF; // instant
	synth_queue->voice[0].decay    = 0x20; // slow
	synth_queue->voice[0].phase_cmp= (1 << 13); 

	synth_queue->cmd_wait = 500 * 256; // factor to line up sample clocks and duration counts
	synth_queue->cmd_wait = 500 * 256; // factor to line up sample clocks and duration counts
	synth_queue->cmd_wait = 200 * 256; // factor to line up sample clocks and duration counts

	synth_queue->voice[0].duration = 20;   // ~ quarter note at 125 BPM 
	synth_queue->voice[0].phase_inc = midi_table[89];
	synth_queue->voice_start = (1 << 0);
	synth_queue->cmd_wait = 15 * 256; // factor to line up sample clocks and duration counts

	synth_queue->voice[0].duration = 90;   // ~ quarter note at 125 BPM 
	synth_queue->voice[0].phase_inc = midi_table[96];
	synth_queue->voice_start = (1 << 0);
	synth_queue->cmd_wait = 150 * 256; // factor to line up sample clocks and duration counts
}
void synth_play_switch(void){
	pcm_fill_switch();
	audio_regs->csr = (audio_regs->csr & 0xffff0000) | AUDIO_CSR_IRQ_PCM_AEMPTY;	/* clear all conditions and enable interrupt */
	mach_set_int_handler(INT_NO_AUDIO, audio_interrupt_handler_switch);
	mach_int_ena(1 << INT_NO_AUDIO);
	/* configure and enable pcm */
	audio_regs->pcm_cfg = PCM_CFG_ENABLE | PCM_CFG_DIV(2175-2) | PCM_CFG_VOLUME(128, 128);
}
void synth_play_sega(void){
	pcm_fill_sega();
	audio_regs->csr = (audio_regs->csr & 0xffff0000) | AUDIO_CSR_IRQ_PCM_AEMPTY;	/* clear all conditions and enable interrupt */
	mach_set_int_handler(INT_NO_AUDIO, audio_interrupt_handler_sega);
	mach_int_ena(1 << INT_NO_AUDIO);
	/* configure and enable pcm */
	audio_regs->pcm_cfg = PCM_CFG_ENABLE | PCM_CFG_DIV(2175-2) | PCM_CFG_VOLUME(128, 128);
	
}
void synth_play_playstation(void){
	pcm_fill_playstation();
	audio_regs->csr = (audio_regs->csr & 0xffff0000) | AUDIO_CSR_IRQ_PCM_AEMPTY;	/* clear all conditions and enable interrupt */
	mach_set_int_handler(INT_NO_AUDIO, audio_interrupt_handler_playstation);
	mach_int_ena(1 << INT_NO_AUDIO);
	/* configure and enable pcm */
	audio_regs->pcm_cfg = PCM_CFG_ENABLE | PCM_CFG_DIV(2175-2) | PCM_CFG_VOLUME(128, 128);
}
void synth_play_xbox(void){
	pcm_fill_xbox();
	audio_regs->csr = (audio_regs->csr & 0xffff0000) | AUDIO_CSR_IRQ_PCM_AEMPTY;	/* clear all conditions and enable interrupt */
	mach_set_int_handler(INT_NO_AUDIO, audio_interrupt_handler_xbox);
	mach_int_ena(1 << INT_NO_AUDIO);
	/* configure and enable pcm */
	audio_regs->pcm_cfg = PCM_CFG_ENABLE | PCM_CFG_DIV(2175-2) | PCM_CFG_VOLUME(128, 128);
}

// PCM sample-playing apparatus



// Switch functions
static  uint16_t *p_switch = (void*)&_binary_switch_raw_start;
void pcm_fill_switch(void)
{
	uint16_t *e = (void*)&_binary_switch_raw_end;

	int n = e - p_switch;
	while (n) {
		/* Check for AFULL */
		if (audio_regs->csr & AUDIO_CSR_PCM_AFULL)
			break;
		/* Fill up to 32 samples */
		for (int i=0; i<32 && n; i++,n--)
			audio_regs->pcm_data = *p_switch++;
	}
	if (n == 0){
		audio_regs->csr &= ~(PCM_CFG_ENABLE);
		mach_int_dis(1 << INT_NO_AUDIO);
	}
}


	static mach_int_frame_t *
audio_interrupt_handler_switch(mach_int_frame_t *frame, int int_no)
{
	uint32_t csr;
	csr = audio_regs->csr;
	if (csr & AUDIO_CSR_PCM_UNDERFLOW) {
		audio_regs->csr = AUDIO_CSR_PCM_UNDERFLOW;
		printf("Underflow\n");
	}
	if (csr & AUDIO_CSR_PCM_EMPTY)
		printf("Empty\n");
	if (csr & AUDIO_CSR_PCM_AEMPTY)
		pcm_fill_switch();
	return frame;
}


// SEGA functions

static  uint16_t *p_sega = (void*)&_binary_sega_raw_start;
void pcm_fill_sega(void)
{
	uint16_t *e = (void*)&_binary_sega_raw_end;

	int n = e - p_sega;
	while (n) {
		/* Check for AFULL */
		if (audio_regs->csr & AUDIO_CSR_PCM_AFULL)
			break;
		/* Fill up to 32 samples */
		for (int i=0; i<32 && n; i++,n--)
			audio_regs->pcm_data = *p_sega++;
	}
	if (n == 0){
		audio_regs->csr &= ~(PCM_CFG_ENABLE);
		mach_int_dis(1 << INT_NO_AUDIO);
	}
}


	static mach_int_frame_t *
audio_interrupt_handler_sega(mach_int_frame_t *frame, int int_no)
{
	uint32_t csr;
	csr = audio_regs->csr;
	if (csr & AUDIO_CSR_PCM_UNDERFLOW) {
		audio_regs->csr = AUDIO_CSR_PCM_UNDERFLOW;
		printf("Underflow\n");
	}
	if (csr & AUDIO_CSR_PCM_EMPTY)
		printf("Empty\n");
	if (csr & AUDIO_CSR_PCM_AEMPTY)
		pcm_fill_sega();
	return frame;
}

// playstation functions

static  uint16_t *p_playstation = (void*)&_binary_playstation_raw_start;
void pcm_fill_playstation(void)
{
	uint16_t *e = (void*)&_binary_playstation_raw_end;

	int n = e - p_playstation;
	while (n) {
		/* Check for AFULL */
		if (audio_regs->csr & AUDIO_CSR_PCM_AFULL)
			break;
		/* Fill up to 32 samples */
		for (int i=0; i<32 && n; i++,n--)
			audio_regs->pcm_data = *p_playstation++;
	}
	if (n == 0){
		audio_regs->csr &= ~(PCM_CFG_ENABLE);
		mach_int_dis(1 << INT_NO_AUDIO);
	}
}


	static mach_int_frame_t *
audio_interrupt_handler_playstation(mach_int_frame_t *frame, int int_no)
{
	uint32_t csr;
	csr = audio_regs->csr;
	if (csr & AUDIO_CSR_PCM_UNDERFLOW) {
		audio_regs->csr = AUDIO_CSR_PCM_UNDERFLOW;
		printf("Underflow\n");
	}
	if (csr & AUDIO_CSR_PCM_EMPTY)
		printf("Empty\n");
	if (csr & AUDIO_CSR_PCM_AEMPTY)
		pcm_fill_playstation();
	return frame;
}


// xbox functions

static  uint16_t *p_xbox = (void*)&_binary_xbox_raw_start;
void pcm_fill_xbox(void)
{
	uint16_t *e = (void*)&_binary_xbox_raw_end;

	int n = e - p_xbox;
	while (n) {
		/* Check for AFULL */
		if (audio_regs->csr & AUDIO_CSR_PCM_AFULL)
			break;
		/* Fill up to 32 samples */
		for (int i=0; i<32 && n; i++,n--)
			audio_regs->pcm_data = *p_xbox++;
	}
	if (n == 0){
		audio_regs->csr &= ~(PCM_CFG_ENABLE);
		mach_int_dis(1 << INT_NO_AUDIO);
	}
}


	static mach_int_frame_t *
audio_interrupt_handler_xbox(mach_int_frame_t *frame, int int_no)
{
	uint32_t csr;
	csr = audio_regs->csr;
	if (csr & AUDIO_CSR_PCM_UNDERFLOW) {
		audio_regs->csr = AUDIO_CSR_PCM_UNDERFLOW;
		printf("Underflow\n");
	}
	if (csr & AUDIO_CSR_PCM_EMPTY)
		printf("Empty\n");
	if (csr & AUDIO_CSR_PCM_AEMPTY)
		pcm_fill_xbox();
	return frame;
}


