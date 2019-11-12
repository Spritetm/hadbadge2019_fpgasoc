#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "mach_defines.h"
#include "sdk.h"

#include "synth_utils.h"
#include "midi_note_increments.h"
#include "libmidi.h"


/// CHANGEME!!!!!
#define CASTLEVANIA

#ifdef MARIO
// mario
#include "Mario-Sheet-Music-Overworld-Main-Theme.h"
#define SONGDATA   mario
#define TEMPO      380
#endif

#ifdef STARMAN
// starman
#include "Mario-Sheet-Music-Starman-Theme.h" 
#define SONGDATA   starman
#define TEMPO      280
#endif

#ifdef CASTLEVANIA
// castlevania
#include "Vampire_Killer_2_nodrums.h"
#define SONGDATA   castlevania
#define TEMPO      120
#endif

#ifdef METAL
// metal
#include "mgs_main_theme.h"
#define SONGDATA   metal
#define TEMPO      380
#endif

#ifdef SECRET
// secret
#include "NeverGonnaGiveYouUpDbmajor.h"
#define SONGDATA   secret
#define TEMPO      120
#endif

#define SONGLENGTH sizeof(SONGDATA)/sizeof(uint16_t)/3

void main(int argc, char **argv)
{
	synth_init(5);

	// This is where you'd configure the voices to fit your song.
	// The init leaves all 8 voices in a pretty generic state.
	// Won't sound good, won't sound horrible.
#ifdef CASTLEVANIA
	for (uint8_t i = 0; i<2; i++){
		synth_now->voice[i].ctrl     = SYNTH_VOICE_CTRL_ENABLE | SYNTH_VOICE_CTRL_PULSE	;
		synth_now->voice[i].attack   = 0x0080;
		synth_now->voice[i].decay    = 0x0040;
		synth_now->voice[i].volume   = SYNTH_VOICE_VOLUME(64,64);
	}
	synth_now->voice[2].ctrl     = SYNTH_VOICE_CTRL_ENABLE | SYNTH_VOICE_CTRL_TRIANGLE	;
	synth_now->voice[2].attack   = 0x00FF;
	synth_now->voice[2].decay    = 0x0030;
	synth_now->voice[2].volume   = SYNTH_VOICE_VOLUME(255,255);
	for (uint8_t i = 3; i<5; i++){
		synth_now->voice[i].ctrl     = SYNTH_VOICE_CTRL_ENABLE | SYNTH_VOICE_CTRL_SAWTOOTH	;
		synth_now->voice[i].attack   = 0x0040;
		synth_now->voice[i].decay    = 0x0040;
		synth_now->voice[i].volume   = SYNTH_VOICE_VOLUME(64,64);
	}
#endif
#ifdef SECRET
	for (uint8_t i = 0; i<8; i++){
		synth_now->voice[i].volume   = SYNTH_VOICE_VOLUME(128,128);
	}
	for (uint8_t i = 1; i<6; i++){
		synth_now->voice[i].ctrl     = SYNTH_VOICE_CTRL_ENABLE | SYNTH_VOICE_CTRL_TRIANGLE	;
	}

#endif

	uint32_t timebase;
	timebase = time();
	uint8_t button = 0;
	uint32_t steps = 0 ;
	while (steps < SONGLENGTH-1){
		// Ideally you would put this somewhere in your code where it can be polled periodically
		// At least as often as the shortest note.
		steps = midi_play_song( SONGDATA, SONGLENGTH, BPM(TEMPO) );

		// Here, we're just looping until you hit the button.
		// Needs debouncing.  Argh.
		if (time()-timebase >= 2000*MILLIS){
			button = MISC_REG(MISC_BTN_REG);
		}
		if (button) {
			break;
		}
	}
	synth_now->voice_force = 0;
}
