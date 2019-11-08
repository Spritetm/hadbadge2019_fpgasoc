## Figuring out a good integer lookup from pitch to accumulator increment
## In principle, we have 
## a 20 bit accumulator, 
##   48 MHz clock, 
## and 1024 (10-bit) oversampling.

## k = 2.0**(10+20) / (48*10**6)

def pitch_increment(freq):
    p =  2.0**30 * freq  / (48*10**6)    
    return p

def midi_note_to_pitch(n):
    pitch = 440 * 2**((n-69)/12.0)
    return pitch


notes = ["A", "A#" , "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"]

w = open("midi_note_increments.h", "w")
w.write("uint32_t midi_table [128] = {\n")
for note in range(21,109):
    increment = round(pitch_increment(midi_note_to_pitch(note)))
    notename = notes[(note-21)%12] + str(int((note-12)/12))
    comment = "/* " + str(int(note)) + " - " + notename + " */\n"
    w.write(str(increment) + ", " + comment )
w.write("};\n")


