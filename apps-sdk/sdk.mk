-include ../local-settings.mk

PREFIX := $(RISCV_TOOLCHAIN_PATH)/riscv32-unknown-elf-
CC := $(PREFIX)gcc
AR := $(PREFIX)ar
LD := $(PREFIX)ld
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
SIZE := $(PREFIX)size

TARGET_ELF := $(APPNAME).elf
TARGET_BIN := $(APPNAME).bin
TARGET_MAP := $(APPNAME).map
TARGET_SVF := $(APPNAME).svf
LIBS += $(APPSSDK_DIR)/gloss/libgloss.a
LDSCRIPT := $(APPSSDK_DIR)/gloss/ldscript.ld

#Ipl gloss is in include path because mach_defines.h
CFLAGS := -Og -ggdb -I. -Igloss -I$(APPSSDK_DIR)/../soc/ipl/gloss
LDFLAGS := -Wl,-Bstatic -Wl,--gc-sections -Wl,-Map,$(TARGET_MAP) -lgcc -nostartfiles -L$(APPSSDK_DIR)/gloss -Wl,-T,$(LDSCRIPT) 
export PREFIX CC AR LD OBJCOPY CFLAGS LDFLAGS APPNAME

$(TARGET_ELF): $(LIBS) $(OBJS) $(LDSCRIPT)
	$(CC) $(LDFLAGS) -o $@ $(LIBS) -lm $(OBJS) 
#	$(PREFIX)strip $@

.PHONY: clean
clean:
	rm -f $(TARGET_ELF) $(OBJS) $(TARGET_MAP)
	$(MAKE) -C gloss clean

.PHONY: $(APPSSDK_DIR)/gloss/libgloss.a
$(APPSSDK_DIR)/gloss/libgloss.a:
	$(MAKE) -C $(APPSSDK_DIR)/gloss
