-include ../../local-settings.mk

include ../../toolchain-settings.mk

APPNAME := ipl
TARGET_ELF := $(APPNAME).elf
TARGET_BIN := $(APPNAME).bin
TARGET_MAP := $(APPNAME).map
TARGET_SVF := $(APPNAME).svf
OBJS = main.o lcd.o pic.o
OBJS += tinyusb/src/device/usbd.o tinyusb/src/device/usbd_control.o tinyusb/src/tusb.o
OBJS += tinyusb/src/common/tusb_fifo.o
OBJS += tinyusb/src/class/msc/msc_device.o tinyusb/src/class/midi/midi_device.o
OBJS += tinyusb/src/class/cdc/cdc_device.o tinyusb/src/class/hid/hid_device.o
OBJS += tinyusb/src/class/dfu/dfu_rt_device.o
OBJS += dcd_tntusb.o usb_descriptors.o hexdump.o flash.o
OBJS += fatfs/source/ff.o fatfs/source/ffunicode.o loadapp.o elfload/elfload.o
OBJS += elfload/elfreloc_riscv.o lodepng.o bgnd.o tileset-default.o
OBJS += tjftl/tjftl.o fs.o gfx_load.o user_memfn.o yxml/yxml.o badgetime.o
LIBS := gloss/libgloss.a
LIBS_TOOLCHAIN := -lm -lgcc
LDSCRIPT := gloss/ldscript.ld

CFLAGS += -ggdb -I. -Isyscallable -Ilodepng -IUGUI -Iusb -Igloss -Itinyusb/src -Ifatfs/source -I../tinyusb/src -I../ -Iyxml
LDFLAGS += -Wl,-T,$(LDSCRIPT) -Wl,-Map,$(TARGET_MAP) -Lgloss

export CC AR LD OBJCOPY CFLAGS ASFLAGS LDFLAGS APPNAME


default: $(TARGET_BIN)

bgnd.o: bgnd.tga
	$(OBJCOPY) -I binary -O elf32-littleriscv -B riscv $< $@

tileset-default.o: tileset-default.tga
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
	$(CC) -o $@ $(LDFLAGS) $(OBJS) $(LIBS) $(LIBS_TOOLCHAIN)

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

dfu_flash: $(TARGET_BIN)
	dfu-util$(EXE) -d 1d50:614a,1d50:614b -a 1 -R -D $<

dfu_flash_cart: $(TARGET_BIN)
	dfu-util$(EXE) -d 1d50:614a,1d50:614b -a 3 -R -D $<

gdb: $(TARGET_ELF)
	$(GDB) -b 115200 -ex "target remote /dev/ttyUSB0" $(APPNAME).elf

.PHONY: gloss/libgloss.a
gloss/libgloss.a: gloss
	$(MAKE) -C gloss

include $(wildcard $(DEPFILES))
