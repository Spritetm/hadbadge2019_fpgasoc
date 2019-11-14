-include ../local-settings.mk
#Badge version. Green (unused) is 1, red is 2, blue is 3, prod (black) is 4
BADGE_VER ?= 4
#Project name
PROJ=soc
#Seed for nextpnr. Change this to another random value if you happen to run 
#into a situation that mis-synths or takes extremely long to synth the SoC.
SEED = 37

# Sources
	# Base
SRC = \
	arbiter.v \
	dsadc.v \
	dma_writer.v \
	lcdiface.v \
	ledctl.v \
	picorv32/picorv32.v \
	pcpi_fastmul_dsp.v \
	soc.v \
	$(NULL)

SRC_SYNTH = \
	mul_18x18_ecp5.v \
	rng.v \
	sysmgr.v \
	top_fpga.v \
	$(NULL)

SRC_SIM = \
	sim/mul_18x18_sim.v \
	sim/ecp5_io_sim.v \
	psram_emu.cpp \
	uart_emu.cpp \
	uart_emu_gdb.cpp \
	verilator_main.cpp \
	$(NULL)

	# Misc
SRC += $(addprefix misc/, \
	delay.v \
	fifo_sync_ram.v \
	fifo_sync_shift.v \
	glitch_filter.v \
	ram_sdp.v \
)

	# QPI cache
SRC += $(addprefix qpi_cache/, \
	qpimem_arbiter.v \
	qpimem_cache.v \
	qpimem_dma_rdr.v \
	qpimem_iface.v \
	qpimem_iface_intl.v \
	qpimem_iface_2x2w.v \
	qspi_phy_2x_ecp5.v \
	simple_mem.v \
	simple_mem_words.v \
)

	# Video
SRC += $(addprefix video/, \
	vid_linerenderer.v \
	video_mem.v \
	video_alphamixer.v \
	vid_spriteeng.v \
)

SRC_SYNTH += $(addprefix video/, \
	ram_dp_24x2048_ecp5.v \
	vid_palettemem_ecp5.v \
	vid_sprite_linebuf_ecp5.v \
	vid_spritemem_ecp5.v \
	vid_tilemapmem_ecp5.v \
	vid_tilemem_ecp5.v \
	ram_dp_32x2048_ecp5.v \
)

SRC_SIM += $(addprefix video/, \
	lcd_renderer.cpp \
	ram_dp_24x2048_sim.v \
	vid_palettemem_sim.v \
	vid_tilemapmem_sim.v \
	vid_tilemem_sim.v \
	vid_sprite_linebuf_sim.v \
	vid_spritemem_sim.v \
	video_renderer.cpp \
	ram_dp_32x2048_sim.v \
)

	# UART
SRC += $(addprefix uart/, \
	uart_irda_rx.v \
	uart_irda_tx.v \
	uart_rx.v \
	uart_tx.v \
	uart_wb.v \
)

	# USB
SRC += $(addprefix usb/, \
	usb_trans.v \
	usb_ep_buf.v \
	usb_rx_pkt.v \
	usb_phy.v \
	usb.v \
	usb_tx_pkt.v \
	usb_ep_status.v \
	usb_tx_ll.v \
	usb_rx_ll.v \
	usb_crc.v \
)

SRC += usb_soc.v

	# PIC
SRC += $(addprefix pic/, \
	dpram_1kx16.v \
	pic_wrapper.v \
	risc16f84_clk2x.v \
)

SRC_SYNTH += $(addprefix pic/, \
	pic_progmem_ecp5.v \
	pic_datamem_ecp5.v \
)

SRC_SIM += $(addprefix pic/, \
	pic_progmem_sim.v \
	pic_datamem_sim.v \
)

	# Audio
SRC += $(addprefix audio/, \
	audio_mix.v \
	audio_wb.v \
	pdm.v \
	synth_attack_decay.v \
	synth_cfg_reg.v \
	synth_core.v \
	synth_mix.v \
	synth_reg.v \
	synth_rng.v \
)

	# HDMI
SRC_SYNTH += $(addprefix hdmi/, \
	clk_8_250_125_25.v \
	fake_differential.v \
	hdmi-encoder.v \
	tmds_encoder.v \
	vga2dvid.v \
	vga.v \
)

EXTRA_DEPEND=rom_random_seeds0x123456.hex
BRAMFILE=rom.hex
CONSTR=$(word $(BADGE_VER), had19_proto1.lpf had19_proto2.lpf had19_proto3.lpf had19_prod.lpf)
HWDEF=$(word $(BADGE_VER), BADGE_V1 BADGE_V2 BADGE_V3 BADGE_PROD)
TRELLIS=/usr/share/trellis

ifeq ($(OS),Windows_NT)
EXE:=.exe
endif
ifneq ("$(WSL_DISTRO_NAME)","")
	# if using Windows Subsystem for Linux, and yosys not found, try adding .exe
	ifeq (, $(shell which yosys))
		EXE:=.exe
 	endif
