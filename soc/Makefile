-include ../local-settings.mk
#Badge version. Green (unused) is 1, red is 2, blue is 3, prod (black) is 4
BADGE_VER ?= 2
PROJ=soc
SRC=soc.v picorv32/picorv32.v simpleuart.v lcdiface.v qpi_cache/qpimem_cache.v 
SRC+=qpi_cache/qpimem_iface.v qpi_cache/simple_mem.v qpi_cache/simple_mem_words.v
SRC+=arbiter.v pcpi_fastmul_dsp.v video/vid_linerenderer.v
SRC+=video/video_mem.v qpi_cache/qpimem_arbiter.v qpi_cache/qpimem_iface_intl.v
SRC+=usb/usb_trans.v usb/usb_ep_buf.v usb/usb_rx_pkt.v usb/usb_phy.v usb/usb.v
SRC+=usb/usb_tx_pkt.v usb/usb_ep_status.v usb/usb_tx_ll.v usb/usb_rx_ll.v usb/usb_crc.v
SRC+=usb/fifo_sync_shift.v usb_soc.v pic/pic_wrapper.v pic/risc16f84_clk2x.v
SRC+=pic/dpram_1kx16.v qpi_cache/qpimem_dma_rdr.v ledctl.v simpleuart_irda.v
SRC+=dsadc.v video/video_alphamixer.v video/vid_spriteeng.v
SRC_SYNTH=pll.v top_fpga.v mul_18x18_ecp5.v hdmi/clk_8_250_125_25.v hdmi/fake_differential.v
SRC_SYNTH+=hdmi/hdmi-encoder.v hdmi/tmds_encoder.v hdmi/vga2dvid.v hdmi/vga.v 
SRC_SYNTH+= video/ram_dp_24x2048_ecp5.v rng.v video/vid_palettemem_ecp5.v
SRC_SYNTH+= video/vid_tilemapmem_ecp5.v video/vid_tilemem_ecp5.v
SRC_SYNTH+= video/vid_sprite_linebuf_ecp5.v video/vid_spritemem_ecp5.v
SRC_SIM=verilator_main.cpp psram_emu.cpp uart_emu.cpp uart_emu_gdb.cpp mul_18x18_sim.v
SRC_SIM+=video/video_renderer.cpp video/lcd_renderer.cpp video/ram_dp_24x2048_sim.v
SRC_SIM+=trellis_io_sim.v video/vid_palettemem_sim.v video/vid_tilemapmem_sim.v 
SRC_SIM+=video/vid_tilemem_sim.v video/vid_sprite_linebuf_sim.v video/vid_spritemem_sim.v
EXTRA_DEPEND=rom_random_seeds0x123456.hex pic/rom_initial.hex
BRAMFILE=rom.hex
CONSTR=$(word $(BADGE_VER), had19_proto1.lpf had19_proto2.lpf had19_proto3.lpf had19_prod.lpf)
TRELLIS=/usr/share/trellis
ifeq ($(OS),Windows_NT)
EXE:=.exe
CHMOD:=echo WINDOWS: Skipping chmod
else
CHMOD:=chmod
endif

#Image read mode: qspi, dual-spi, fast-read
FLASH_MODE=qspi
#Image read freq, in MHz: 2.4, 4.8, 9.7, 19.4, 38.8, 62.0
FLASH_FREQ=38.8 #MHz


all: $(PROJ).svf

$(PROJ).json $(PROJ).blif: $(SRC) $(SRC_SYNTH) $(EXTRA_DEPEND)
	yosys -e ".*(assigned|implicitly).*" \
		-p "read -sv -DBADGE_VER=$(BADGE_VER) -DBADGE_V$(BADGE_VER)=1 $(SRC) $(SRC_SYNTH); \
			  synth_ecp5 -abc9 -top top_fpga -json $(PROJ).json -blif $(PROJ).blif"

%_out_synth.config: %.json clock-constrainsts.py
	nextpnr-ecp5 --json $< --lpf $(CONSTR) --textcfg $@ --45k --package CABGA381 --speed 8  --pre-pack clock-constrainsts.py --seed 37

%_out.config: %_out_synth.config bram_replace/bram_replace$(EXE) rom.hex
	bram_replace/bram_replace$(EXE) -l 8192 -r $< $@ rom.hex

bram_replace/bram_replace:
ifneq ($(OS),Windows_NT)
	make -C bram_replace
endif

#Note: can't generate bit and svf at the same time as some silicon revs of the ECP5 don't seem to accept
#bitstreams with SPI-specific things over JTAG.

%.bit: %_out.config
	ecppack --spimode $(FLASH_MODE) --freq $(FLASH_FREQ) --input $< --bit $@

%.svf: %_out.config
	ecppack --svf-rowsize 100000 --svf $@ --input $<

prog: $(PROJ).svf
	openocd -f ../openocd.cfg -c "init; svf  $<; exit"

flash: $(PROJ).bit
	tinyprog -p $(PROJ).bit -a 0x180000

clean:
	rm -f $(PROJ).json $(PROJ).svf $(PROJ).bit $(PROJ)_out.config
	rm -rf verilator-build
	make -C boot clean
	rm -f rom.hex

verilator: verilator-build/Vsoc ipl boot/ $(EXTRA_DEPEND)
	./verilator-build/Vsoc

verilator-build/Vsoc: $(SRC) $(SRC_SIM) $(BRAMFILE)
	verilator -Iusb -CFLAGS "-ggdb `sdl2-config --cflags`" -LDFLAGS "`sdl2-config --libs`" --assert --trace --Mdir verilator-build -Wno-style -Wno-fatal -cc --top-module soc --exe $(SRC) $(SRC_SIM)
	make OPT_FAST="-O2 -fno-stack-protector" -C verilator-build -f Vsoc.mk

rom.hex: boot/
	make -C boot
ifeq ($(OS),Windows_NT)
	bin2hex.exe boot/rom.bin rom.hex
else
	cat boot/rom.bin | hexdump -v -e '/4 "%08X\n"' > rom.hex
endif

gdb:
	$(RISCV_TOOLCHAIN_PATH)riscv32-unknown-elf-gdb -b 115200 -ex "set debug remote 1" -ex "target remote /dev/ttyUSB0" app/app.elf

pcpi_fastmul_dsp_testbench:
	iverilog -opcpi_fastmul_dsp_testbench.vvp pcpi_fastmul_dsp_testbench.v pcpi_fastmul_dsp.v picorv32/picorv32.v mul_18x18_sim.v
	vvp pcpi_fastmul_dsp_testbench.vvp

pic/rom_initial.hex: pic/rom.asm
	make -C pic rom_initial.hex

ipl:
	make -C ipl

.PHONY: prog clean verilator bram_replace boot/ ipl
.PRECIOUS: $(PROJ).json $(PROJ)_out_synth.config $(PROJ)_out.config

