SRC := ram_dp_24x2048_sim.v video_mem.v vid_linerenderer.v vid.v video_renderer.cpp verilator_main.cpp ../qpi_cache/qpimem_dma_rdr.v
SRC += vid_palettemem_sim.v vid_tilemapmem_sim.v vid_tilemem_sim.v vgapal.c ../mul_18x18_sim.v
SRC += vid_spriteeng.v vid_sprite_linebuf_sim.v vid_spritemem_sim.v
verilator: verilator-build/Vvid $(EXTRA_DEPEND)
	./verilator-build/Vvid

verilator-build/Vvid: $(SRC) $(SRC_SIM) $(BRAMFILE)
	verilator -CFLAGS "-ggdb `sdl2-config --cflags`" -LDFLAGS "`sdl2-config --libs` -lgd" --assert --trace --Mdir verilator-build -Wno-style -Wno-fatal -cc --top-module vid --exe $(SRC) $(SRC_SIM)
	make OPT_FAST="-Og -fno-stack-protector" -C verilator-build -f Vvid.mk
