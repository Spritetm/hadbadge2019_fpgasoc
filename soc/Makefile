PROJ=soc
SRC=soc.v picorv32/picorv32.v simpleuart.v lcdiface.v qpi_cache/qpimem_cache.v 
SRC+=qpi_cache/qpimem_iface.v qpi_cache/simple_mem.v qpi_cache/simple_mem_words.v
SRC_SYNTH=pll.v top_fpga.v
SRC_SIM=verilator_main.cpp psram_emu.cpp uart_emu.cpp uart_emu_gdb.cpp
EXTRA_DEPEND=rom_random_seeds0x123456.hex
BRAMFILE=rom.hex
CONSTR=had19_proto1.lpf
TRELLIS=/usr/share/trellis

all: $(PROJ).svf

$(PROJ).json: $(SRC) $(SRC_SYNTH) $(EXTRA_DEPEND)
	yosys -p "synth_ecp5 -top top_fpga -json $@" $(SRC) $(SRC_SYNTH)

%_out_synth.config: %.json
	nextpnr-ecp5 --json $< --lpf $(CONSTR) --textcfg $@ --um-45k --package CABGA381 --speed 8  --freq 48

%_out.config: %_out_synth.config bram_replace/bram_replace
	bram_replace/bram_replace -l 4096 -r $< $@ rom.hex

bram_replace/bram_replace:
	make -C bram_replace

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

verilator-build/Vsoc: $(SRC) $(SRC_SIM)
	verilator -CFLAGS "-ggdb" --trace --Mdir verilator-build -Wno-style -Wno-fatal -cc --top-module soc --exe $(SRC) $(SRC_SIM)
	make OPT_FAST="-O2 -fno-stack-protector" -C verilator-build -f Vsoc.mk

rom.hex: boot/
	make -C boot
	cat boot/rom.bin | hexdump -v -e '/4 "%08X\n"' > rom.hex

.PHONY: prog clean verilator bram_replace
.PRECIOUS: $(PROJ).json $(PROJ)_out_synth.config $(PROJ)_out.config

