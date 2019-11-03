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
* 80000010 Voice 1 : Sawtooth
* 80000020 Voice 2 : Pulse + Sub
* 80000030 Voice 3 : Pulse + Sub
* 80000040 Voice 4 : Triangle
* ...
* 80000070 Voice 7 : Triangle

* 800000C0 Raw PCM input: 14-bit samples, but hit it with whatever you got
  Sample rate is determined by whatever you push in, 
* 800000D0 Drums  (yes, I'm picking the register addresses to be mnemonic)
  Bits: Kick drum, Snare, Hat/Cymbal, Cowbell
* 800000F0 Config register

## Voice Registers 

0. @0x800000V0: 0xG000PPPP    Pitch accumulator and duration.  Low 16 bits are the pitch.  High 15 bits may eventually be the duration in clocks.  For now the highest bit (31) is a gate.

1. @0x800000V4: 0x0000RRAA  Attack and release fit in low 16 bits, each 8 bit. Figure out what's relevant for drums here.  

2. @0x800000V8: Filter parameters. Misc voice parameters? (All TBD, if space allows.  Might use detune to control pulse width of the pulse...)  Ditto on drums.

3. @0x800000VC: Nothing yet.

OK, so that's a ton of space left over, but what you gonna do?  Better too much space for parameters than too little.  The cost is two extra wires, virtually nil.  And it just feels so _luxurious_.

## PCM Register (0hC0)

This just takes 14-bit data and shuttles it straight off to the PCM channel.  Do what you want with it.
It's mixed in kinda loud with respect to the other synth voices, but that just gives you more flexibility.

## Config

Tempo, something else?  I don't know what should go here.  
Maybe implement an overall filter like the SID did?  

