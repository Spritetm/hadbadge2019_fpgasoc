/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
*/

/*
Memory layout:
0x40000000-0x40002000: 128K boot ROM space
0x40002000-0x40100000: ~1MiB for IPL
0x40100000-0x41000000: 15MiB app
*/

MEMORY {
	ram : org = 0x40100000, len = (8*1024*1024)-0x100000
}

SECTIONS {
	.vectors : {
		. = ORIGIN(ram);
		_bin_start = .;
		KEEP(crt0.o(.text));
	} > ram
	.text : {
		int*(.text);
		*(.text);
		*(.text.*);
	} > ram
	.data : {
		. = ALIGN(4);
		*(.rodata);
		*(.rodata.*);
		*(.srodata)
		*(.srodata.*);
		*(.data);
		*(.data.*);
		*(.gnu.linkonce.d.*)
		*(.data1)
		*(.sdata);
		*(.sdata.*);
		*(.sdata2)
		*(.sdata2.*)
	} > ram
	.bss (NOLOAD) : {
		. = ALIGN(4);
		_bin_end = .;
		_bss_start = .;
		*(.bss);
		*(.bss.*);
		*(.sbss);
		*(.sbss.*);
		*(COMMON);
		*(COMMON.*);
		. = ALIGN(4);
		_bss_end = .;
		_end = .;
	} > ram
}

ENTRY(_start)

/* Syscall table hooks */

PROVIDE ( _access		= 0x4000200c );
PROVIDE ( _chdir		= 0x40002010 );
PROVIDE ( _chmod		= 0x40002014 );
PROVIDE ( _chown		= 0x40002018 );
PROVIDE ( _close		= 0x4000201c );
PROVIDE ( _execve		= 0x40002020 );
PROVIDE ( _exit			= 0x40002024 );
PROVIDE ( _faccessat	= 0x40002028 );
PROVIDE ( _fork			= 0x4000202c );
PROVIDE ( _fstatat		= 0x40002030 );
PROVIDE ( _fstat		= 0x40002034 );
PROVIDE ( _ftime		= 0x40002038 );
PROVIDE ( _getcwd		= 0x4000203c );
PROVIDE ( _getpid		= 0x40002040 );
PROVIDE ( _gettimeofday	= 0x40002044 );
PROVIDE ( _isatty		= 0x40002048 );
PROVIDE ( _kill			= 0x4000204c );
PROVIDE ( _link			= 0x40002050 );
PROVIDE ( _lseek		= 0x40002054 );
PROVIDE ( _lstat		= 0x40002058 );
PROVIDE ( _openat		= 0x4000205c );
PROVIDE ( _open			= 0x40002060 );
PROVIDE ( _read			= 0x40002064 );
PROVIDE ( _stat			= 0x40002068 );
PROVIDE ( _sysconf		= 0x4000206c );
PROVIDE ( _times		= 0x40002070 );
PROVIDE ( _unlink		= 0x40002074 );
PROVIDE ( _utime		= 0x40002078 );
PROVIDE ( _wait			= 0x4000207c );
PROVIDE ( _write		= 0x40002080 );
PROVIDE ( opendir		= 0x40002084 );
PROVIDE ( readdir		= 0x40002088 );
PROVIDE ( closedir		= 0x4000208C );
PROVIDE ( _sbrk			= 0x40002090 );
PROVIDE ( gfx_load_fb_mem = 0x40002094 );
PROVIDE ( gfx_load_tiles_mem = 0x40002094 );

PROVIDE ( interrupt_vector_table = 0x40000020 );
PROVIDE ( irq_stack_ptr = 0x400000a0 );

PROVIDE ( UART =        0x10000000 );
PROVIDE ( MISC =        0x20000000 );
PROVIDE ( LCD =         0x30000000 );
PROVIDE ( GFXREG =      0x50000000 );
PROVIDE ( GFXPAL =      0x50002000 );
PROVIDE ( GFXTILEMAPA = 0x50004000 );
PROVIDE ( GFXTILEMAPB = 0x50008000 );
PROVIDE ( GFXTILES =    0x50010000 );
PROVIDE ( USB =         0x60000000 );
