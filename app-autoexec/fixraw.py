import sys
import struct

RAMPLENGTH = 1000

samples = []
with open(sys.argv[1], "rb") as f:
    while True:
        data = f.read(2)
        if not data: break
        s = int(struct.unpack("<h", data)[0])
        samples.append(s)


# Even out to 32-bits
while (not (len(samples)/2 == round(len(samples)/2))):
    samples.append(0)

# Add (linear, but whatever) volume taper to beginning and end
for i in range(RAMPLENGTH):
    end = len(samples)-1
    frontramp = i / RAMPLENGTH
    backramp = (RAMPLENGTH-i) / RAMPLENGTH
    samples[i] = round(frontramp * samples[i] - 2**15 * (1-frontramp))
    samples[end-i] = round(samples[end-i] * (1-backramp)  - 2**15 * backramp)

# back to bytes and write it out
with open("test.raw", "wb") as f:
    for sample in samples:
        s = struct.pack("<h", sample)
        f.write(s)




