PROJ=blinky
CONSTR=had19_proto1.lpf
TRELLIS=/usr/share/trellis

all: ${PROJ}.svf

%.json: %.v
	yosys -p "synth_ecp5 -json $@" $<

%_out.config: %.json
	nextpnr-ecp5 --json $< --lpf ${CONSTR} --textcfg $@ --um-45k --package CABGA381 --speed 8

%.bit: %_out.config
	ecppack --svf-rowsize 100000 --svf ${PROJ}.svf --input $< --bit $@

${PROJ}.svf: ${PROJ}.bit

prog: ${PROJ}.svf
	openocd -f ../openocd.cfg -c "init; svf  $<; exit"

clean:
	rm -f ${PROJ}.json ${PROJ}.svf ${PROJ}.bit ${PROJ}_out.config

.PHONY: prog clean
.PRECIOUS: ${PROJ}.json ${PROJ}_out.config

