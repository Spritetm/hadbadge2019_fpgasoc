
SDK usage (or: how do I create an app?)
=======================================

The main SDK is C-based (uses gcc as a compiler) and uses Newlib as the C library of choice. Newlib
is hooked up fatfs, so it can access the files on the flash (the ones that the IPL allows you to
mess with over USB) using standard fopen()/fclose() etc calls. It also has support for the dbguart
(see J1 on the back of the badge) as well as the CDC-ACM device and a 'console' device that allows
you to fprintf() to the screen. There's also a dynamic memory allocator that gives you access to
most of the 16MiB of RAM the badge has. In general: if you can do it in 'normal' C, you can probably
do it on the badge.

The SDK build system of choice is Make. It is modeled on the ESP32 esp-idf SDK, as in, a project 
only needs a small Makefile identifying the source code, and the SDK will track of dependencies
building in a separate build dir, and linking correctly.
The easiest way to get an app to compile is to copy the app-helloworld and modify it to your needs.
The Makefile and code are more-or-less self-documenting (and, if any, more in sync with the
actual badge and SDK than this document.)

Aside from the standard C stuff you can use, there are a few routines in the IPL that are exported
for you to use, as well as some headers that define useful stuff.


Compile and upload an app
-------------------------

- Turn on the badge. Make sure the SoC and IPL are flashed and recent.

- Go to the subdirectory containing the app you want to compile and upload

- Run `make`

- Connect the badge over USB. Make sure the IPL is fully started.

- Mount the badge as an USB drive, if your OS doesn't do this automatically

- Copy the generated \*.elf file to the USB drive

- Make sure the USB drive is ejected and disconnect the badge from USB.

- The app should show up in the IPL menu now.

