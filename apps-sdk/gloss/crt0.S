
	.section .text

//note: no irq vector here as that's in the bootloader area

.global _stack_start
.global _bss_start
.global _bss_end
.global _start
.global app_start

//Note: as this is an app, a0-a2 are argc, argv, envp. We want to pass this to the main
//function proper, so these registers should not be disturbed.
_start:
	//Note: stack already is set up from caller
	//Note: elfload already clears bss
	//Note: that leaves us very little to do here...

	//Jump to C code
	j app_start
