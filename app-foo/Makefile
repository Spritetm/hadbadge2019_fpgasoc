#This is an example Makefile to build the 'Hello world' example.
all: flash

#The name of the app. The resulting file will be called APPNAME.elf.
APPNAME = foo

#Option 1 of indicating what files to compile: tell the SDK what directories contain
#source files. The SDK will then compile everything in these directories.
SRCDIRS = . subdir

#Option 2: Tell the SDK what objects there are. The objects are effectively all
#compilable files with their extension changed to .o. Note: This means it will not
#work if you put c-files in here, you must change the extension to .o.
#OBJS = main.o subdir/bla.o

#These directories will be passed (with the -I flag) to the compiler. This makes it so you
#can directly #include "file.h" from these directories.
INCLUDEDIRS =

#You can include binaries directly in your app by adding it to BINFILE. See main.c on how
#to reference to its data.
BINFILES = bgnd.png

#Normally, you'd put the APSSDK_DIR in your environment. Here, we know where it is, so
#if people have not got it set, we assume the default relative directory to it.
APPSSDK_DIR ?= ../apps-sdk

#Include the SDK makefile. It'll take care of the rest.
include $(APPSSDK_DIR)/sdk.mk

flash: foo.elf
	sudo mount -o user,umask=000,utf8 /dev/sdd1 badgemount
	cp foo.elf badgemount 
	sync
	sudo umount badgemount
	-echo DONE

