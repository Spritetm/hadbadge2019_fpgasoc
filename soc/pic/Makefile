
testbench.vvp: rom_initial.hex pic_testbench.v pic_wrapper.v risc16f84_clk2x.v dpram_1kx16.v
	iverilog -o pic_testbench.vvp pic_testbench.v pic_wrapper.v risc16f84_clk2x.v dpram_1kx16.v
	vvp pic_testbench.vvp

rom_initial.hex: rom.bin
	cat $^ | hexdump -v -e '/2 "%04X\n"' | head -n 1024 > $@

rom.bin: rom.o
	gplink -o rom -m -s /usr/share/gputils/lkr/16f84a_g.lkr $^
	objcopy --input-target=ihex --output-target=binary rom.hex $@

rom.o: LEDctrl.asm macros.inc
	gpasm -o rom -c $< --mpasm-compatible


clean:
	rm rom.coff rom.bin rom_initial.hex rom.cod rom.lst

.PHONY: clean