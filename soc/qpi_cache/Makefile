qpimem_iface_testbench:
	iverilog -o qpimem_iface_testbench.vvp qpimem_iface_testbench.v qpimem_iface.v ly68l6400_model.v
	vvp qpimem_iface_testbench.vvp

qpimem_cache_testbench:
	iverilog -o qpimem_cache_testbench.vvp qpimem_cache_testbench.v qpimem_cache.v simple_mem.v simple_mem_words.v
	vvp qpimem_cache_testbench.vvp

verilator: verilator-build/Vqpitest
	./verilator-build/Vqpitest

verilator-build/Vqpitest: qpimem_cache.v simple_mem.v simple_mem_words.v verilator_top.v verilator_main.cpp ../psram_emu.cpp
	verilator -CFLAGS "-ggdb" --assert --trace --Mdir verilator-build -Wno-style -Wno-fatal -cc --top-module qpitest --exe $^
	make OPT_FAST="-O2 -fno-stack-protector" -C verilator-build -f Vqpitest.mk
