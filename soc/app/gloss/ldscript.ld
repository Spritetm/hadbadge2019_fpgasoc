/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
*/

MEMORY {
	ram : org = 0x0002000, len = (8*1024*1024)-0x2000
}

_stack_size = 0x1000;

SECTIONS {
	.vectors : {
		. = ORIGIN(ram);
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
		*(.sdata);
		*(.sdata.*);
	} > ram
	.bss (NOLOAD) : {
		. = ALIGN(4);
		_bss_start = .;
		*(.bss);
		*(.bss.*);
		*(.sbss);
		*(.sbss.*);
		*(COMMON);
		*(COMMON.*);
		. = ALIGN(4);
		_bss_end = .;
	} > ram
	.stack (NOLOAD) : {
		_end = .;
		_stack_start = ORIGIN(ram) + LENGTH(ram);
		_stack_end = ORIGIN(ram) + LENGTH(ram) - _stack_size;
	} > ram
}

PROVIDE ( UART = 0x10000000 );
PROVIDE ( LED  = 0x20000000 );
PROVIDE ( LCD =  0x30000000 );

