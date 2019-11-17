#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "libsynth.h"

#include "mach_defines.h"
#include "sdk.h"
#include "gfx_load.h"
#include "cache.h"
#include "main.h"
#include "badgetime.h"

extern char _binary_bgnd_png_start;
extern char _binary_bgnd_png_end;

extern char _binary_doom_raw_start;
extern char _binary_doom_raw_end;

extern char _binary_tilemap_tmx_start;
extern char _binary_tilemap_tmx_end;

//Pointer to the framebuffer memory.
uint8_t *fbmem;

#define FB_WIDTH 512
#define FB_HEIGHT 320


//Wait until all buttons are released
static inline void __button_wait_for_release() {
	while (MISC_REG(MISC_BTN_REG));
}

// AUDIO PLAYBACK

void synth_play_doom(void){
	pcm_fill_doom();
	audio_regs->csr = (audio_regs->csr & 0xffff0000) | AUDIO_CSR_IRQ_PCM_AEMPTY;	/* clear all conditions and enable interrupt */
	mach_set_int_handler(INT_NO_AUDIO, audio_interrupt_handler_doom);
	mach_int_ena(1 << INT_NO_AUDIO);
	/* configure and enable pcm */
	audio_regs->pcm_cfg = PCM_CFG_ENABLE | PCM_CFG_DIV(2175-2) | PCM_CFG_VOLUME(127, 127);
}

// Switch functions
static  uint16_t *p_doom = (void*)&_binary_doom_raw_start;
void pcm_fill_doom(void)
{
	uint16_t *e = (void*)&_binary_doom_raw_end;

	int n = e - p_doom;
	while (n) {
		/* Check for AFULL */
		if (audio_regs->csr & AUDIO_CSR_PCM_AFULL)
			break;
		/* Fill up to 32 samples */
		for (int i=0; i<32 && n; i++,n--)
			audio_regs->pcm_data = *p_doom++;
	}
	if (n == 0){
		audio_regs->csr &= ~(PCM_CFG_ENABLE);
		mach_int_dis(1 << INT_NO_AUDIO);
	}
}

	static mach_int_frame_t *
audio_interrupt_handler_doom(mach_int_frame_t *frame, int int_no)
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
		pcm_fill_doom();
	return frame;
}


void main(int argc, char **argv) {
	//We're running in app context. We have full control over the badge and can do with the hardware what we want. As
	//soon as main() returns, however, we will go back to the IPL.
	
	//Blank out fb while we're loading stuff by disabling all layers. This just shows the background color.
	GFX_REG(GFX_BGNDCOL_REG) = 0x202020; //a soft gray
	GFX_REG(GFX_LAYEREN_REG) = 0; //disable all gfx layers
	
	//First, allocate some memory for the background framebuffer. We're gonna dump a fancy image into it. The image is
	//going to be 8-bit, so we allocate 1 byte per pixel.
	fbmem = calloc(FB_WIDTH,FB_HEIGHT);
	
	//Tell the GFX hardware to use this, and its pitch. We also tell the GFX hardware to use palette entries starting
	//from 128 for the frame buffer; the tiles left by the IPL will use palette entries 0-16 already.
	GFX_REG(GFX_FBPITCH_REG) = (128 << GFX_FBPITCH_PAL_OFF) | (FB_WIDTH << GFX_FBPITCH_PITCH_OFF);
	//Set up the framebuffer address
	GFX_REG(GFX_FBADDR_REG) = ((uint32_t) fbmem);

	//Now, use a library function to load the image into the framebuffer memory. This function will also set up the palette entries,
	//we tell it to start writing from entry 128.
	int png_size = (&_binary_bgnd_png_end - &_binary_bgnd_png_start);
	int i = gfx_load_fb_mem(fbmem, &GFXPAL[128], 8, FB_WIDTH, &_binary_bgnd_png_start, png_size);
	if (i) printf("gfx_load_fb_mem: error %d\n", i);

	//Flush the memory region to psram so the GFX hw can stream it from there.
	cache_flush(fbmem, fbmem+FB_WIDTH*FB_HEIGHT);

	__button_wait_for_release();

	//The user can still see nothing of this graphics goodness, so let's re-enable the framebuffer and
	//tile layer A (the default layer for the console). Also indicate the framebuffer we have is
	//8-bit.
	GFX_REG(GFX_LAYEREN_REG) = GFX_LAYEREN_FB_8BIT | GFX_LAYEREN_FB;

	synth_play_doom();
	wait_for_button_press(BUTTON_A);
}
