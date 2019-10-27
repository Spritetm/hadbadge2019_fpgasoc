PROJ=minimal
DUT=voice
INCLUDES=oscillator.v dac.v button_number.v lfsr.v amplifier.v envelope.v
CONSTR=had19_proto2.lpf
TRELLIS=/usr/share/trellis


all: ${PROJ}.svf flash
# all: sim

%.json: %.v ${INCLUDES} 
	yosys -p "synth_ecp5 -json $@" $< 

%_out.config: %.json
	nextpnr-ecp5 --json $< --lpf ${CONSTR} --textcfg $@ --45k --package CABGA381 --speed 8 --seed 42

%.bit: %_out.config
	ecppack --svf-rowsize 100000 --svf ${PROJ}.svf --input $< --bit $@

${PROJ}.svf: ${PROJ}.bit

prog: ${PROJ}.svf
	openocd -f ../openocd.cfg -c "init; svf  $<; exit"

clean:
	rm -f ${PROJ}.json ${PROJ}.svf ${PROJ}.bit ${PROJ}_out.config

flash: ${PROJ}.bit 
	tinyprog -p ${PROJ}.bit -a 0x180000


sim: ${DUT}.v  ${DUT}_tb.v 
	iverilog -Wall -Wno-timescale -o${DUT} ${DUT}.v ${DUT}_tb.v 
	vvp ${DUT}
	# gtkwave dump.vcd config.gtkw 

.PHONY: prog clean
.PRECIOUS: ${PROJ}.json ${PROJ}_out.config

