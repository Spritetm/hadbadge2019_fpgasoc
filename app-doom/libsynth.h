#pragma once

#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>

#include "mach_defines.h"
#include "mach_interrupt.h"

/* Register definitions */
#define SYNTH_VOICE_CTRL_ENABLE		(1 << 0)
#define SYNTH_VOICE_CTRL_PHASE_ZERO	(1 << 1)
#define SYNTH_VOICE_CTRL_SAWTOOTH	(0 << 2)
#define SYNTH_VOICE_CTRL_TRIANGLE	(1 << 2)
#define SYNTH_VOICE_CTRL_PULSE		(2 << 2)
#define SYNTH_VOICE_CTRL_SUBOCTAVE	(3 << 2)

#define SYNTH_VOICE_CTRL_WT_FWDREV	(1 << 8)
#define SYNTH_VOICE_CTRL_WT_ENABLE	(1 << 7)
#define SYNTH_VOICE_CTRL_WT_BASE(n)	(((n) >> 9) << 4)	/* 512 aligned */
#define SYNTH_VOICE_CTRL_WT_LEN_512	(3 << 2)
#define SYNTH_VOICE_CTRL_WT_LEN_1024	(2 << 2)
#define SYNTH_VOICE_CTRL_WT_LEN_2048	(1 << 2)
#define SYNTH_VOICE_CTRL_WT_LEN_4096	(0 << 2)

#define SYNTH_VOICE_VOLUME(l,r)		(((l)<<8) | (r))

struct synth {
	/* Per-Voice registers */
	struct {
		uint32_t ctrl;
		uint32_t _rsvd;
		uint32_t phase_inc;
		uint32_t phase_cmp;
		uint32_t volume;
		uint32_t duration;
		uint32_t attack;
		uint32_t decay;
	} voice[16];

	/* Global register */
	uint32_t samplerate_div;
	uint32_t volume;
	uint32_t voice_force;
	uint32_t voice_start;
	uint32_t _rsvd[4];

	/* Commands (only valid for queuing !!!) */
	uint32_t cmd_wait;
	uint32_t cmd_gen_event;
} __attribute__((packed,aligned(4)));

// Controls for PCM Audio
#define AUDIO_CSR_PCM_FULL		(1 << 31)
#define AUDIO_CSR_PCM_AFULL		(1 << 30)
#define AUDIO_CSR_PCM_AEMPTY		(1 << 29)
#define AUDIO_CSR_PCM_EMPTY		(1 << 28)

#define AUDIO_CSR_PCM_OVERFLOW		(1 << 27)
#define AUDIO_CSR_PCM_UNDERFLOW		(1 << 26)

#define AUDIO_CSR_SYNTH_CMD_FULL	(1 << 23)
#define AUDIO_CSR_SYNTH_CMD_AFULL	(1 << 22)
#define AUDIO_CSR_SYNTH_CMD_AEMPTY	(1 << 21)
#define AUDIO_CSR_SYNTH_CMD_EMPTY	(1 << 20)

#define AUDIO_CSR_SYNTH_CMD_OVERFLOW	(1 << 19)
#define AUDIO_CSR_SYNTH_EVT_OVERFLOW	(1 << 18)
#define AUDIO_CSR_SYNTH_EVT_FULL	(1 << 17)
#define AUDIO_CSR_SYNTH_EVT_EMPTY	(1 << 16)

#define AUDIO_CSR_IRQ_PCM_AFULL_N	(1 << 15)
#define AUDIO_CSR_IRQ_PCM_AEMPTY	(1 << 14)
#define AUDIO_CSR_IRQ_SYNTH_CMD_AFULL_N	(1 << 13)
#define AUDIO_CSR_IRQ_SYNTH_CMD_AEMPTY	(1 << 12)
#define AUDIO_CSR_IRQ_SYNTH_EVT_EMPTY_N	(1 << 11)

#define AUDIO_CSR_UNFORCE_DC_LEVEL	(1 <<  1)
#define AUDIO_CSR_FORCE_DC_LEVEL	(1 <<  0)

#define SYNTH_EVT_INVALID		(1 << 31)

#define PCM_CFG_ENABLE			(1 << 31)
#define PCM_CFG_DIV(d)			((d) << 16)
#define PCM_CFG_VOLUME(l,r)		(((l) << 8) | (r))

struct audio {
	uint32_t csr;
	uint32_t evt;
	uint32_t pcm_cfg;
	uint32_t pcm_data;
} __attribute__((packed,aligned(4)));

// Use these to change the synthesizer / audio system registers
static volatile struct audio * const audio_regs  = (void*)((AUDIO_CORE_BASE) + 0x00000);
static volatile uint32_t *     const synth_wt    = (void*)((AUDIO_CORE_BASE) + 0x10000);
static volatile struct synth * const synth_now   = (void*)((AUDIO_CORE_BASE) + 0x20000);
static volatile struct synth * const synth_queue = (void*)((AUDIO_CORE_BASE) + 0x30000);

