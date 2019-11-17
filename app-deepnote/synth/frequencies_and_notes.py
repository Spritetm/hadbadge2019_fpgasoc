## Figuring out a good integer lookup from pitch to accumulator increment
## In principle, we have 
## a 48,000 Hz sample clock
## and 14-bit samples with a 5-bit fixed point fraction = 19 bit denom

## k = accumulator depth / sampling rate

def pitch_increment(freq):
    p =  2.0**19 * freq  / 48000    
    return p

def midi_note_to_pitch(n):
    pitch = 440 * 2**((n-69)/12.0)
    return pitch


notes = ["A", "A#" , "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"]

w = open("midi_note_increments.c", "w")

w.write('#include <stdint.h>\n')
w.write("uint32_t midi_table [128] = {\n")
for note in range(0,128):
    increment = round(pitch_increment(midi_note_to_pitch(note)))
    # note names start with A, but octave numbers switch on C
    notename = notes[(note-21)%12] + str(int((note-12)/12)) 
    comment = "/* " + str(int(note)) + " - " + notename + " */\n"
    w.write(str(increment) + ", " + comment )
w.write("};\n")


