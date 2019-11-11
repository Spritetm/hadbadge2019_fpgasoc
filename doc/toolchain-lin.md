# Pre Compiled Toolchain

This is probably the easiest way to get going, but YMMV depending on the Linux distribution you are using. But it is worth a shot before you go down the path of building your own toolchains.

Download the linux_x86_64 archive from https://github.com/xobs/ecp5-toolchain/releases.

Extract the tools for example into your home directory:

```
cd ~
tar xfvz <archive-location>/ecp5-toolchain-linux_x86_64-<ver>.tar.gz
export PATH=~/ecp5-toolchain-linux_x86_64-<ver>/bin:$PATH
```

You can add the `export PATH=~/ecp5-toolchain-linux_x86_64-<ver>/bin:$PATH` to your `.profile` if you want to make it permanently accessible.

Now you should be able to build the SOC, IPL and the apps.

In some cases you will not have the user permissions to access your badge over USB. You will need to add `udev` rules. You will need to create a file `/etc/udev/rules.d/59-hadb19.rules` with the following content:
```
ATTR{idVendor}=="1d50", ATTR{idProduct}=="614a", MODE="660", GROUP="plugdev", TAG+="uaccess"
ATTR{idVendor}=="1d50", ATTR{idProduct}=="614b", MODE="660", GROUP="plugdev", TAG+="uaccess"
```

# Build it yourself

You can build the FPGA tools using the https://github.com/esden/summon-fpga-tools script. This will build and install the tools in your home directory under `~/sft`. Follow the instructions included in the summon-fpga-tools README.

If you want to compile your own RiscV toolchain, see https://github.com/riscv/riscv-gnu-toolchain .
Specifically, you want a multilib Newlib toolchain, something that is not in the list. Just
invoke these two commands after having fulfilled all prerequisites and you should be good:

```
./configure --prefix=/opt/riscv --enable-multilib
make
```
