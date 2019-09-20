PROJ=blinky
CONSTR=had19_proto3.lpf
TRELLIS=/usr/share/trellis

#Image read mode: qspi, dual-spi, fast-read
FLASH_MODE=qspi
#Image read freq, in MHz: 2.4, 4.8, 9.7, 19.4, 38.8, 62.0
FLASH_FREQ=38.8 #MHz

all: ${PROJ}.svf

%.json: %.v
	yosys -p "synth_ecp5 -json $@" $<

%_out.config: %.json
	nextpnr-ecp5 --json $< --lpf ${CONSTR} --textcfg $@ --45k --package CABGA381 --speed 8

%.bit: %_out.config
	ecppack --spimode $(FLASH_MODE) --freq $(FLASH_FREQ) --svf-rowsize 100000 --svf ${PROJ}.svf --input $< --bit $@

${PROJ}.svf: ${PROJ}.bit

prog: ${PROJ}.svf
	openocd -f ../openocd.cfg -c "init; svf  $<; exit"

flash: $(PROJ).bit
	tinyprog -p $(PROJ).bit -a 0x0

flash_trigger:
	tinyprog -p trigger.bin -a 0x17f000

clean:
	rm -f ${PROJ}.json ${PROJ}.svf ${PROJ}.bit ${PROJ}_out.config

.PHONY: prog clean
.PRECIOUS: ${PROJ}.json ${PROJ}_out.config

