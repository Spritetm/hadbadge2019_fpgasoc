#
# Setups the RISC-V toolchain
#

# Deal with Windows
ifeq ($(OS),Windows_NT)

	# We need the suffix (depends on exact shell you use, but some need it
	# and all allow it, so always set it)
EXE := .exe

	# Skip auto-detect. Not all env will have 'which' and most likely you're
	# using the prebuild toolchain. Always possible to override with CROSS=xxx
ifeq ("$(CROSS)", "")
CROSS := riscv64-unknown-elf-
endif
endif

# Find a toolchain
POSSIBLE_CROSS := riscv-none-embed- riscv32-unknown-elf- riscv64-unknown-elf-

ifneq ("$(RISCV_TOOLCHAIN_PATH)", "")
POSSIBLE_CROSS := $(addprefix $(RISCV_TOOLCHAIN_PATH)/, $(POSSIBLE_CROSS))
endif

# Search for toolchain with each of the possible names
ifeq ("$(CROSS)", "")
CROSS := $(shell for c in $(POSSIBLE_CROSS); do which $${c}gcc$(EXE) >/dev/null 2>&1 && echo $${c} && break; done)
endif

# If still not found toolchain, and on WSL, look for native windows toolchain
ifeq ("$(CROSS)", "")
	ifneq ("$(WSL_DISTRO_NAME)", "")
		EXE := .exe
		# Search again
		CROSS := $(shell for c in $(POSSIBLE_CROSS); do which $${c}gcc$(EXE) >/dev/null 2>&1 && echo $${c} && break; done)
	endif
endif

ifeq ("$(CROSS)", "")
$(info ERROR: We couldn't find a RiscV toolchain anywhere in your path or in RISCV_TOOLCHAIN_PATH.)
$(info ERROR: We looked for anything looking like $(POSSIBLE_CROSS) but couldn't find anything.)
$(error Aborting: Need a RISC-V toolchain)
endif

# Set prefixes and paths to all tools.
CC := $(CROSS)gcc$(EXE)
AR := $(CROSS)gcc-ar$(EXE)
LD := $(CROSS)ld$(EXE)
OBJCOPY := $(CROSS)objcopy$(EXE)
OBJDUMP := $(CROSS)objdump$(EXE)
SIZE := $(CROSS)size$(EXE)
STRIP := $(CROSS)strip$(EXE)
GDB := $(CROSS)gdb$(EXE)

ASFLAGS := -march=rv32imac -mabi=ilp32
CFLAGS  := -march=rv32imac -mabi=ilp32 -flto -Os
LDFLAGS := -march=rv32imac -mabi=ilp32 -flto -ffreestanding -nostartfiles -Wl,--gc-section -Wl,-Bstatic -Wl,-melf32lriscv
