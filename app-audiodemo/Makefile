#This is an example Makefile to build the synth demo example.
# If you want to add synth functions to your code, copy the synth folder in, 
# and add "synth" to the src/include directories.  
# If you want it to play in tune, also consider including "midi_note_increments.h"

#The name of the app. The resulting file will be called APPNAME.elf.
APPNAME = audiodemo

#Add the synth source directory 
SRCDIRS = . synth

#Add the synth include directory
INCLUDEDIRS = synth

#Normally, you'd put the APSSDK_DIR in your environment. Here, we know where it is, so
#if people have not got it set, we assume the default relative directory to it.
APPSSDK_DIR ?= ../apps-sdk

#Include the SDK makefile. It'll take care of the rest.
include $(APPSSDK_DIR)/sdk.mk


