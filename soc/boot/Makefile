-include ../include.mk
TOOLCHAIN_PREFIX := $(RISCV_TOOLCHAIN_PATH)riscv32-unknown-elf-
CC=$(TOOLCHAIN_PREFIX)gcc
CFLAGS=-Os -ggdb -I../ipl
OBJS:=rom.o irq.o gdbstub.o loadipl.o ipl_flash.o

default: rom.bin

%.o: %.S
	$(CC) -c -o $@ $^

rom.elf: $(OBJS) sections.lds
	$(CC) -Os -ffreestanding -nostdlib -o $@ \
		-Wl,-Bstatic,-T,sections.lds,-Map,rom.map,--strip-debug \
		$(OBJS) -lgcc

rom.bin: rom.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	$(TOOLCHAIN_PREFIX)objdump -S $< > rom.disasm
	$(CHMOD) -x $@

clean:
	rm -f rom.bin rom.elf $(OBJS)

send: send.c
	gcc -O2 -ggdb -o send send.c

.PHONY: clean