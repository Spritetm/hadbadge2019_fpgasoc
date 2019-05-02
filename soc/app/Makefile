TC_PATH := /home/jeroen/hackaday2019/poc/toolchain/toolchain/bin
NEWLIB_PATH := /home/jeroen/hackaday2019/poc/toolchain/toolchain/bin

PREFIX := $(TC_PATH)/riscv32-unknown-elf-
CC := $(PREFIX)gcc
AR := $(PREFIX)ar
LD := $(PREFIX)ld
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
SIZE := $(PREFIX)size

APPNAME := app
TARGET_ELF := $(APPNAME).elf
TARGET_BIN := $(APPNAME).bin
TARGET_MAP := $(APPNAME).map
OBJS := main.o lcd.o
LIBS := gloss/libgloss.a
LDSCRIPT := gloss/ldscript.ld

CFLAGS := -Os -ggdb -I.
LDFLAGS := -Wl,-Bstatic -Wl,-T,$(LDSCRIPT) -Wl,-Map,$(TARGET_MAP) -lgcc -nostartfiles -Lgloss 
export PREFIX CC AR LD OBJCOPY CFLAGS LDFLAGS APPNAME
#-Wl,--gc-sections  

$(TARGET_BIN): $(TARGET_ELF)
	$(SIZE) $^
	$(OBJCOPY) -O binary $^ $@
	$(OBJDUMP) -S $^ > $(APPNAME).disasm

$(TARGET_ELF): $(LIBS) $(OBJS) $(LDSCRIPT)
	$(CC) $(LDFLAGS) -o $@ $(LIBS) -lm $(OBJS) 

.PHONY: clean
clean:
	rm -f $(TARGET_ELF) $(TARGET_BIN) $(OBJS) $(TARGET_MAP) app.disasm
	$(MAKE) -C gloss clean

.PHONY: prog
prog: $(TARGET_BIN)
	../boot/send $(TARGET_BIN) /dev/ttyUSB0

gdb: $(TARGET_ELF)
	/home/jeroen/hackaday2019/riscv-toolchain/bin/riscv32-unknown-elf-gdb -b 115200 -ex "target remote /dev/ttyUSB0" app.elf

.PHONY: gloss/libgloss.a
gloss/libgloss.a:
	$(MAKE) -C gloss
