This directory shows you how to turn a MIDI file into something you can use on the badge.

## Background

The badge has a built-in rudimentary synthesizer, and it's pretty easy to write a music player for it.  You'll need source material, but for that, there's the entire library of all music ever out there on the Interwebs, saved in Standard MIDI Format.  Then you need to translate it into something that our little synth understands.

That's where this demo comes in.  

## Prerequisites

You'll need Python, and then to install the "mido" MIDI library.  `pip install mido` did it for me.

## TODO:

The synth queuing infrastructure is great, and would be a perfect match for MIDI playback.  

Two things need doing:  

1) MIDI delays need to be converted into queue delays

2) There needs to be an interrupt-driven method to refill the queue when it's empty, b/c only the simplest songs will fit in whole.  Here be dragons, but it should be doable and useful.  Then a calling program would only need to hammer in MIDI data quite infrequently.    As it stands, it needs to be polled at the interval of the shortest note in the music.


