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
CHMOD := chmod

CFLAGS=-Os -ggdb -I../ipl -march=rv32im -mabi=ilp32
OBJS:=rom.o irq.o gdbstub.o loadipl.o ipl_flash.o

DEPDIR := .deps
DEPFLAGS = -MT $@ -MMD -MP -MF $(patsubst %.o,%.d,$(dir $@)$(DEPDIR)/$(notdir $@))
DEPFILES := $(foreach obj,$(OBJS),$(dir $(obj))$(DEPDIR)/$(notdir $(obj:%.o=%.d)))
DEPTREE := $(sort $(dir $(DEPFILES)))

default: rom.bin

$(DEPFILES):

$(DEPTREE):
	mkdir -p $(DEPTREE)

%.o: %.c
%.o: %.c $(DEPDIR)/%.d | $(DEPTREE)
	$(CC) $(DEPFLAGS) $(CFLAGS) -c -o $@ $<

%.o: %.S
%.o: %.S $(DEPDIR)/%.d | $(DEPTREE)
	$(CC) $(DEPFLAGS) $(CFLAGS) -c -o $@ $<


rom.elf: $(OBJS) sections.lds
	$(CC)  $(CFLAGS) -Wl,-melf32lriscv -ffreestanding -nostdlib -o $@ \
		-Wl,-Bstatic,-T,sections.lds,-Map,rom.map,--strip-debug \
		$(OBJS) -lgcc

rom.bin: rom.elf
	$(OBJCOPY) -O binary $< $@
	$(OBJDUMP) -S $< > rom.disasm
	$(CHMOD) -x $@

clean:
	rm -f rom.bin rom.elf $(OBJS)
	rm -rf $(DEPTREE)

send: send.c
	gcc -O2 -ggdb -o send send.c

.PHONY: clean

include $(wildcard $(DEPFILES))

