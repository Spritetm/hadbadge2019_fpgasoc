PROJ=soc
SRC=soc.v picorv32/picorv32.v simpleuart.v lcdiface.v qpi_cache/qpimem_cache.v 
SRC+=qpi_cache/qpimem_iface.v qpi_cache/simple_mem.v qpi_cache/simple_mem_words.v
SRC+=arbiter.v pcpi_fastmul_dsp.v video/vid_linerenderer.v
SRC+=video/video_mem.v qpi_cache/qpimem_arbiter.v
SRC+=usb/usb_trans.v usb/usb_ep_buf.v usb/usb_rx_pkt.v usb/usb_phy.v usb/usb.v
SRC+=usb/usb_tx_pkt.v usb/usb_ep_status.v usb/usb_tx_ll.v usb/usb_rx_ll.v usb/usb_crc.v
SRC+=usb/fifo_sync_shift.v usb_soc.v
SRC_SYNTH=pll.v top_fpga.v mul_18x18_ecp5.v hdmi/clk_8_250_125_25.v hdmi/fake_differential.v
SRC_SYNTH+=hdmi/hdmi-encoder.v hdmi/tmds_encoder.v hdmi/vga2dvid.v hdmi/vga.v 
SRC_SYNTH+= video/ram_dp_24x2048_ecp5.v
SRC_SIM=verilator_main.cpp psram_emu.cpp uart_emu.cpp uart_emu_gdb.cpp mul_18x18_sim.v
SRC_SIM+=video/video_renderer.cpp video/lcd_renderer.cpp video/ram_dp_24x2048_sim.v
SRC_SIM+=trellis_io_sim.v
EXTRA_DEPEND=rom_random_seeds0x123456.hex
BRAMFILE=rom.hex
CONSTR=had19_proto2.lpf
TRELLIS=/usr/share/trellis
#frequency in MHz to use as a goal for the timing calculations
#note: 48MHz actually, but better to be on the safe size.
FREQ=55


#Image read mode: qspi, dual-spi, fast-read
FLASH_MODE=qspi
#Image read freq, in MHz: 2.4, 4.8, 9.7, 19.4, 38.8, 62.0
FLASH_FREQ=38.8 #MHz


all: $(PROJ).svf

$(PROJ).json $(PROJ).blif: $(SRC) $(SRC_SYNTH) $(EXTRA_DEPEND)
	yosys -p "synth_ecp5 -top top_fpga -json $(PROJ).json -blif $(PROJ).blif" $(SRC) $(SRC_SYNTH)

%_out_synth.config: %.json
	nextpnr-ecp5 --json $< --lpf $(CONSTR) --textcfg $@ --45k --package CABGA381 --speed 8  --freq $(FREQ)

%_out.config: %_out_synth.config bram_replace/bram_replace rom.hex
	bram_replace/bram_replace -l 4096 -r $< $@ rom.hex

bram_replace/bram_replace:
	make -C bram_replace

#Note: can't generate bit and svf at the same time as some silicon revs of the ECP5 don't seem to accept
#bitstreams with SPI-specific things over JTAG.

#ToDo: separate
%.bit: %_out.config
	ecppack --svf-rowsize 100000 --spimode $(FLASH_MODE) --freq $(FLASH_FREQ) --svf $(PROJ).svf --input $< --bit $@



$(PROJ).svf: $(PROJ).bit

prog: $(PROJ).svf
	openocd -f ../openocd.cfg -c "init; svf  $<; exit"

flash: $(PROJ).bit
	tinyprog -p $(PROJ).bit -a 0x180000

clean:
	rm -f $(PROJ).json $(PROJ).svf $(PROJ).bit $(PROJ)_out.config
	rm -rf verilator-build
	make -C boot clean
	rm -f rom.hex

verilator-postsyn: verilator-postsyn-build/Vsoc $(EXTRA_DEPEND)
	./verilator-postsyn-build/Vsoc

