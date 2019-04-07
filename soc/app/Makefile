TOOLCHAIN_DIR := /home/jeroen/hackaday2019/poc/toolchain/toolchain/bin
TOOLCHAIN_PREFIX := $(TOOLCHAIN_DIR)/riscv32-unknown-elf-
CC := $(TOOLCHAIN_PREFIX)gcc
OBJCOPY := $(TOOLCHAIN_PREFIX)objcopy
OBJS:=start.o main.o xprintf.o lcd.o UGUI/ugui.o
CFLAGS := -Os -IUGUI -I.

default: program

%.o: %.S
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -c -o $@ $^

#no-relax because https://github.com/riscv/riscv-binutils-gdb/issues/144
app.elf: $(OBJS) ldscript.ld
	$(CC) $(CFLAGS) -o $@ -ffreestanding -nostdlib \
		-Wl,-Bstatic -Wl,-T,ldscript.ld -Wl,-Map,app.map -Wl,--no-relax \
		$(OBJS) -lgcc

app.bin: app.elf
	$(OBJCOPY) -O binary $< $@
	$(TOOLCHAIN_PREFIX)objdump -S $< > app.disasm
	chmod -x $@

program: app.bin
	../boot/send app.bin /dev/ttyUSB0

clean:
	rm -f send
	rm -f app.elf app.bin $(OBJS)

.PHONY: clean
