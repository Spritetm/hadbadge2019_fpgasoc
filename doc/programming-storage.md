Storage & programming
=====================

The badge has two storage devices: the on-board flash and the cartridge flash. Obviously,
cartridge flash is only available whenever a cartridge with on-board flash is plugged in.
There are two ways to program this storage, depending on what needs to be programmed.
For applications and general-use files, both the internal flash as well as cartridge
flash has two ranges that are formatted as a FAT filesystem on top of a flash translation
layer. (Note that for cartridges, this is optional: see below for details.) To place files
here, simply boot the cartridge into the main menu and plug it in over USB. The internal and,
if available, cartridge FAT partitions should show up as mass storage devices; simply copy
files and apps from and to them.

Other data, like ECP5 bitstreams and the IPL, cannot be files as they need to be loaded when
the FAT driver isn't active. These are flashed 'raw' to certain memory regions using the 
bootloader.

Bootloader functions
--------------------

Your badge comes equipped with a bootloader that is able to program most of the rest of the 
flash by enumerating as a standard USB DFU device. To activate it, hold SELECT (SW7) when powering
on the device. By default, the bootloader does not allow overwriting itself and makes the largest
part of the memory it lives in write-protected. To disable this protection, hold START (SW8) on 
bootup, either in conjunction with SELECT to flash the bootloader using DFU or by itself to allow
other software/gateware to write to the bootloader region.

The tool of choice to upload new data using the bootloader is ``dfu-util``, this tool should
be included in your toolchain download or you can install it yourself. As DFU is a standard,
other tools should work as well. In order to specify what region needs to be flashed, DFU uses
the so-called 'alt'-setting. Which setting to use is shown in the table below. As an example,
if you wanted to overwrite the IPL on the internal flash with the contents of the file
``ipl.bin``, you could do so using the following command line:

```
dfu-util -a 1 -D ipl.bin
```

Note that a lot of Makefiles already have a target for dfu-util-based flashing built-in: in the
SoC and IPL directory, it suffices to simply run ``make dfu_flash`` to build and flash.

Flash ranges
------------
Note that there's no on-storage partition table at this moment. All offsets are hardcoded
in the IPL/SDK/bitstreams.

Internal flash:

| Location          | Size   | Function            | alt | Note               |
|-------------------|--------|---------------------|-----|--------------------|
| 0-0x17FFFF        | 1.5MiB | Bootloader          | 5*  | FPGA bitstream     |
| 0x180000-0x2FFFFF | 1.5MiB | SoC                 | 0   | FPGA bitstream     |
| 0x300000-0x37FFFF | 0.5MiB | IPL                 | 1   | RiscV binary       |
| 0x380000-0xCFFFFF | 9.5MiB | FAT16 part          |     | Filesystem, TJFTL  |
| 0xD00000-0xFFFFFF | 3MiB   | Spare               |     | Not used atm       |

What do they do?

- The bootloader starts at power on and if you hold the SELECT button (SW7) you are able to use DFU
  to connect the device to a computer to write things to the flash directly. If that button is not
  held, or after a DFU reset, it'll pull the FPGAs PROGRAMN pin to load the SoC bitstream.

- The SoC bitstream has a small bit of code pre-loaded in its PSRAM cache (see soc/boot for the source 
  code) This piece of code will try to load the IPL from flash, then run it. If no IPL is detected, 
  it'll sit and wait until the data at memory address 0 changes to 0xdeadbeef, and then run the IPL 
  anyway. (This allows for a JTAG upload of IPL+app)

- The IPL will initialize the LCD and framebuffer and show the main menu that can be used to select
  an app. To do this, it will also initialize TJFTL (the flash translation layer) and on top of that 
  the FAT16 partition that contains the apps. This FAT partition is accessible over USB as mass storage
  as well, allowing you to just drag&drop files into it. It will do the same with any cartridge
  that is plugged in and contains a TJFL.

Cartridge flash:

| Location          | Size   | Function            | alt | Note                       |
|-------------------|--------|---------------------|-----|----------------------------|
| 0-0x17FFFF        | 1.5MiB | FPGA image          | 2   | FPGA bitstream             |
| 0x180000-0x200000 | 0.5MiB | User-defined        | 3   | IPL, if bitstream is SoC   |
| 0x200000-0xFFFFFF | 14MiB  | Filesystem          | 4   | FAT16/TJFL *               |

The last partition is only used if a TJFTL signature is detected (3 out of 4 first pages have
a valid signature), otherwise they are ignored and can be used as user-defined memory. The
user-defined partition is never touched by the main software, but can contain an IPL image
if the FPGA bitstream is a (modified) SoC image.

Note that smaller flash chips should be autodetected by IPL and the FAT partition is made 
smaller to match.


