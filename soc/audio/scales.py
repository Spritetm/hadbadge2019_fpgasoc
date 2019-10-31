
##  Ah screw it.  When the SoC is up and running, I'll be using a 48 MHz clock
##  anyway...

## probably should make a MIDI note number to pitch lookup table someday:
def midi_to_pitch(midi_note_number):
    return 440 * 2**((midi_note_number-69.0)/12.0)

def increment(m, bit_depth, bit_fraction, sample_freq):
    return midi_to_pitch(m) * 2**(bit_depth + bit_fraction)/sample_freq*2.0

freqs = [midi_to_pitch(x) for x in range(21,109)]
pitches = [increment(x, 14, 6, 31250) for x in range(21,109)]

import sys

if False:
    sys.stdout = open("scales.v", "w+")

    print "// Automatically generated from scales.py"
    print "module scales ("
    print "input clk,"
    print "input [6:0] midi_note,"
    print "output reg [16:0] increment"
    print ");"

    print "always @(posedge clk) begin\n\tcase (midi_note)"
    for i, pitch in enumerate(pitches):
        print "%i: increment <= %i; // f = %f" % (21+i, round(pitch), freqs[i])
    print "endcase"
    print "end"
    print "endmodule"

sys.stdout = open("scales.hex", "w+")
for i in range(128):
    inc = int(round(increment(i, 14, 6, 31250)))
    print "{:04x}".format(inc)

