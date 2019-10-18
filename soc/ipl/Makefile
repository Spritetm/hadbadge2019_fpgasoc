-include ../../local-settings.mk

ifeq ("$(RISCV_TOOLCHAIN_PATH)", "")
PREFIX := riscv64-unknown-elf-
else
PREFIX := $(RISCV_TOOLCHAIN_PATH)/riscv64-unknown-elf-
endif
CC := $(PREFIX)gcc
AR := $(PREFIX)ar
LD := $(PREFIX)ld
OBJCOPY := $(PREFIX)objcopy
OBJDUMP := $(PREFIX)objdump
SIZE := $(PREFIX)size

APPNAME := ipl
TARGET_ELF := $(APPNAME).elf
TARGET_BIN := $(APPNAME).bin
TARGET_MAP := $(APPNAME).map
TARGET_SVF := $(APPNAME).svf
OBJS = main.o lcd.o UGUI/ugui.o
#OBJS += usb/usb.o usb/usb_ctrl_ep0.o usb/usb_ctrl_std.o usb/usb_desc_app.o usb/utils.o
OBJS += tinyusb/src/device/usbd.o tinyusb/src/device/usbd_control.o tinyusb/src/tusb.o
OBJS += tinyusb/src/common/tusb_fifo.o
OBJS += tinyusb/src/class/msc/msc_device.o tinyusb/src/class/midi/midi_device.o
OBJS += tinyusb/src/class/cdc/cdc_device.o tinyusb/src/class/hid/hid_device.o
OBJS += dcd_tntusb.o usb_descriptors.o hexdump.o flash.o
OBJS += fatfs/source/ff.o fatfs/source/ffunicode.o loadapp.o elfload/elfload.o
OBJS += elfload/elfreloc_riscv.o lodepng.o bgnd.o tileset-default.o
OBJS += tjftl/tjftl.o fs.o gfx_load.o
LIBS := gloss/libgloss.a -lm
LDSCRIPT := gloss/ldscript.ld

CFLAGS := -Os -ggdb -I. -Isyscallable -Ilodepng -IUGUI -Iusb -Igloss -Itinyusb/src -Ifatfs/source -I../tinyusb/src -I../ -march=rv32im -mabi=ilp32
ASFLAGS := -march=rv32i -mabi=ilp32
LDFLAGS := -Wl,-Bstatic -Wl,--gc-sections  -Wl,-T,$(LDSCRIPT) -Wl,-Map,$(TARGET_MAP) -lgcc -lm -nostartfiles -Lgloss -Wl,-melf32lriscv -march=rv32im -mabi=ilp32
export PREFIX CC AR LD OBJCOPY CFLAGS ASFLAGS LDFLAGS APPNAME

default: $(TARGET_BIN)

bgnd.o: bgnd.png
	$(OBJCOPY) -I binary -O elf32-littleriscv -B riscv $< $@

tileset-default.o: tileset-default.png
	$(OBJCOPY) -I binary -O elf32-littleriscv -B riscv $< $@


DEPDIR := .deps
DEPFLAGS = -MT $@ -MMD -MP -MF $(patsubst %.o,%.d,$(dir $@)$(DEPDIR)/$(notdir $@))
DEPFILES := $(foreach obj,$(OBJS),$(dir $(obj))$(DEPDIR)/$(notdir $(obj:%.o=%.d)))
DEPTREE := $(sort $(dir $(DEPFILES)))

$(DEPFILES):

$(DEPTREE):
	mkdir -p $(DEPTREE)


%.o: %.c
%.o: %.c $(DEPDIR)/%.d | $(DEPTREE)
	$(CC) $(DEPFLAGS) $(CFLAGS) -c -o $@ $<


$(TARGET_BIN): $(TARGET_ELF)
	$(SIZE) $^
	$(OBJCOPY) -O binary $^ $@
	$(OBJDUMP) -S $^ > $(APPNAME).disasm

$(TARGET_ELF): $(LIBS) $(OBJS) $(LDSCRIPT)
	$(CC) -o $@ $(LDFLAGS) $(OBJS) $(LIBS)

.PHONY: clean
clean:
	rm -f $(TARGET_ELF) $(TARGET_BIN) $(OBJS) $(TARGET_MAP) $(TARGET_SVF) $(APPNAME).disasm
	rm -rf $(DEPTREE)
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
	$(PREFIX)gdb -b 115200 -ex "target remote /dev/ttyUSB0" $(APPNAME).elf

.PHONY: gloss/libgloss.a
gloss/libgloss.a:
	$(MAKE) -C gloss

include $(wildcard $(DEPFILES))
