SRC := ram_dp_24x2048_sim.v video_mem.v vid_linerenderer.v vid.v ../qpi_cache/qpimem_dma_rdr.v
SRC += vid_palettemem_sim.v vid_tilemapmem_sim.v vid_tilemem_sim.v vgapal.c ../mul_18x18_sim.v
SRC += vid_spriteeng.v vid_sprite_linebuf_sim.v vid_spritemem_sim.v

SRC_SIM := video_renderer.cpp verilator_options.cpp verilator_setup.cpp verilator_main.cpp
SRC_SIM_HDR := video_renderer.hpp verilator_options.hpp verilator_setup.hpp ../ipl/gloss/mach_defines.h

verilator: verilator-build/Vvid $(EXTRA_DEPEND)
	./verilator-build/Vvid

verilator-trace: verilator-build/Vvid $(EXTRA_DEPEND)
	./verilator-build/Vvid -t

verilator-build/Vvid: $(SRC) $(SRC_SIM) $(BRAMFILE) $(SRC_SIM_HDR)
	verilator -CFLAGS "-ggdb `sdl2-config --cflags`" -LDFLAGS "`sdl2-config --libs` -lgd" --assert --trace \
		--Mdir verilator-build -Wno-style -Wno-fatal -cc --top-module vid --exe $(SRC) $(SRC_SIM)
	make OPT_FAST="-Og -fno-stack-protector" -C verilator-build -f Vvid.mk

clean:
	rm -rf verilator-build

.PHONY: clean
