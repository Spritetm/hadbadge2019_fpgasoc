Hackaday Supercon 2019 Badge: Gateware & 'OS' & SDK
===================================================

Note
----

If you see anything wrong or missing, either here in the documentation or in the gateware
or software, do not hesitate to file an issue, or even better, change it and file a push
request.

Intro
-----

This project contains the FPGA configurations for the badge, in the form of a SoC
containing the processors and all peripherals. It also contains the software 
responsible for bootup and app selection and loading (boot and IPL) as well
as the SDK you can use to create new apps.

How to use
==========

In order to use this repository, aside from the badge itself, you'll need a toolchain
compiled for your OS:

- [Linux](./doc/toolchain-lin.md)
- [MacOSX](./doc/toolchain-mac.md)
- [Windows](./doc/toolchain-win.md)
- [Docker image](./doc/toolchain-docker.md)

You will also need a Micro-USB cable to connect to the badge, as well as 2 AA's (or another
way to supply it with power, e.g. using the JTAG connector) to power it. Note that while
the badge has a JTAG connector, using this should not be necessary in normal use, even if
you want to change the FPGA load. An 3.3V USB-to-serial cable or board may be useful, the
JTAG connector (J1, on the back of the badge) carries serial debug signals that allows you 
to use e.g. gdb in case of a crash.

After you have a toolchain, you'll need to set up this SDK. Clone this repository and grab 
the submodules, if you haven't already:
```
git clone --recursive https://github.com/Spritetm/hadbadge2019_fpgasoc
cd hadbadge2019_fpgasoc
```

From here, you can start hacking:

- You can just use the hardware and start your new design [from scratch](doc/fpga_dev.md).
- You can [modify the existing SoC](doc/soc_dev.md) to incorporate your own peripherals.
- [Modifying the IPL](doc/ipl_dev.md) is useful if you want to change the look of the menu
  or add extra features there.
- Finally, if you are happy with the existing hardware, you can [write an app](doc/app_dev.md)
  to make use of it.


Repo directory structure
========================

- blink contains a trivial blinker project, useful to make sure your setup 
works. 

- [apps-sdk](./apps-sdk/) contains the SDK you can use to build apps that can be loaded by the IPL.

- [app-helloworld](./app-helloworld/) contains a bare-bones test application that the IPL is able to load and execute. 

- [app-basic](./app-basic/) contains a Basic interpreter that can be used to run .bas files.

- [app-audiodemo](./app-audiodemo/)

- [app-invaders](./app-invaders/)

- [app-flappy](./app-flappy/)

- [app-midi](./app-midi/)

- Other app-* directories contain example projects.

- [soc](./soc/) contains the actual SoC that is the main FPGA load.

The [soc](./soc/) folder at this point is a bit of a mess: it contains most of the 'base' Verilog code,
as well as code for simulation of parts using Icarus, or the entirety using Verilator. Apart
from this, the contents of the directories are:

- [jtagload](./soc/jtagload/) is a nearly-trivial program to convert a binary executable file into a svf file 
that can then be sent to the FPGA using OpenOCD. At the moment, the boot ROM only invokes a
mode compatible with this when it doesn't find a proper IPL in flash.

- [boot](./soc/boot/) contains the bootloader, to be embedded in bram in the FPGA image. At the moment,
it tests the SPI memory (takes a few seconds), then initializes the flash and loads the
IPL from there. If it doesn't see a valid IPL, it waits for an app to be uploaded over
JTAG.

- [ipl](./soc/ipl/) contains the Initial Program Loader, aka IPL. The IPL mostly contains driver code,
to be called through a syscall jump table at the beginning of the binary. It also has logic
to load an initial program, and to use USB to set up the internal flash as a mass storage device
so an attached PC can access it directly. It also contains a flash translation layer as well
as a fatfs driver, so you can also access the files dropped by the PC programmatically. 
Finally, it contains the menu you see when the badge starts up, that allows you to select an app
to run.

- [hdmi](./soc/hdmi/) contains all Verilog for the hdmi output.

- [picorv32](https://github.com/cliffordwolf/picorv32/tree/e0baf2e0bd49fdddef2e3440c1f6364478655154) is a submodule containing the PicoRV32 RiscV core.

- [qpi_cache](./soc/qpi_cache/) is the cache for and interface to the external SPI PSRAM.

- [video](./soc/video/) contains the renderer and sequencing logic for the framebuffer.

- [pic](./soc/pic/) contains a PIC16F84 core which is intended to drive the attached LEDs.

- [usb](./soc/usb/) contains an USB device core.

- [audio](./soc/audio/) contains the audio subsystem.

