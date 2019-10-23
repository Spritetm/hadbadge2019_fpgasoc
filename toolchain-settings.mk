#
# Setups the RISC-V toolchain
#

# Find a toolchain
POSSIBLE_CROSS = riscv-none-embed- riscv32-unknown-elf- riscv64-unknown-elf-

ifneq ("$(RISCV_TOOLCHAIN_PATH)", "")
POSSIBLE_CROSS := $(addprefix $(RISCV_TOOLCHAIN_PATH), $(POSSIBLE_CROSS))
endif

ifeq ("$(CROSS)", "")
CROSS := $(shell for c in $(POSSIBLE_CROSS); do which $${c}gcc >/dev/null 2>&1 && echo $${c} && break; done)
endif

ifeq ("$(CROSS)", "")
$(error Need a RISC-V toolchain)
endif

# Set prefixes and paths to all tools.
CC := $(CROSS)gcc
AR := $(CROSS)ar
LD := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump
SIZE := $(CROSS)size
STRIP := $(CROSS)strip
GDB := $(CROSS)gdb

ASFLAGS := -march=rv32imac -mabi=ilp32
CFLAGS  := -march=rv32imac -mabi=ilp32 -flto -Os
LDFLAGS := -march=rv32imac -mabi=ilp32 -flto -ffreestanding -nostartfiles -Wl,--gc-section -Wl,-Bstatic -Wl,-melf32lriscv
