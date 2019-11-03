## The Plan

The idea is to make the presets fairly useable/playable.  Hopefully most will be able to use the synth out of the box.

Voices 1 and 2 are sawtooths.  I like 'em for basses, but whatever.
Voices 3 and 4 are pulse waves with a suboctave added in for extra flavor. Good for leads.
Voices 5-8 are mellow triangle voices, good for chords.
Drums are Kick, Snare, a noisy hat/cymbal, and a cheesy Cowbell.  
Finally, there is a raw PCM channel which takes 14-bit samples at whatever speed you send 'em.

The oscillators take a pitch increment (scale: TBD) from userland.  A lookup or formula in the IPL should take care of turning this into pitches for the user.
An IPL function should also take care of durations, but I haven't decided yet how to handle that: timer in HW or SW?
But the user experience should be `synth_play(voice, note, duration);`

Note that if you select a long release, it will "spill over" the time that you've selected as duration -- it's the time that you're holding down the key on a keyboard.  

This general layout should be kinda musical, make it easy to write a MIDI player or tracker (todo!), and generally be fun. How would it be easiest to write a tracker?  What can I do to support that?

Configurables include attack and release on the amplitude envelope.  IPL functions for these will need to be written, once the configurable hardware gets done.


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

0. Pitch accumulator and duration.  Low 16 bits are the pitch.  High 16 bits are the duration in clocks.   (Do I need to squish a gate in here?)

1. Attack and release.  Both in range 0-255.  (8 bits each, oh the waste of address space!)  Figure out what's relevant for drums here.  Still have  16 bits free?

2. Detune and filter cutoff. Misc voice parameters? (TBD, if space allows.  Might use detune to control pulse width of the pulse...)  Ditto on drums.

3. TBD, reserved, not for production use, dragons.

(Better too much space for parameters than too little?  The cost is two extra wires.)

## Config

Tempo, something else?  I don't know what should go here.  
Maybe implement an overall filter like the SID did?  

