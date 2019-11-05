## The Plan

The idea is to make the presets fairly useable/playable.  Hopefully most will be able to use the synth out of the box.

Voices 1 and 2 are sawtooths.  I like 'em for basses, but whatever.
Voices 3 and 4 are pulse waves with a suboctave added in for extra flavor. Good for leads.
Voices 5-8 are mellow triangle voices, good for chords.
Drums are Kick, Snare, a noisy hat/cymbal, and a cheesy Cowbell.  
Finally, there is a raw PCM channel that takes 16-bit samples at whatever speed you send 'em.

You can configure an attack and release rate for each voice independently, and then play it by sending it a pitch increment (scale: TBD) and a duration.  A lookup or formula in the IPL should take care of turning this into pitches for the user, and the durations are approximately 180 counts for a quarter note at 120 BPM.

But the user experience should be `synth_play(voice, note, duration);`  You just have to fire these off at the right time, and you have music.

Note that if you have configured the voice for a long release, it will "spill over" the time that you've selected as duration -- the duration is like the time that you're holding down the key on a keyboard -- it rings out a bit after that.  

This general layout should be kinda musical, make it easy to write a MIDI player or tracker (todo!), and generally be fun. How would it be easiest to write a tracker?  What can I do to support that?


## Layout: 

* 80000000 Voice 0 : Sawtooth
* 80000010 Voice 1 : Sawtooth
* 80000020 Voice 2 : Pulse + Sub
* 80000030 Voice 3 : Square
* 80000040 Voice 4 : Triangle
* 80000050 Voice 5 : Triangle
* 80000060 Voice 6 : Triangle
* 80000070 Voice 7 : Triangle


* 800000C0 Raw PCM input: 14-bit samples, but hit it with whatever you got
  Sample rate is determined by whatever you push in, 

* 800000D0 Drums  (Still TBD) Bits: Kick drum, Snare, Hat/Cymbal, Cowbell

* 800000F0 Config register

## Voice Registers 

Sawtooths are fun to detune and phase against each other.  Plus a nice fat bass is sick. The pulse/sub is a great solo voice.  You always need a square.  It just sounds chip-tuney.  And then the four voices of triangles are for nice backing chords.  Try 'em all out!

Replace V with the voice number.

0. @0x800000V0: 0xDDDDPPPP    Pitch accumulator and duration.  Low 16 bits are the pitch.  High 16 bits is the gate-on time in clicks, which are 2^15/48MHz = 0.68266667 ms 
   180 counts is about a quarter note at 120 BPM, which gives you 90-count eighths, and 45-count sixteenths, etc.  You're still responsible for the timing...

1. @0x800000V4: 0x0000RRAA  Attack and release are both 0-255, and fit in low 16 bits. (Figure out what's relevant for drums when I get there.)

2. @0x800000V8: Filter parameters. Misc voice parameters? (All TBD, if space allows.  Might use detune to control pulse width of the pulse...)  Ditto on drums.

3. @0x800000VC: Nothing yet.

OK, so that's a ton of space left over, but what you gonna do?  Better too much space for parameters than too little.  The cost is two extra wires, virtually nil.  And it just feels so _luxurious_.

## PCM Register (0hC0)

0x0000PPPP: This just takes 16-bit data, mixes it with the synth voices, and sends it off to the DAC.  It's mixed in kinda loud with respect to the other synth voices which come in at 14 bits, but you often play multiple synth voices. If it's distorting, try turning the master volume down from 0x8000, the default.

## Config

0. @0x800000F0: 0xTTTTVVVV Controls master tempo and volume.  

1. @0x800000F4: 0x0000FFFF : This may eventually be a master lowpass filter, like the SID has. FFFF will be the cutoff.


