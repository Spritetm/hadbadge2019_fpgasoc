Hackaday Supercon 2019 Badge: FPGA load
=======================================

Intro
-----

This project contains the FPGA configurations for the badge. At the moment,
the workflow is mainly over USB: you need a JTAG rig to program the badge,
both to upload a new SoC configuration as well as to send the application to
SRAM. There is some work in progress for a flash/USB-based workflow, but this
is still a work-in-progress (see tinyfpga-bootloader).


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
works. soc contains the actual SoC that is the main load.

The soc folder at this point is a bit of a mess: it contains most of the 'base' Verilog code,
as well as code for simulation of parts using Icarus, or the entirety using Verilator. Apart
from this, the contents of the directories are:

- bram_replace is a tool to replace the content of bram in bitstreams. It's used here to
generate a new bitfile when the bootloader code has changed without having to re-synthesize
the entire project.

- jtagload is a nearly-trivial program to convert a binary executable file into a svf file 
that can then be sent to the FPGA using OpenOCD.

- boot contains the bootloader, to be embedded in bram in the FPGA image. At the moment,
it tests the SPI memory (takes a few seconds), then waits for an app to be uploaded over
JTAG.

- app contains the main application. It's a standalone executable, to be uploaded over
JTAG (at the moment, the bootloader cannot load it from flash yet).

- hdmi contains all Verilog for the hdmi output

- picorv32 is a submodule containing the PicoRV32 RiscV core.

- qpi_cache is the cache for and interface to the external SPI PSRAM.

- video contains the renderer and sequencing logic for the framebuffer.

How to use
==========

Did I already say this is work in progress? You more-or-less need:

- An Unix-based system. No guarantees for anything but Debian Linux at this point.

- Yosys, a recent version (read: grab the git master)

- prjtrellis, to generate ECP5 bitstreams; also use a recent version.

- A RiscV toolchain, for instance built using crosstool-NG. Make sure that the toolchain is
built for the Newlib C library, as the application stuff uses that.

- OpenOCD, plus JTAG hardware. Version of OpenOCD isn't really relevant as we only use it to upload
svf files at this point. JTAG hardware: faster = better, something FT2232H-based works well.

- The badge

In theory, the current workflow is something like:

- Connect the badge to JTAG

- Run `make prog` in the soc directory

- Wait until the RAM test is done (D5, D6, D7 are lit)

- Run `make prog` in the app directory

- Gaze at the beauty of the SoC running the app

At this point, you can also flash the bootloader and SoC (but not the app) to flash.

- Make sure the badge is connected both over JTAG as well as USB

- Run 'make flash' in the TinyFPGA-Bootloader/boards/hadbadge2019 directory

- Answer 'yes' on the prompt

- Run `make flash` in the SoC directory.




