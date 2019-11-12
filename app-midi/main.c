#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#include "mach_defines.h"
#include "sdk.h"

#include "synth_utils.h"
#include "midi_note_increments.h"
#include "libmidi.h"

// tetris
#include "Tetris-hand_edits.h" 
// mario
#include "Mario-Sheet-Music-Overworld-Main-Theme.h"
// starman
#include "Mario-Sheet-Music-Starman-Theme.h" 
// castlevania
#include "Vampire_Killer_2_nodrums.h"
// metal
#include "mgs_main_theme.h"
// surprise
#include "NeverGonnaGiveYouUpDbmajor.h"

// the name of the data from the include file
#define SONGDATA   mario
#define SONGLENGTH sizeof(SONGDATA)/sizeof(uint16_t)/3

void main(int argc, char **argv)
{
	synth_init(5);

	// This is where you'd configure the voices to fit your song.
	// The init leaves all 8 voices in a pretty generic state.
	// Won't sound good, won't sound horrible.

	uint32_t timebase;
	timebase = time();
	uint8_t button = 0;

	while (1){
		// Ideally you would put this somewhere in your code where it can be polled periodically
		// At least as often as the shortest note.
		midi_play_song( SONGDATA, SONGLENGTH, BPM(420) );

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
