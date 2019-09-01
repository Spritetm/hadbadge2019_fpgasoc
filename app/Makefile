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
TARGET_SVF := $(APPNAME).svf
OBJS = main.o
LIBS := gloss/libgloss.a
LDSCRIPT := gloss/ldscript.ld

CFLAGS := -Og -ggdb -I. -Igloss -I../ipl/gloss
LDFLAGS := -Wl,-Bstatic -Wl,--gc-sections -Wl,-Map,$(TARGET_MAP) -lgcc -nostartfiles -Lgloss -Wl,-T,$(LDSCRIPT) 
export PREFIX CC AR LD OBJCOPY CFLAGS LDFLAGS APPNAME


$(TARGET_ELF): $(LIBS) $(OBJS) $(LDSCRIPT)
	$(CC) $(LDFLAGS) -o $@ $(LIBS) -lm $(OBJS) 
	$(OBJDUMP) -S $@ > $(APPNAME).disasm
#	$(PREFIX)strip $@

.PHONY: clean
clean:
	rm -f $(TARGET_ELF) $(TARGET_BIN) $(OBJS) $(TARGET_MAP) $(TARGET_SVF) app.disasm
	$(MAKE) -C gloss clean

.PHONY: prog
prog: $(TARGET_SVF)
	openocd -f ../../openocd.cfg -c "init; svf  $<; exit"
#	../boot/send $(TARGET_BIN) /dev/ttyUSB0

$(TARGET_SVF): $(TARGET_BIN)
	../jtagload/jtagload < $(TARGET_BIN) > $(TARGET_SVF)

flash: $(TARGET_BIN)
	tinyprog -p $(TARGET_BIN) -a 0x300000

gdb: $(TARGET_ELF)
	/home/jeroen/hackaday2019/riscv-toolchain/bin/riscv32-unknown-elf-gdb -b 115200 -ex "target remote /dev/ttyUSB0" app.elf

.PHONY: gloss/libgloss.a
gloss/libgloss.a:
	$(MAKE) -C gloss
