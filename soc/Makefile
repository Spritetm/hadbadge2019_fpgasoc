PROJ=soc
SRC=soc.v picorv32/picorv32.v simpleuart.v base_mem.v lcdiface.v
SRC_SYNTH=pll.v
SRC_SIM=pll_sim.v
EXTRA_DEPEND=rom.hex
CONSTR=had19_proto1.lpf
TRELLIS=/usr/share/trellis

all: $(PROJ).svf

$(PROJ).json: $(SRC) $(SRC_SYNTH) $(EXTRA_DEPEND)
	yosys -p "synth_ecp5 -top soc -json $@" $(SRC) $(SRC_SYNTH)

%_out.config: %.json
	nextpnr-ecp5 --json $< --lpf $(CONSTR) --textcfg $@ --um-45k --package CABGA381 --speed 8  --freq 48

%.bit: %_out.config
	ecppack --svf-rowsize 100000 --svf $(PROJ).svf --input $< --bit $@

$(PROJ).svf: $(PROJ).bit

prog: $(PROJ).svf
	openocd -f ../openocd.cfg -c "init; svf  $<; exit"

clean:
	rm -f $(PROJ).json $(PROJ).svf $(PROJ).bit $(PROJ)_out.config
	rm -rf verilator-build
	make -C boot clean
	rm -f rom.hex

verilator: verilator-build/Vsoc $(EXTRA_DEPEND)
	./verilator-build/Vsoc

verilator-build/Vsoc: $(SRC) $(SRC_SIM) verilator_main.cpp
	verilator --trace --Mdir verilator-build -Wno-style -Wno-fatal -cc --top-module soc --exe $(SRC) $(SRC_SIM) verilator_main.cpp
	make OPT_FAST="-O2 -fno-stack-protector" -C verilator-build -f Vsoc.mk

rom.hex: boot/
	make -C boot
	cat boot/rom.bin | hexdump -v -e '/4 "%08X\n"' > rom.hex

.PHONY: prog clean verilator
.PRECIOUS: $(PROJ).json $(PROJ)_out.config

