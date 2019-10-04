Help!
====

Just received a proto badge? Want to know how you can help this project? Please check
[the wiki](https://github.com/Spritetm/hadbadge2019_fpgasoc/wiki/Hackaday-Supercon-2019-badge)
for what is done and what needs doing.

Hackaday Supercon 2019 Badge: FPGA load
=======================================

Intro
-----

This project contains the FPGA configurations for the badge. At the moment,
the workflow is mainly over USB: while you can us a JTAG rig to program the badge,
the badge comes with an USB bootloader (tinyfpga-bootloader) which can be
used to program the flash, allowing you to both upload a new SoC configuration
and to update the Initial Program Loader (IPL) binary. Furthermore, the
current IPL can be set to Mass Storage Mode. This mode makes the FAT-partition
of the internal flash show up as a disk drive, allowing you to upload apps and
data files.


SoC
---
At the moment, the SOC is a dual-core RiscV processor that uses the external
PSRAM as it's main memory through an internal cache. There's a simple uart
for debugging, as well as a framebuffer-based graphics subsystem for the
LCD and HDMI interfaces.


File structure
--------------

- TinyFPGA-Bootloader contains the boot loader that can be used to re-write 
the flash of the badge over USB. (Used to upload new config without JTAG.) 

- blink contains a trivial blinker project, useful to make sure your setup 
works. 

- app contains a bare-bones test application that the IPL is able to load and execute. This should
be separated into a SDK and an example app; all standard C-based user apps should be compiled
like this.

- soc contains the actual SoC that is the main FPGA load.

The soc folder at this point is a bit of a mess: it contains most of the 'base' Verilog code,
as well as code for simulation of parts using Icarus, or the entirety using Verilator. Apart
from this, the contents of the directories are:

- bram_replace is a tool to replace the content of bram in bitstreams. It's used here to
generate a new bitfile when the bootloader code has changed without having to re-synthesize
the entire project.

- jtagload is a nearly-trivial program to convert a binary executable file into a svf file 
that can then be sent to the FPGA using OpenOCD. At the moment, the boot ROM only invokes a
mode compatible with this when it doesn't find a proper IPL in flash.

- boot contains the bootloader, to be embedded in bram in the FPGA image. At the moment,
it tests the SPI memory (takes a few seconds), then initializes the flash and loads the
IPL from there. If it doesn't see a valid IPL, it waits for an app to be uploaded over
JTAG.

- ipl contains the Initial Program Loader, aka IPL. The IPL mostly contains driver code,
to be called through a syscall jump table at the beginning of the binary. It also has logic
to load an initial program, and to use USB to set up the internal flash as a mass storage device
so an attached PC can access it directly. It also contains a flash translation layer as well
as a fatfs driver, so you can also access the files dropped by the PC programmatically.

- hdmi contains all Verilog for the hdmi output.

- picorv32 is a submodule containing the PicoRV32 RiscV core.

- qpi_cache is the cache for and interface to the external SPI PSRAM.

- video contains the renderer and sequencing logic for the framebuffer.

- pic contains a PIC16F84 core which is intended to drive the attached LEDs.

- usb contains an USB device core.

How to use
==========

Did I already say this is work in progress? You more-or-less need:

- An Unix-based system. No guarantees for anything but Debian Linux at this point.

- Yosys, a recent version (read: grab the git master)

- prjtrellis, to generate ECP5 bitstreams; also use a recent version.

- A RiscV toolchain, for instance built using crosstool-NG. Make sure that the toolchain is
built for the Newlib C library, as the application stuff uses that. It normally has binaries
with the name ``riscv32-unknown-elf-*``. The build system assumes the binaries for it are in your
path, but if not, you can either set the environment ``RISCV_TOOLCHAIN_PATH`` to match, or put
a line setting RISCV_TOOLCHAIN_PATH in a newly-created soc/include.mk file.

- Optional: OpenOCD, plus JTAG hardware. Version of OpenOCD isn't really relevant as we only 
use it to upload svf files at this point. JTAG hardware: faster = better, something 
FT2232H-based works well.

- The badge itself. Duh.

- 2xAA battery, or a 3V'ish power supply. If you want to apply an external power supply, you
  can apply it on J1, between VBAT and GND. Note the badge cannot be powered from USB alone.

The current workflow to get a badge running 'from scratch' is documented below. Note that your
badge probably already has TinyFPGA-Boot, the SoC, IPL and/or apps flashed to that. You can skip the
sections you don't need 

Flash tinyfpga-boot to the badge
--------------------------------
Note that this also overwrites any SoC you have in flash with an ancient version. You may want to
flash the up-to-date SoC immediately after. Also note that your badge probably also comes with a
viable TinyFPGA-Boot version in flash, so in all likelyhood there's no need to dig out the JTAG
adapter. If you still want to do this, here's how:

- Make sure the openocd.conf in this directory reflects your JTAG hardware.

- Make sure the badge is connected both over JTAG as well as USB

- Run 'make flash' in the TinyFPGA-Bootloader/boards/HackadayBadge2019 directory

- Answer 'yes' on the prompt

- Wait until flashing is complete.

Install tinyprog from TinyFPGA-Bootloader
-----------------------------------------

tinyprog is used to flash SoC and IPL via USB. It can be installed from the TinyFPGA-Bootloader of this repo:

```
cd hadbadge2019_fpgasoc
git submodule update --init --recursive
cd TinyFPGA-Bootloader/programmer
sudo python setup.py install
```

Synthesize and upload the SoC
-----------------------------

- Run `make` in the fpga/soc directory

- Connect the badge over USB, make sure it is powered off.

- Turn it on, and 1 second after, run `make flash` in the fpga/soc directory.
  (Note timing is kinda critical here.)

- You may need to answer 'yes' to the 'overwrite bootloader' prompt

Compile and upload the IPL
--------------------------

- Run `make` in the soc/ipl directory

- Connect the badge over USB, make sure it is powered off.

- Turn it on, and 2 seconds after, run `make flash` in the fpga/soc/ipl directory.
  (Note timing is kinda critical here.)

- You may need to answer 'yes' to the 'overwrite bootloader' prompt

Upload an app
-------------

- Turn on the badge. Make sure the SoC and IPL are flashed and recent.

- Go to the app subdirectory

- Run `make`

- Connect the badge over USB. Make sure the IPL is fully started.

- Mount the badge as an USB drive, if your OS doesn't do this automatically

- Copy the generated *.elf file to the USB drive


Flash partitions
================
Note that there's no on-storage partition table at this moment. All offsets are hardcoded.

Internal flash:

| Location          | Size   | Function            | Note           |
|-------------------|--------|---------------------|----------------|
| 0-0x17FFFF        | 1.5MiB | TinyFPGA-Bootloader | FPGA bitstream |
| 0x180000-0x2FFFFF | 1.5MiB | SoC                 | FPGA bitstream |
| 0x300000-0x380000 | 0.5MiB | IPL                 | RiscV binary   |
| 0x380000-0xCFFFFF | 9.5MiB | FAT16 part          | Filesystem     |
| 0xD00000-0xFFFFFF | 3MiB   | Spare               | Not used atm   |

What do they do?

- The TinyFPGA-Bootloader starts at power on and if USB is plugged in, gives an 5 second window
  to connect the device to a computer to write things to the flash directly. After that 5 second window,
  or if no Vbus on the USB connector is detected, it'll pull the FPGAs PROGRAMN pin to load the SoC 
  bitstream.

- The SoC bitstream has a small bit of code pre-loaded in its PSRAM cache. This piece of code will try
  to load the IPL from flash, then run it. If no IPL is detected, it'll sit and wait until the data at
  memory address 0 changes to 0xdeadbeef, and then run the IPL anyway. (This allows for a JTAG upload
  of IPL+app)

- The IPL will initialize the LCD and framebuffer and load the initial app from the FAT16 partition 
  on flash. If it cannot load it, it will switch the device to USB MSC upload mode. (Or will it show
  the main menu already? Don't quite know...)