$(PROJ)-postsyn.json $(PROJ)-postsyn.blif: $(SRC) $(SRC_SYNTH) $(EXTRA_DEPEND)
	yosys -p "synth_ecp5 -top soc -json $(PROJ)-postsyn.json -blif $(PROJ)-postsyn.blif" $(SRC) $(SRC_SYNTH)

$(PROJ)_syn.v: $(PROJ)-postsyn.blif
	yosys -o $@ $^

ECP5_SIM_BASE_DIR := /usr/src/symbiflow-arch-defs/ecp5/
ECP5_SIM_FILES :=  primitives/misc/INV/INV.sim.v primitives/io/OBZ/OBZ.sim.v primitives/io/TRELLIS_IO/TRELLIS_IO.sim.v \
	primitives/io/OB/OB.sim.v primitives/io/IB/IB.sim.v primitives/io/BB/BB.sim.v primitives/slice/TRELLIS_RAM16X2/TRELLIS_RAM16X2.sim.v \
	primitives/slice/LUT4/LUT4.sim.v primitives/slice/LUT2/LUT2.sim.v primitives/slice/DPR16X4C/DPR16X4C.sim.v \
	primitives/slice/TRELLIS_DPR16X4/TRELLIS_DPR16X4.sim.v primitives/slice/TRELLIS_FF/TRELLIS_FF.sim.v primitives/slice/CCU2C/CCU2C.sim.v \
	primitives/slice/PFUMX/PFUMX.sim.v primitives/slice/L6MUX21/L6MUX21.sim.v
ECP5_SIM_EXTRA := $(addprefix $(ECP5_SIM_BASE_DIR),$(ECP5_SIM_FILES)) DP16KD_sim.v

verilator-postsyn-build/Vsoc: $(PROJ)_syn.v $(SRC_SIM) $(BRAMFILE) corr_synth_for_verilator
	verilator -CFLAGS "-ggdb" --trace --Mdir verilator-build -Wno-style -Wno-pinmissing -Wno-fatal \
			-cc --top-module soc --exe $(PROJ)_syn.v $(SRC_SIM) $(ECP5_SIM_EXTRA) 
	make OPT_FAST="-O2 -fno-stack-protector" -C verilator-build -f Vsoc.mk

#	./corr_synth_for_verilator < $(PROJ)_syn.v > $(PROJ)_syn_corr.v 

verilator: verilator-build/Vsoc $(EXTRA_DEPEND)
	./verilator-build/Vsoc

verilator-build/Vsoc: $(SRC) $(SRC_SIM) $(BRAMFILE)
	verilator -Iusb -CFLAGS "-ggdb `sdl2-config --cflags`" -LDFLAGS "`sdl2-config --libs`" --assert --trace --Mdir verilator-build -Wno-style -Wno-fatal -cc --top-module soc --exe $(SRC) $(SRC_SIM)
	make OPT_FAST="-O2 -fno-stack-protector" -C verilator-build -f Vsoc.mk

rom.hex: boot/
	make -C boot
	cat boot/rom.bin | hexdump -v -e '/4 "%08X\n"' > rom.hex

gdb:
	/home/jeroen/hackaday2019/riscv-toolchain/bin/riscv32-unknown-elf-gdb -b 115200 -ex "set debug remote 1" -ex "target remote /dev/ttyUSB0" app/app.elf

corr_synth_for_verilator: corr_synth_for_verilator.c
	gcc -o corr_synth_for_verilator corr_synth_for_verilator.c

pcpi_fastmul_dsp_testbench:
	iverilog -opcpi_fastmul_dsp_testbench.vvp pcpi_fastmul_dsp_testbench.v pcpi_fastmul_dsp.v picorv32/picorv32.v mul_18x18_sim.v
	vvp pcpi_fastmul_dsp_testbench.vvp


.PHONY: prog clean verilator bram_replace boot/
.PRECIOUS: $(PROJ).json $(PROJ)_out_synth.config $(PROJ)_out.config

