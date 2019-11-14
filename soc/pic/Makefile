
rom_initial.hex: rom.bin
	cat $^ | hexdump -v -e '/2 "%04X\n"' | head -n 1024 > $@

rom.bin: LEDctrl.o
	gplink -o rom -m -s /usr/share/gputils/lkr/16f84a_g.lkr $^
	objcopy --input-target=ihex --output-target=binary rom.hex $@

LEDctrl.o: LEDctrl.asm macros.inc
	gpasm -e ON -c $< --mpasm-compatible

verilator: verilator-build/Vpic_wrapper
	./verilator-build/Vpic_wrapper

verilator-build/Vpic_wrapper: pic_wrapper.v risc16f84_clk2x.v pic_progmem_sim.v pic_datamem_sim.v \
			verilator_main.cpp rom_initial.hex
	verilator -CFLAGS "-ggdb" --assert --trace --Mdir verilator-build -Wno-style -Wno-fatal -cc --top-module pic_wrapper --exe pic_wrapper.v risc16f84_clk2x.v verilator_main.cpp
	make OPT_FAST="-O2 -fno-stack-protector" -C verilator-build -f Vpic_wrapper.mk

clean:
	rm rom.coff rom.bin rom_initial.hex rom.cod rom.lst
	rm -rf verilator-build

.PHONY: clean