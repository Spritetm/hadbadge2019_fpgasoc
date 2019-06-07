SRC := ram_dp_24x2048_sim.v video_mem.v vid_linerenderer.v vid.v video_renderer.cpp verilator_main.cpp

verilator: verilator-build/Vvid $(EXTRA_DEPEND)
	./verilator-build/Vvid

verilator-build/Vvid: $(SRC) $(SRC_SIM) $(BRAMFILE)
	verilator -CFLAGS "-ggdb `sdl2-config --cflags`" -LDFLAGS "`sdl2-config --libs`" --assert --trace --Mdir verilator-build -Wno-style -Wno-fatal -cc --top-module vid --exe $(SRC) $(SRC_SIM)
	make OPT_FAST="-Og -fno-stack-protector" -C verilator-build -f Vvid.mk
