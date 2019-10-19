

# https://en.wikipedia.org/wiki/Piano_key_frequencies
# chromatic scale starting at C4
frequencies = [261.6256, 277.1826, 293.6648, 311.1270, 329.6276, 349.2282, 369.9944, 391.9954, 415.3047, 440.0000, 466.1638, 493.8833]

maxclock = 8000000 / 2 # square waves

print( [round(maxclock / f) for f in frequencies] )
# [15289, 14431, 13621, 12856, 12135, 11454, 10811, 10204, 9631, 9091, 8581, 8099]

maxclock = 8000000 / 600 # 600 step samples DDS
print( [round(maxclock / f) for f in frequencies] )
# [51.0, 48.0, 45.0, 43.0, 40.0, 38.0, 36.0, 34.0, 32.0, 30.0, 29.0, 27.0]
# ok, so that won't work.

maxclock = 8000000 / 64 # 64 samples DDS
print( [round(maxclock / f) for f in frequencies] )
# 478.0, 451.0, 426.0, 402.0, 379.0, 358.0, 338.0, 319.0, 301.0, 284.0, 268.0, 253.0


maxclock = 8000000 # full-speed DDS
print( [round(maxclock / f) for f in frequencies] )
# [30578.0, 28862.0, 27242.0, 25713.0, 24270.0, 22908.0, 21622.0, 20408.0, 19263.0, 18182.0, 17161.0, 16198.0]


## OK, real DDS
# 16 bit DAC, 12 bit tuning
print( [round(f*2**28/maxclock) for f in frequencies] )
[8779, 9301, 9854, 10440, 11060, 11718, 12415, 13153, 13935, 14764, 15642, 16572]

