

# https://en.wikipedia.org/wiki/Piano_key_frequencies
# chromatic scale starting at C3
frequencies = [261.6256, 277.1826, 293.6648, 311.1270, 329.6276, 349.2282, 369.9944, 391.9954, 415.3047, 440.0000, 466.1638, 493.8833]

maxclock = 8000000 / 2

print( [round(maxclock / f) for f in frequencies] )
# [15289, 14431, 13621, 12856, 12135, 11454, 10811, 10204, 9631, 9091, 8581, 8099]
