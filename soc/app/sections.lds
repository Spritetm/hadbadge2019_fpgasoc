/*
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
*/

MEMORY {
	ram : ORIGIN = 0x00000200, LENGTH = 0x1E00
}

SECTIONS {
	.vectors : {
		. = ORIGIN(ram);
		start.o(.text);
	} > ram
	.text : {
		*(.text);
	} > ram
	.data : {
		*(.rodata);
		*(.rodata.*);
		*(.data);
	} > ram
	.bss (NOLOAD) : {
		. = ALIGN(4);
		_bss_start = .;
		*(.bss);
		*(.sbss);
		*(COMMON);
		. = ALIGN(4);
		_bss_end = .;
	} > ram
}

PROVIDE ( UART = 0x10000000 );
PROVIDE ( LED  = 0x20000000 );
PROVIDE ( LCD =  0x30000000 );