endif

#Image read mode: qspi, dual-spi, fast-read
FLASH_MODE=qspi
#Image read freq, in MHz: 2.4, 4.8, 9.7, 19.4, 38.8, 62.0
FLASH_FREQ=38.8 #MHz


all: $(PROJ).svf

$(PROJ).json $(PROJ).blif: $(SRC) $(SRC_SYNTH) $(EXTRA_DEPEND)
	yosys$(EXE) -e ".*(assigned|implicitly).*" -l yosys.log \
		-p "read -sv -DBADGE_VER=$(BADGE_VER) -D$(HWDEF)=1 $(SRC) $(SRC_SYNTH); \
			  synth_ecp5 -abc9 -top top_fpga -json $(PROJ).json -blif $(PROJ).blif"

%_out_synth.config: %.json clock-constrainsts.py
	nextpnr-ecp5$(EXE) --json $< --lpf $(CONSTR) --textcfg $@ --45k --package CABGA381 --speed 8 \
			--pre-pack clock-constrainsts.py -l nextpnr.log --freq 48 --seed $(SEED)

%_out.config: %_out_synth.config rom.hex
	ecpbram -i $< -o $@ -f rom_random_seeds0x123456.hex -t rom.hex

#Note: can't generate bit and svf at the same time as some silicon revs of the ECP5 don't seem to accept
#bitstreams with SPI-specific things over JTAG.

%.bit: %_out.config
	ecppack$(EXE) --spimode $(FLASH_MODE) --freq $(FLASH_FREQ) --input $< --bit $@

%.svf: %_out.config
	ecppack$(EXE) --svf-rowsize 100000 --svf $@ --input $<

prog: $(PROJ).svf
	openocd -f ../openocd.cfg -c "init; svf  $<; exit"

dfu_flash: $(PROJ).bit
	dfu-util$(EXE) -d 1d50:614a,1d50:614b -a 0 -R -D $<

dfu_flash_all: $(PROJ).bit ipl
	dfu-util$(EXE) -d 1d50:614a,1d50:614b -a 0 -D $(PROJ).bit
	dfu-util$(EXE) -d 1d50:614a,1d50:614b -a 1 -D ipl/ipl.bin -R

dfu_flash_all_cart: $(PROJ).bit ipl
	dfu-util$(EXE) -d 1d50:614a,1d50:614b -a 2 -D $(PROJ).bit
	dfu-util$(EXE) -d 1d50:614a,1d50:614b -a 3 -D ipl/ipl.bin -R

clean:
	rm -f $(PROJ).json $(PROJ).svf $(PROJ).bit $(PROJ)_out.config
	rm -rf verilator-build
	$(MAKE) -C boot clean
	rm -f rom.hex

verilator: verilator-build/Vsoc ipl boot/ $(EXTRA_DEPEND)
	./verilator-build/Vsoc

ifeq ("$(VCD)","")
VR_TRACE_OPTS := --trace-fst-thread
VR_TRACE_CFLAGS := -DVERILATOR_USE_FST=1
else
VR_TRACE_OPTS := --trace
VR_TRACE_CFLAGS := -DVERILATOR_USE_VCD=1
endif

verilator-build/Vsoc: $(SRC) $(SRC_SIM) $(BRAMFILE)
	verilator -Iusb -CFLAGS "-ggdb `sdl2-config --cflags` $(VR_TRACE_CFLAGS)" -LDFLAGS "`sdl2-config --libs`" --assert \
			$(VR_TRACE_OPTS) --Mdir verilator-build -Wno-style -Wno-fatal -cc --top-module soc \
			-O3 --noassert --exe $(SRC) $(SRC_SIM)
	$(MAKE) OPT_FAST="-O2 -fno-stack-protector" -C verilator-build -f Vsoc.mk

rom.hex: boot/
	$(MAKE) -C boot
ifeq ($(OS),Windows_NT)
	bin2hex.exe boot/rom.bin rom.hex
else
	cat boot/rom.bin | hexdump -v -e '/4 "%08X\n"' > rom.hex
endif

gdb:
	$(GDB) -b 115200 -ex "set debug remote 1" -ex "target remote /dev/ttyUSB0" app/app.elf

pcpi_fastmul_dsp_testbench:
	iverilog -opcpi_fastmul_dsp_testbench.vvp pcpi_fastmul_dsp_testbench.v pcpi_fastmul_dsp.v picorv32/picorv32.v mul_18x18_sim.v
	vvp pcpi_fastmul_dsp_testbench.vvp

ipl:
	$(MAKE) -C ipl

.PHONY: prog clean verilator boot/ ipl
.PRECIOUS: $(PROJ).json $(PROJ)_out_synth.config $(PROJ)_out.config

