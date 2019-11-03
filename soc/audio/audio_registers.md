## The Plan

The idea is to make the presets fairly useable/playable.  Hopefully most will be able to use the synth out of the box.

Voices 1 and 2 are sawtooths.  I like 'em for basses, but whatever.
Voices 3 and 4 are pulse waves with a suboctave added in for extra flavor. Good for leads.
Voices 5-8 are mellow triangle voices, good for chords.
Drums are Kick, Snare, a noisy hat/cymbal, and a cheesy Cowbell.  
Finally, there is a raw PCM channel which takes 14-bit samples at whatever speed you send 'em.

Inputs from userland will be the MIDI note/pitch and a gate duration for the note.
Simply put the note/duration data in the corresponding register and it goes.  
Note that if you select a long release, it will "spill over" the time that you've selected as duration -- it's the time that you're holding down the key on a keyboard.  

This general layout should be kinda musical, make it easy to write a MIDI player or tracker (todo!), and generally be fun.  

A lightweight overlayer in the IPL could make this even more accessible.  We'll see what happens.

Configurables include attack and release on the amplitude envelope.

This should probably combine with a timer / sequencer to play the notes.  

## Layout: 

* 80000000 Voice 0 : Sawtooth
* 80001000 Voice 1 : Sawtooth
* 80002000 Voice 2 : Pulse + Sub
* 80003000 Voice 3 : Pulse + Sub
* 80004000 Voice 4 : Triangle
 ...
* 8000C000 Raw PCM input: 14-bit samples, but hit it with whatever you got
  Sample rate is determined by whatever you push in, 

* 8000D000 Drums  (yes, I'm picking the register addresses to be mnemonic)
  Bits: Kick drum, Snare, Hat/Cymbal, Cowbell

* 8000F000 Config register

## Registers per Voice  (six-bit addresses?)

Offsets:

0. Note and duration.  Low 8 bits are MIDI note 0-127 (yes, it's a 7 bit number).  Bit 8 is gate -- useful.  High 16 bits are the duration in clocks.   

1. Attack and release.  Both in range 0-255.  (8 bits each, oh the waste of address space!)  Figure out what's relevant for drums here.

2. Detune and filter cutoff. Misc voice parameters? (TBD, if space allows.  Might use detune to control pulse width of the pulse...)  Ditto on drums.

3. TBD, reserved, not for production use, dragons.


## Config

Tempo, something else?  I don't know what should go here.  
Maybe implement an overall filter like the SID did?  

