//This is the initial bit of the IPL binary. It starts with a header
//that allows the bootloader to load it from flash, then has all the
//syscalls that allows the application to use the drivers in the IPL.

	.section .text

.global start_ipl
.global _start
.global _bin_end
.global _bin_start

reset_vec:
	.word 0x1337b33f
	.word _bin_end - _bin_start
_start:
	j start_ipl

.global _access
	j _access
.global _chdir
	j _chdir
.global _chmod
	j _chmod
.global _chown
	j _chown
.global _close
	j _close
.global _execve
	j _execve
.global _exit
	j _exit
.global _faccessat
	j _faccessat
.global _fork
	j _fork
.global _fstatat
	j _fstatat
.global _fstat
	j _fstat
.global _ftime
	j _ftime
.global _getcwd
	j _getcwd
.global _getpid
	j _getpid
.global _gettimeofday
	j _gettimeofday
.global _isatty
	j _isatty
.global _kill
	j _kill
.global _link
	j _link
.global _lseek
	j _lseek
.global _lstat
	j _lstat
.global _openat
	j _openat
.global _open
	j _open
.global _read
	j _read
.global _stat
	j _stat
.global _sysconf
	j _sysconf
.global _times
	j _times
.global _unlink
	j _unlink
.global _utime
	j _utime
.global _wait
	j _wait
.global _write
	j _write
.global opendir
	j opendir
.global readdir
	j readdir
.global closedir
	j closedir
.global sbrk_app //maps to _sbrk in app code
	j sbrk_app
.global gfx_load_fb_mem
	j gfx_load_fb_mem
.global gfx_load_tiles_mem
	j gfx_load_tiles_mem
.global user_memfn_set
	j user_memfn_set
.global gfx_load_tilemap_mem
	j gfx_load_tilemap_mem
.global gfx_load_fb_tga
	j gfx_load_fb_tga
.global gfx_load_fb_tga_mem
	j gfx_load_fb_tga_mem
.global gfx_load_tiles_tga
	j gfx_load_tiles_tga
.global gfx_load_tiles_tga_mem
	j gfx_load_tiles_tga_mem
.global usb_msc_on
	j usb_msc_on
.global usb_msc_off
	j usb_msc_off
.global fs_cart_initialize_fat
	j fs_cart_initialize_fat
.global millis
	j millis
.global delay
	j delay
.global wait_for_button_press
	j wait_for_button_press
.global wait_for_button_release
	j wait_for_button_release
.global wait_for_next_frame
	j wait_for_next_frame


