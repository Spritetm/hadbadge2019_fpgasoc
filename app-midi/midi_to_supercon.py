#! /usr/bin/env python3

## Translates a standard MIDI file into a header file suitable for including in
## programs on the Supercon badge.  

import mido
import sys

###  (@_@)   Add a way to remove tracks that are percussion that we can't do?

## Tweak these to your liking
# FILE              = 'Tetris-Theme_A_by_Gori_Fater.mid'
# HEADERNAME        = "tetris"
FILE              = sys.argv[1]
HEADERNAME        = sys.argv[2]
OUTFILE           = FILE[:-4] + ".h"

MAXVOICES         = 8
NONOTE            = 255 ## higher than the highest valid MIDI note
DEBUG             = False
TICKS_PER_QUARTER = 480  # like Yamaha sequencers

##  GO!

m = mido.MidiFile(FILE)

print(m.filename)
print("Length: " + str(m.length) + " seconds")
ticks_per_quarter = m.ticks_per_beat

## First, strip off the non-note data.  We won't use it.
def is_note(msg):
    if msg.type == "note_on" or msg.type == "note_off":
        answer = True
    else:
        answer = False
    return answer

def is_note_off(msg):
    if msg.type == "note_off" or (msg.type == "note_on" and msg.velocity == 0):
        answer = True
    else:
        answer = False
    return answer

def is_note_on(msg):
    if msg.type == "note_on" and msg.velocity > 0:
        answer = True
    else:
        answer = False
    return answer
## Next, get a feel for how many instruments there are in the track, and how
## voices per instrument they play.  You will need this to set up our synth.

## Count number of notes on at once
def num_notes(track):
    voice_count = 0
    max_voices = 0
    for msg in track: 
        if is_note_on(msg):
            voice_count = voice_count + 1
        if is_note_off(msg): 
            voice_count = voice_count - 1
        if voice_count > max_voices:
            max_voices = voice_count
    return max_voices

voices = []
for i, track in enumerate(m.tracks):
    nnotes = num_notes(track)
    voices.append(nnotes)
    print("Track {}: {} notes: {}".format(i, nnotes, track.name))

if sum(voices) > MAXVOICES:
    print("Too many simultaneous notes.  You have some hard choices to make, friend.")
## At this point, the file will create data for you of the format:
##   timedelta, note0, note1, note2, ...
## for all note events in the midi file

has_notes = []
for track in m.tracks:
    this_track = [x for x in track if is_note(x)]
    if len(this_track) > 0:
        has_notes.append(this_track)
voices = [num_notes(x) for x in has_notes]

## We also know that track 1 needs 3 voices, track 2 needs 2, etc.  
sequence = []
voice_offset = 0
for num_voices,track in zip(voices, has_notes):  
    parsed_track = []
    voice_notes = [None for x in range(num_voices)]  # keep track of state
    time = 0
    active_voice = 0 
    step = 0
    ## start parsing
    for event in track:
        step = step + 1 # just for fun
        track_event = {}
        #  {"time":0, 'note':None, 'noteon':False, 'voice':None}
        time = time + event.time
        track_event['time'] = time
        if DEBUG and step < 20:
            print(event)
        if is_note_on(event):
            track_event['voice'] = voice_offset + active_voice
            track_event['on'] = 1
            track_event['note'] = event.note
            ## update internal voice state 
            voice_notes[active_voice] = event.note
            ## advance voice for next one
            active_voice = (active_voice + 1) % num_voices 
        if is_note_off(event):
            try:
                which_voice = voice_notes.index(event.note)
                track_event['voice'] = voice_offset + which_voice
                track_event['on'] = 0
                track_event['note'] = None
                voice_notes[which_voice] = None
            except ValueError:
                if DEBUG:
                    print ("found note off that wasn't on")
        if 'voice' in track_event.keys():  # only when parsed
            parsed_track.append(track_event)
    sequence.append(parsed_track)
    voice_offset = voice_offset + num_voices

  
def notes_left(v):
    totalnotes = sum([x for x in [len(y) for y in v]])
    return totalnotes

def which_min(a):
    return a.index(min(a))
          
## Interleave and reconvert to time deltas
merged_events = []
current_time = 0
step = 0
while (notes_left(sequence)):
    step = step + 1
    event = {}

    ## handle empty track: drop it
    while any([len(x)==0 for x in sequence]):
        sequence.pop([len(x) for x in sequence].index(0))

    first_times = [x[0]["time"] for x in sequence]
    first_time = min(first_times)
    which_first = first_times.index(first_time)

    # diagnostic
    if DEBUG and step < 20:
        print (current_time)
        print(sequence[which_first][0])

    ## Fix up ticks per beat 
    event["delta"] =  round((first_time - current_time) * TICKS_PER_QUARTER /
            ticks_per_quarter)
    event["voice"] = sequence[which_first][0]["voice"]
    if sequence[which_first][0]['on']:
        event["note"] = sequence[which_first][0]["note"]
    else:
        event["note"] = 255


    ## Update time and drop event
    merged_events.append(event)
    current_time = first_time 
    foo = sequence[which_first].pop(0)
    # diagnostic
    if DEBUG and step < 20:
        print(event)
        print(current_time)
        print ()



## and write out to header file
w = open(OUTFILE, 'w')
w.write("// {} \n\n".format(m.filename))
voices = []
for i, track in enumerate(m.tracks):
    nnotes = num_notes(track)
    voices.append(nnotes)
    w.write("// Track {}: {} notes: {} \n".format(i, nnotes, track.name))
w.write("\n// Length: {} seconds\n\n".format(m.length))
w.write('uint16_t {} [{}][3] = {{'.format(HEADERNAME, len(merged_events), sum(voices)))
w.write('\n/* time_delta, voice #,  midi note num (255 = note off) */\n')
for entry in merged_events:
    w.write('{} , {}, {},\n'.format(entry["delta"], entry["voice"], entry["note"]))
w.write('};\n')
w.close()


