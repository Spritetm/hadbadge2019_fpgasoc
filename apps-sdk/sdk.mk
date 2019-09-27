#Include local settings for entire project, if they exist
-include ../local-settings.mk

#Set prefixes and paths to all tools.
PREFIX := $(RISCV_TOOLCHAIN_PATH)/riscv32-unknown-elf-
CC := $(PREFIX)gcc
AR := $(PREFIX)ar
LD := $(PREFIX)ld
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
SIZE := $(PREFIX)size

#Name of what we're trying to build.
TARGET_ELF := $(APPNAME).elf
TARGET_MAP := $(APPNAME).map

#Linker script path
LDSCRIPT := $(APPSSDK_DIR)/gloss/ldscript.ld

#Note that PWD is the source dir of the app, so the build dir will be under the current app.
BUILD_DIR := build/
#All SDK files are built in the apps-sdk folder in the build dir,
BUILD_DIR_SDK := $(BUILD_DIR)/apps-sdk

#Ipl gloss is in include path because mach_defines.h
CFLAGS := -Os -ggdb -I$(APPSSDK_DIR) -I$(APPSSDK_DIR)/gloss -I$(APPSSDK_DIR)/../soc/ipl/gloss
LDFLAGS := -Wl,-Bstatic -Wl,--gc-sections -Wl,-T,$(LDSCRIPT) -Wl,-Map,$(TARGET_MAP) -lgcc -nostartfiles
DEPFLAGS := -MMD -MP 

export PREFIX CC AR LD OBJCOPY CFLAGS LDFLAGS APPNAME

#By default, we'll build the elf file.
default: $(TARGET_ELF)

#If no manual objs are given, automatically find them by scanning for all files ending in SRC_SUFFIXES in all SRCDIRS.
#If no srcdir is given, assume this dir. (For simple projects with only a few .c/.h files thrown into a folder.
SRCDIR ?= .
SRC_SUFFIXES := .S .s .c .cpp
ifeq ($(OBJS),)
	OBJS := $(addsuffix .o,$(basename $(foreach dir,$(SRCDIRS),$(wildcard $(addprefix $(dir)/*,$(SRC_SUFFIXES))))))
endif

#Define objects used for the SDK itself here and the libs they're supposed to make.
#Note that all objects in a subdir are packed in the lib name in the same subdir.
SDK_OBJS := gloss/crt0.o
SDK_LIBS := gloss/libgloss.a

LIBS += $(addprefix $(BUILD_DIR_SDK)/,$(SDK_LIBS))

#Note that OBJS are 'virtual' objects that live in the source directory next to the source files they
#are generated from. (They're effectively the names of and paths to the source files, but with .c/.S/...
#changed to .o.) OBJS_BUILDDIR contains the actual locations of the object files so we can depend
#on them when generating the elf.
OBJS_BUILDDIR := $(abspath $(addprefix $(BUILD_DIR),$(OBJS)))

#Handle verbosity setting. Run e.g. 'make V=1' to show full command lines.
ifeq ("$(V)","1")
Q :=
vecho = @true
else
Q := @
vecho = @echo "    "
endif

#Template to generate recipes to compile all files in one dir.
#Called with $1 being build dir, $2 being source dir
define build_template
#$$(info build_template called with $(1) $(2))
$(1)/%.o: $(2)/%.c
	$$(vecho) CC $$(notdir $$<)
	$$(Q)mkdir -p $(1)
	$$(Q)$$(CC) $$(CFLAGS) $$(2DEPFLAGS) -c -o $$@ $$<

$(1)/%.o: $(2)/%.S
	$$(vecho) CC $$(notdir $$<)
	$$(Q)mkdir -p $(1)
	$$(Q)$$(CC) $$(CFLAGS) $$(DEPFLAGS) -c -o $$@ $$<
endef

#Generate patterns to compile all app objects.
$(foreach dir,$(sort $(dir $(OBJS))),$(eval $(call build_template,$(abspath $(BUILD_DIR)/$(dir)),$(abspath $(dir)))))

#Dependency pattern for sdk libs. Called with lib name as $1, list of objs as $2.
define sdklib_template
#$$(info sdklib_template $(1) $(2))
$(1): $(2)
	$$(vecho) AR $$(notdir $(1))
	$$(Q)mkdir -p $$(dir $(1))
	$$(Q)$$(AR) rc $(1) $(2)
endef

#Generate patterns to compile all sdklibs objects.
$(foreach dir,$(sort $(dir $(SDK_OBJS))),$(eval $(call build_template,$(abspath $(BUILD_DIR_SDK)/$(dir)),$(abspath $(addprefix $(APPSSDK_DIR)/,$(dir))))))
#Generate pattern to generate dependencies to build sdklibs
$(foreach lib,$(SDK_LIBS),$(eval $(call sdklib_template,$(addprefix $(BUILD_DIR_SDK)/,$(lib)),$(abspath $(addprefix $(BUILD_DIR_SDK)/,$(filter $(dirname $(lib))%,$(SDK_OBJS)))))))

#Libs contains things like build/apps-sdk/gloss/libgloss.a
#These lines convert that into -Lbuild/apps-sdk/gloss/ and -lgloss, respectively
LIBPATHS=$(addprefix -L,$(dir $(LIBS)))
LIBREFS=$(patsubst lib%,-l%,$(notdir $(basename $(LIBS))))

#Main target
$(TARGET_ELF): $(LIBS) $(OBJS_BUILDDIR) $(LDSCRIPT)
	$(vecho) LD $@
	$(Q)$(CC) $(LDFLAGS) -o $@ $(LIBPATHS) $(LIBREFS) -lm $(OBJS_BUILDDIR) 
	$(vecho) STRIP $@
	$(Q)$(PREFIX)strip $@

#Clean all targets. Should leave an empty build dir tree.
.PHONY: clean
clean:
	$(vecho) CLEAN
	$(Q)rm -f $(TARGET_ELF)
	$(Q)rm -rf $(addprefix $(BUILD_DIR)/,$(OBJS)) $(addprefix $(BUILD_DIR)/,$(OBJS:%.o=%.d)) 
	$(Q)rm -rf $(addprefix $(BUILD_DIR_SDK)/,$(SDK_OBJS)) $(addprefix $(BUILD_DIR_SDK)/,$(SDK_OBJS:%.o=%.d))
	$(Q)rm -rf $(addprefix $(BUILD_DIR_SDK),/$(SDK_LIBS)) $(TARGET_MAP)

#Include auto-generated dependencies, if exist.
include $(wildcard $(OBJS_BUILDDIR:%.o=%.d))
