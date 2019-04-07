qpimem_iface_testbench:
	iverilog -o qpimem_iface_testbench.vvp qpimem_iface_testbench.v qpimem_iface.v ly68l6400_model.v
	vvp qpimem_iface_testbench.vvp

qpimem_cache_testbench:
	iverilog -o qpimem_cache_testbench.vvp qpimem_cache_testbench.v qpimem_cache.v simple_mem.v simple_mem_words.v
	vvp qpimem_cache_testbench.vvp
