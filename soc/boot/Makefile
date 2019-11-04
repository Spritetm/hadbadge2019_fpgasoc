-include ../../local-settings.mk

include ../../toolchain-settings.mk

CFLAGS += -ggdb -I../ipl

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

clean:
	rm -f rom.bin rom.elf $(OBJS)
	rm -rf $(DEPTREE)

send: send.c
	gcc -O2 -ggdb -o send send.c

.PHONY: clean

include $(wildcard $(DEPFILES))

