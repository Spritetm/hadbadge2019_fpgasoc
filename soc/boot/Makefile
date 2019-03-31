TOOLCHAIN_DIR := /home/jeroen/prog/fpga/picorv32/toolchain/bin
TOOLCHAIN_PREFIX := $(TOOLCHAIN_DIR)/riscv32-unknown-elf-

OBJS:=rom.o

default: rom.bin

%.o: %.S
	$(TOOLCHAIN_PREFIX)gcc -c -o $@ $^

rom.elf: $(OBJS) sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -ffreestanding -nostdlib -o $@ \
		-Wl,-Bstatic,-T,sections.lds,-Map,rom.map,--strip-debug \
		$(OBJS) -lgcc

rom.bin: rom.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

clean:
	rm -f rom.bin rom.elf $(OBJS)

.PHONY: clean