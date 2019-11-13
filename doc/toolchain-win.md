# Windows Ten Minute Setup for RiscV Development

You've got a badge, you want to write and run C to run on the RiscV. This
is a guide for you.

## Regarding Bash

The toolchain requires a bash shell - it won't work with CMD. We'll use
the bash shell that comes with Git for Windows. Other options include 
installing Windows Subsystem for Linux or using a Mac. However, the git
bash shell is straight forward and Just Works.

## A. Install Git-for-Windows

1. Download git for Windows from [git-scm.com](https://git-scm.com/download/win).
Choose the "64-bit Git for Windows Setup" option.

2. Run the installer. There are a lot of screens for options. You can accept
the defaults for everything.

## B. Make a directory for the Hackaday Badge

1. Run the Git bash shell. (I generally press the Win key once to bring up the
menu, then type 'bash', which brings up the Git Bash option, and the press
enter.)

2. You'll be at a command prompt like this:
```
    Yourname@SOMENAME MINGW64 ~
    $ 
```

3. Run:
```
    $ mkdir hadbadge
```

## C. Install the RiscV toolchain.

1. Download the precompiled toolchain from [xobs/ecp5-toolchain](https://github.com/xobs/ecp5-toolchain/releases/). You want the file named something like `ecp5-toolchain-windows-v1.6.2.zip`.

2. Unzip the toolchain to `C:\Users\Yourname\hadbadge`. You should now have
a directory named `C:\Users\Yourname\hadbadge\ecp5-toolchain-windows-v1.6.2`.

## D. Clone and initialise the Git repo

1. From the bash shell, cd to `~/hadbadge`.

2. Clone the repo
```
    $ git clone https://github.com/Spritetm/hadbadge2019_fpgasoc.git
```

3. If you plan on writing verilog or recompiling the SoC, you must also
get the submodules:
```
    $ cd hadbadge2019_fpgasoc
    $ git submodule update --init --recursive
```

## E. Set up environment

Make a `.bashrc` file in your home directory (i.e. `~/.bashrc`). The file will
set these environment variables and your path. If the .bashrc file already
exists, just add this to the end.

(If the toolchain version changes, don't forget to update the version number in
the path here too!)

```
export APPSSDK_DIR=~/hadbadge/hadbadge2019_fpgasoc/apps-sdk
export RISCV_TOOLCHAIN_PATH=~/hadbadge/ecp5-toolchain-windows-v1.6.2/bin
export PATH=$RISCV_TOOLCHAIN_PATH:$PATH
```

Now restart your Git Bash shell to pick up the changes. Test that you have the
paths set correctly by attempting to run nextpnr:

```
    $ nextpnr-ecp5.exe
```

This should output a list of command-line options. If it doesn't find the
nextpnr-ecp5 command, carefully check directory names in the path.

## F. Make a new C app

Nearly there!

1. Copy the app-helloworld to use as a template for your own code.
```
    $ cd ~/hadbadge
    $ cp -r hadbadge2019_fpgasoc/app-helloworld myapp
```

2. Edit the Makefile at `~/hadbadge/myapp/Makefile`. The most important thing
to change is to change `APPNAME`:
```
APPNAME = myapp
```

3. Edit `main.c`. Find the line that says:
```
	fprintf(f, "Hello World!"); // Print a nice greeting.
```
Change it to say "Hello Yourname!", or "Yourname Roolz!".

4. Run `make`:
```
    $ cd ~/hadbadge/myapp
    $ make
```

All going well, you'll see this output:
```
$ make
     CC crt0.S
     CC app_start.c
     AR libgloss.a
     CC main.c
     CC bla.c
     OBJCOPY bgnd.png
     OBJCOPY tilemap.tmx
     LD myapp.elf
     SYM myapp.elf
     STRIP myapp.elf
```

And you'll have myapp.elf sitting in the myapp directory, ready to move onto
your badge and run.
