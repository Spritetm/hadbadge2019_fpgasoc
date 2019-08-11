
testbench.vvp: rom_initial.hex pic_testbench.v pic_wrapper.v risc16f84_clk2x.v
	iverilog -o pic_testbench.vvp pic_testbench.v pic_wrapper.v risc16f84_clk2x.v
	vvp pic_testbench.vvp

rom_initial.hex: rom.bin
	cat $^ | hexdump -v -e '/2 "%04X\n"' > $@

rom.bin: rom.hex
	objcopy --input-target=ihex --output-target=binary $^ $@

rom.hex: rom.asm
	gpasm $^