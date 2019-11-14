#pragma once

//Hardware definitions of the SoC. Also is the main repo of documentation for the
//programmer-centric view of the hardware.

/* -------------- Main machine defines --------------------- */

/** The external PSRAM starts here. The PSRAM is cached. */
#define MACH_RAM_START		0x40000000
/** Size of RAM on the badge */
#define MACH_RAM_SIZE		(16*1024*1024)
/** Cache flush region. To make sure all modifications to PSRAM are written
    back to the physical memory for a specific region (e.g. framebuffer memory),
    for a region that starts at MACH_RAM_START+start and ends at MACH_RAM_START+end,
    write 'end' to MACH_FLUSH_REGION+start. Make sure 'start' and 'end' are 4-bit
    aligned. */
#define MACH_FLUSH_REGION 	0x41000000

/** (Not specifically SoC-related) Start of RAM that contains the IPL. */
#define MEM_IPL_START		0x40002000
/** (Not specifically SoC-related) Start of RAM containing the application */
#define MEM_APP_START		0x40100000

/* -------------- UART defines --------------------- */

/** Start of memory range for the UART peripheral */
#define UART_OFFSET		0x10000000
/** Offset of the data register for the debug UART. A write here will send the
    data out of the UART. A write when a send is going on will halt the processor
    until the send is completed. A read will receive any byte that was received by
    the UART since the last read, or 0xFFFFFFFF when none was. There is no receive
    buffer, so it's possible to miss data if you don't poll frequently enough.
    The debug UART is always configured as 8N1. */
#define UART_DATA_REG	0x00
/** UART divisor register. Baud rate used by the UART is 48MHz/(UART_DIV_REG+2).
    Common rates: 115200 -> 414, 38400 -> 1248, 19200 -> 2498, 9600 -> 4998 */
#define UART_DIV_REG	0x04
/** Data register for IrDA UART. Works similar to UART_DATA_REG. */
#define UART_IRDA_DATA_REG	0x10
/** Divisor register for IrDA UART. Baud rate used by IrDA is 48MHz/(16*(UART_IRDA_DIV_REG+2))
 *  Common rate: 115200 -> 24, 38400 -> 76, 19200 -> 154, 9600 -> 310 */
#define UART_IRDA_DIV_REG	0x14

/* -------------- Misc register block defines --------------------- */

/** Start of memory range for the 'misc' peripheral, containing all sorts of
    non-specific SoC functionality */
#define MISC_OFFSET 0x20000000
/** LED offset. The lower bits here map directly to a LED. Write to set the LED
    values. Reading reads the last written value.*/
#define MISC_LED_REG (0*4)
/** Button register. Reads return the status of the buttons (pressed = 1). Writes
    get ignored. */
#define MISC_BTN_REG (1*4)
/** Bitmask for the 'up' button. */
#define BUTTON_UP (1<<0)
/** Bitmask for the 'down' button. */
#define BUTTON_DOWN (1<<1)
/** Bitmask for the 'left' button. */
#define BUTTON_LEFT (1<<2)
/** Bitmask for the 'right' button. */
#define BUTTON_RIGHT (1<<3)
/** Bitmask for the 'a' button. */
#define BUTTON_A (1<<4)
/** Bitmask for the 'b' button. */
#define BUTTON_B (1<<5)
/** Bitmask for the 'select' button. */
#define BUTTON_SELECT (1<<6)
/** Bitmask for the 'start' button. */
#define BUTTON_START (1<<7)
/** SoC version register. Reads return the SoC version. */
#define MISC_SOC_VER (2*4)
/** If this bit is set, the software is running in a Verilator simulation. 
    (If you find this bit set on the real badge, please take the red pill.)*/
#define MISC_SOC_VER_VERILATOR (1<<16)
/** This reads the ID of the current CPU reading this. */
#define MISC_CPU_NO (3*4)
/** Reset register for various CPUs in the SoC. (ToDo: document) */
#define MISC_RESETN_REG (6*4)
/** Flash control register. Used to read from / write to both the on-board as
    well as the cartridge flash. (ToDo: document)*/
#define MISC_FLASH_CTL_REG (7*4)
#define MISC_FLASH_CTL_CLAIM (1<<0)
#define MISC_FLASH_CTL_IDLE (1<<1) //RO
#define MISC_FLASH_CTL_DMADONE (1<<2) //RO
/** Flash write register. (ToDo: document) */
#define MISC_FLASH_WDATA_REG (8*4)
/** Flash read register. (ToDo: document) */
#define MISC_FLASH_RDATA_REG (9*4)
/* Flash DMA: memory address to write block to */
#define MISC_FLASH_DMAADDR (10*4)
/* Flash DMA: Start byte address in flash to read block from */
#define MISC_FLASH_RDADDR (11*4)
/* Flash DMA: Length. A write here starts a new DMA transfer. Check
   MISC_FLASH_CTL_DMADONE for status. */
#define MISC_FLASH_DMALEN (12*4)
/** Flash selection register. Write a value to select a flash chip. Also
    is used to reboot the FPGA into the next bitstream by pulling the PROGRAMN pin. */
#define MISC_FLASH_SEL_REG (13*4)
/** Write this to select cartridge flash */
#define MISC_FLASH_SEL_CARTFLASH 1
/** Write this to select internal flash */
#define MISC_FLASH_SEL_INTFLASH 0
/** Write this to reload the FPGA. Note that ORring this with one of the
   MISC_FLASH_SEL_* values will reload the FPGA from that particular flash
   chip. */
#define MISC_FLASH_SEL_FPGARELOAD_MAGIC (0xD0F1A5<<8)
/** Random number register. A read returns a fully random number. Do not read more
    than once every 32 clock cycles for maximum random-ness. */
#define MISC_RNG_REG (14*4)
/** SAR ADC register. ToDo: document */
#define MISC_ADC_CTL_REG (15*4)
#define MISC_ADC_CTL_ENA (1<<0)
#define MISC_ADC_CTL_VALID (1<<1)
#define MISC_ADC_CTL_DIV(x) (x<<16)
/** SAR ADC value readout */
#define MISC_ADC_VAL_REG (16*4)
/** General I/O input register. Bits 29-0 reflect the values of the corresponding lines on the cartridge I/O connector. */
#define MISC_GENIO_IN_REG (17*4)
/** General I/O output register. Bits 29-0 set the values of the cartridge lines that are selected as outputs. */
#define MISC_GENIO_OUT_REG (18*4)
/** General I/O output enable registers. Set 1 to any of the bits 29-0 to make the corresponding line into an output. */
#define MISC_GENIO_OE_REG (19*4)
/** Write 1 to set register. Any write of 1 will set the corresponding bit in MISC_GENIO_OUT_REG to 1. */
#define MISC_GENIO_W2S_REG (20*4)
/** Write 1 to clear register. Any write of 1 will set the corresponding bit in MISC_GENIO_OUT_REG to 0. */
#define MISC_GENIO_W2C_REG (21*4)
/** Extended I/O input register. The bits here reflect the values of the corresponding lines on the cartridge I/O connector:
   (ToDo: insert mapping here)
   Bit 31 reflects the status of the input-only USB VDET line, which is high when a +5V voltage is on the USB VBUS line.
    */
#define MISC_GPEXT_IN_REG (22*4)
/** Extended I/O: if a pin is an output, the corresponding bit here will set its value */
#define MISC_GPEXT_OUT_REG (23*4)
/** Extended I/O: output enable register */
#define MISC_GPEXT_OE_REG (24*4)
/** Extended I/O: write 1 to set output register */
#define MISC_GPEXT_W2S_REG (25*4)
/** Extended I/O: write 1 to clear output register */
#define MISC_GPEXT_W2C_REG (26*4)

/* -------------- LCD interface defines --------------------- */

/** Offset to the LCD controller. This allows you to send commands and data directly to the LCD. Note
    that normally this is not used aside from setting up the LCD; actual graphics are pushed automatically
    through the GFX subsystem. */
#define LCD_OFFSET 0x30000000
/** Command register. Poke an 16-bit command in here to send it to the LCD. */
#define LCD_COMMAND_REG 0x0
/** Data register. Poke an 16-bit data word in here to send it to the LCD. */
#define LCD_DATA_REG 0x4
/** Control register. Contains various bits that control the LCD. */
#define LCD_CONTROL_REG 0x8
/** Backlight enable. Set 1 to light up the backlight. */
#define LCD_CONTROL_BLEN (1<<0)
/** Reset line to the LCD */
#define LCD_CONTROL_RST (1<<1)
/** Chip select line for the LCD */
#define LCD_CONTROL_CS (1<<2)
/** Start handing over control to the GFX subsystem. This will set the
    LCD_CONTROL_FBENABLE bit when the next frame starts. */
#define LCD_CONTROL_FBSTART (1<<3)
/** Hand over control to the GFX subsystem. When set, the GFX subsystem will send pixel data
    to the display. */
#define LCD_CONTROL_FBENA (1<<4)
/** LCD status register */
#define LCD_STATUS_REG 0xC
/** Output of the FMARK LCD pin */
#define LCD_STATUS_FMARK (1<<0)
/** Output of the ID LCD pin */
#define LCD_STATUS_ID (1<<1)
/** Command that is sent before a new frame is transmitted. */
#define LCD_FB_STARTCMD 0x10
/** Backlight PWM width control. Lower 16 bits control how much backlight to give, 
    if LCD_CONTROL_BLEN set in LCD_CONTROL_REG. */
#define LCD_BL_LEVEL_REG 0x14

/* -------------- GFX subsystem defines --------------------- */

/** 
Memory address base of the registers of the graphics subsystem 

The GFX subsystem has four layers: the framebuffer layer, two tile
layers and one sprite layer. The framebuffer layer is generated by
using a user-specified framebuffer memory region in PSRAM and
interpreting the bytes or nibbles in there as a 4- or 8-bit bitmap.
That data is then used verbatim as a graphics layer.

The tile layers work as follows. Every 64 bytes in the tile memory are
interpreted as an 16x16-pixel, 4-bit image known as a 'tile'. As the
tile memory is 16K, this means there is a total of 512 tiles. These tiles
are shared between the two tile layers and the sprite layer.

A tilemap is an 64x64 map of 9-bit indexes into the tile memory: it 
describes a 'virtual' (64*16)x(64x16)=1024x1024 bitmap. This 'virtual'
bitmap is then referred to when filling in the 'real' 480x32 layer that
goes to the LCD/HDMI: the pixel at (0,0) is looked up in the 'virtual'
bitmap at (x,y)=(GFX_TILEx_OFF.x,GF_TILEx_OFF.y). Then, for each increase
in X on the 'real' layer, (GFX_TILEx_INC_COL.x,GFX_TILEx_INC_COL.y) is 
added to the (x,y) coordinates, while for each increase in Y, 
(GFX_TILEx_INC_ROW.x,GFX_TILEx_INC_ROW.y) is added. Note that all these
values are specified in (1/64)th pixel, so e.g. to make the 'real' (0,0)
pixel map to the 'virtual' (10, 20) pixel, you would set 
GFX_TILEA_OFF to (640<<16)|1280.

Sprites are defined in their own memory. Each sprite has a position
on screen and an associated 16x16 tile from the main tile memory. Sprites
can be scaled, that is, you can set an X and Y size and the sprite will
scale the 16x16 tile to be that size. Note that palette index 0 in these
sprites always is transparent. Other palette entries may be transparent
using alpha values, however this will only apply when a single sprite is 
placed over a background. If sprites are placed over eachother, if a 
non-zero palette index pixel is placed, it will always entirely overwrite
the sprite pixel that was there beforehand.

A note on colors: When compositing the final layers, all tile / FB colors 
are looked up in the palette memory, resulting in a bunch of RGBA colors. These
are mixed according to their alpha values, so it's possible to create 
semitranslucent effects. When RGBA values need to be specified, (e.g. to
fill the palette memory), the fields are
[31:24]: Alpha value. 0xff is opaque, 0x0 is fully transparent
[23:16]: Red value
[15:8]: Green value
[7:0]: Blue value
*/
#define GFX_OFFSET_REGS 0x50000000
/** Memory address of a buffer that is used as a frame buffer, i.e. it will
    be read out verbatim, its bytes (in 8-bit mode) or nibbles (in 4-bit mode)
    will be looked up in palette memory and the results will be used verbatim
    as the FB layer. */
#define GFX_FBADDR_REG 0x00
/** Register describing the pitch and palette offset of the framebuffer */
#define GFX_FBPITCH_REG 0x04
/** Bits [15:0]: Pitch (length of one row of pixel data) of the framebuffer bitmap. 
    Note the pitch is in pixels. Must be a multiple of 4 for 8-bit pixels or 8 for
    4-bit pixels, or else display artifacts will be evident. */
#define GFX_FBPITCH_PITCH_OFF 0
/** Bits [24:16]: Palette offset. This is added to the nibbles or bytes retrieved 
    from framebuffer, and the result is used as an address into the palette memory
    to read the actual color. */
#define GFX_FBPITCH_PAL_OFF 16
/** Layer enable / misc register */
#define GFX_LAYEREN_REG 0x08
/** Framebuffer layer enable. If 1, the framebuffer is displayed.  Note
    that disabling this also disables the DMA retrieving the framebuffer
    pixels, leading to a slight speedup of the rest of the system. */
#define GFX_LAYEREN_FB (1<<0)
/** Tile A enable register. If 1, the tile B layer is displayed. */
#define GFX_LAYEREN_TILEA (1<<1)
/** Tile B enable register. If 1, the tile B layer is displayed. */
#define GFX_LAYEREN_TILEB (1<<2)
/** Sprite enable register. If 1, the sprite layer is displayed. */
#define GFX_LAYEREN_SPR (1<<3)
/** Set this to 1 to make the framebuffer memory contain 8-bit values,
    making for a 256-color framebuffer. If 0, the framebuffer memory
    is only 4-bit, giving an 16-bit bitmap. */
#define GFX_LAYEREN_FB_8BIT (1<<16)
/** Register to specify where in the virtual tilemap space the 'real'
    (0,0) retrieves its data from. */
#define GFX_TILEA_OFF 0x0C
/** Bits [0-15]: X-offset. Note this is in 1/64th increments. */
#define GFX_TILEA_X_OFF_OFF 0
/** Bits [31:16]: Y-offset. Note this is in 1/64th increments. */
#define GFX_TILEA_Y_OFF_OFF 16
/** Register to specify where in the virtual tilemap space the 'real'
    (0,0) retrieves its data from. */
#define GFX_TILEB_OFF 0x10
/** Bits [0-15]: X-offset. Note this is in 1/64th increments. */
#define GFX_TILEB_X_OFF_OFF 0
/** Bits [31:16]: Y-offset. Note this is in 1/64th increments. */
#define GFX_TILEB_Y_OFF_OFF 16
/** Register defining what gets added to the virtual (x,y) coordinate
    when the real X coordinate increments by 1. */
#define GFX_TILEA_INC_COL 0x14
/** Bits [15:0]: X value added. (1/64) of a pixel increments. 
    Defaults to 64 for 1:1 mapping. */
#define GFX_TILEA_INC_COL_X_OFF 0
/** Bits [32:15]: Y value added. (1/64) of a pixel increments. 
    Defaults to 0 for 1:1 mapping. */
#define GFX_TILEA_INC_COL_Y_OFF 16
/** Register defining what gets added to the virtual (x,y) coordinate
    when the real Y coordinate increments by 1. */
#define GFX_TILEA_INC_ROW 0x18
/** Bits [15:0]: X value added. (1/64) of a pixel increments. 
    Defaults to 64 for 1:1 mapping. */
#define GFX_TILEA_INC_ROW_X_OFF 0
/** Bits [32:15]: Y value added. (1/64) of a pixel increments. 
    Defaults to 0 for 1:1 mapping. */
#define GFX_TILEA_INC_ROW_Y_OFF 16
/** Same registers, for tile layer B */
#define GFX_TILEB_INC_COL 0x1C
#define GFX_TILEB_INC_COL_X_OFF 0
#define GFX_TILEB_INC_COL_Y_OFF 16
#define GFX_TILEB_INC_ROW 0x20
#define GFX_TILEB_INC_ROW_X_OFF 0
#define GFX_TILEB_INC_ROW_Y_OFF 16
/** Read-only register: indicates the current video position being 
    processed by the gfx hardware. (Note the real HDMI/LCD output
    lags give-or-take a few lines behind this position.) */
#define GFX_VIDPOS_REG 0x24
/** [15:0]: X position being currently processed */
#define GFX_VIDPOS_X_OFF 0
/** [32:16]: Y position being currently processed */
#define GFX_VIDPOS_Y_OFF 16
/** Read-only: Amount of vertical blanks processed. This increases 
    when the line renderer is done processing a frame and is waiting
    for the next one to begin. As this is a 32-bit value and counts 
    up at 60Hz it will overflow every 2 years or so.*/
#define GFX_VBLCTR_REG 0x28
/** Background color register. If all the layers are disabled, or 
    if a pixel is transparent or translucent in all layers, this
    color 'shines through'. This is a RGBA color, but the alpha
    probably isn't that useful.*/
#define GFX_BGNDCOL_REG 0x2C
/** Offset of all the sprites. Defaults to (64, 64) meaning that
    a sprite placed on x=64, y=64 will appear in the top left
    corner. */
#define GFX_SPRITE_OFF_REG 0x30
/** [12:0]: Sprite X position that maps to left of screen */
#define GFX_SPRITE_OFF_X_OFF 0
/** [28:16]: Sprite Y position that maps to top of screen */
#define GFX_SPRITE_Y_OFF 16
/** Copper control register */
#define GFX_COPPER_CTL_REG 0x34
/** [31]: Copper enable register. Setting this enables the copper. 
    Clearing this disables & resets the copper. */
#define GFX_COPPER_CTL_RUN (1<<31)
/** [30:0]: Current copper PC. Indicates which word in the copper
    list (at GFX_OFFSET_COPPERMEM) the copper is currently 
    processing. Read-only. */
#define GFX_COPPER_PC_OFF 0

/** Memory address of the palette memory. This is a 512-entry
    memory containing 32-bit RGBA values. */
#define GFX_OFFSET_PAL 0x50002000

/** Memory address to tilemap A. This is indexed as an array
    of 32-bit fields. */
#define GFX_OFFSET_TILEMAPA 0x50004000
/** Memory address to tilemap B. This is indexed as an array
    of 32-bit fields. */
#define GFX_OFFSET_TILEMAPB 0x50008000
/** Width of tilemap A/B, in tiles */
#define GFX_TILEMAP_W 64
/** Height of tilemap A/B, in tiles */
#define GFX_TILEMAP_H 64

/* A tilemap entry is defined as follows: */
/** Bits [8:0]: Tile to use for this entry */
#define GFX_TILEMAP_ENT_TILE_OFF 0
/** Bit [9]: Flip tile horizontally */
#define GFX_TILEMAP_ENT_FLIP_X (1<<9)
/** Bit [10]: Flip tile vertically */
#define GFX_TILEMAP_ENT_FLIP_Y (1<<10)
/** Bit [10]: Swap x and y of tile (diagonal flip). This happens before the other flips. */
#define GFX_TILEMAP_ENT_SWAP_XY (1<<11)
/** Bit [17:12]: Palette offset. If this is set to i, the 16 colors of 
    the tile will be looked up in the palette memory starting from entry 
    (i*8). */
#define GFX_TILEMAP_ENT_PAL_OFF 12

/** Memory address of the sprites. This is contains 256 2x32-bit
    words containing the sprite data for 256 sprites. Note that 
    sprite addresses are offset by GFX_SPRITE_OFF register contents
    defaulting to (64, 64); in other words placing a sprite at 
    (64,64) makes it appear in the top right corner. Also note negative
    sprite positions won't work, hence the need for an offset.*/
#define GFX_OFFSET_SPRITE 0x5000C000
/** Word 0, bits [13:0]: X position of top left corner of sprite */
#define GFX_SPRITE_ENT_XPOS_OFF 0
/** Word 0, bit [14]: X chain. Unused for now. */
#define GFX_SPRITE_ENT_XCHAIN (1<<14)
/** Word 0, bit [15]: X flip of tile. */
#define GFX_SPRITE_ENT_XFLIP (1<<15)
/** Word 0, bits [29:16]: Y position of top left corner of sprite */
#define GFX_SPRITE_ENT_YPOS_OFF 16
/** Word 0, bit [30]: Y chain. Unused for now. */
#define GFX_SPRITE_ENT_YCHAIN (1<<30)
/** Word 0, bit [31]: Y flip of tile. */
#define GFX_SPRITE_ENT_YFLIP (1<<31)
/** Word 1, bit [7:0]: X size. The tile for this sprite will be scaled horizontally
    to this size, in pixels. 16 for no scale.*/
#define GFX_SPRITE_ENT_XSIZE_OFF 0
/** Word 1, bit [15:8]: Y size. The tile for this sprite will be scaled vertically
    to this size, in pixels. 16 for no scale. */
#define GFX_SPRITE_ENT_YSIZE_OFF 8
/** Word 1, bit [24:16]: Tile number that this sprite uses. */
#define GFX_SPRITE_ENT_TILE_OFF 16
/** Word 1, bit [31:25]: Palette selection. */
#define GFX_SPRITE_ENT_PALSEL_OFF 25



/* Offset to tile memory. This contains the pixel data of all 512 tiles
as 32 32-bit words. The pixel data is stored little-endian, so e.g:
pixel (0,0) of a tile is stored in bits [3:0] of word 0
pixel (1,0) of a tile is stored in bits [7:4] of word 0
pixel (8,0) of a tile is stored in bits [3:0] of word 1
pixel (0,1) of a tile is stored in bits [3:0] of word 2
*/
#define GFX_OFFSET_TILEMEM 0x50010000

/**
 Offset to copper memory. The copper is a tiny video 'coprocessor'
 with a very limited set of instructions: the main two are to wait 
 until the  graphics processor has reached a certain (x/y)-coordinate 
 and to poke words into the GFX registers. This can be used to e.g
 change palettes, scaling factors, locations etc at a random point
 during screen rendering, allowing for some creative effects without
 having to use the CPU. Note that the coppermem region is 2K-words
 in size. */
#define GFX_OFFSET_COPPERMEM 0x50020000

/* This instruction makes the coprocessor wait until the graphics
 processor has reached a certain (x,y) coordinate. Use coordinates
 (0,0) to wait for a new screen to be drawn. Note that sprites 
 graphics are actually calculated one line earlier than they are 
 drawn. */
#define COPPER_OP_WAIT(x, y) (0x80000000 | (y<<16) | (x))

/* This instruction resets the copper PC to the start of the copper
 list, making it start over. */
#define COPPER_OP_RESET 0x90000000

/* This instruction generates an interrupt. */
#define COPPER_OP_IRQ 0xA0000000

/* This instruction prepares a write of one to four words to consecutive
 addresses in the graphics subsystem. addr is the same address as the main
 RiscV processor would use to write into the register. Ct is the number
 of words that are written, from 1 to 4. The word data follows this 
 instruction and is written into consecutive addresses. */
#define COPPER_OP_WRITE(addr, ct) (((uint32_t)addr & 0xfffffffc)|(ct-1))

/* -------------- PIC peripheral defines --------------------- */

#define PIC_OFFSET_REGS 0x70000000

#define PIC_CTL_REG 0x0
#define PIC_CTL_RESET (1<<0)
#define PIC_CTL_INT0 (1<<1)
#define PIC_CTL_PASSTHRU (1<<2)
#define PIC_OFFSET_DATAMEM 0x70004000
#define PIC_OFFSET_PROGMEM 0x70008000

/* -------------- USB peripheral defines --------------------- */

/** Offset to USB core. Please refer to the USB IP for info on how
    this can be used.*/
#define USB_CORE_OFFSET 0x60000000
/** Offset to the USB core registers */
#define USB_COREREGS 0x00000
/** Offset to USB core receive memory. Read-only. */
#define USB_RXMEM    0x10000
/** Offset to USB core transmit memory. Write-only. */
#define USB_TXMEM    0x20000

#define USB_DATA_BASE_RX (USB_CORE_OFFSET+USB_RXMEM)
#define USB_DATA_BASE_TX (USB_CORE_OFFSET+USB_TXMEM)

/* -------------------- Audio / Synthesizer defines ------------------- */
/* 
The FPGA SoC has a dedicated synthesizer (loosely inspired by the SID) and
an audio output subsystem.  The board itself has a single logic output pin 
that passes through a lowpass RC filter into an amplifier.

The rest is done in code.

The synthesizer has eight simultaneous voices, mixed together with fixed 
volume in two groups.  Each voice has its own attack and release parameters, 
and can be set to sound for a given duration.  Attack and release are each 
eight bit values, set in per-voice configuration registers.

Sending a duration and pitch to a voice's "play" register makes it start 
immediately into its attack phase, play for the duration, and then taper
slowly off according to the release value. Note that you are responsible
for timing.  The synth just handles duration.

There is a README in the soc/audio subdirectory if you want to know more,
but this should get you started.

## Layout:

80000000 Voice 0 : Sawtooth
80000010 Voice 1 : Sawtooth
80000020 Voice 2 : Pulse + Sub
80000030 Voice 3 : Square
80000040 Voice 4 : Triangle
80000050 Voice 5 : Triangle
80000060 Voice 6 : Triangle
80000070 Voice 7 : Triangle

800000C0 Raw PCM input: 14-bit samples, but hit it with whatever you got 
         Sample rate is determined by whatever you push in,

800000D0 Drums (Still TBD) Bits: Kick drum, Snare, Hat/Cymbal, Cowbell

800000F0 Config register

## Voice Registers: for voice and drums X

0x800000X0: PLAY register: 
	    0xDDDDPPPP Pitch accumulator and duration. 
0x800000X4: CONFIG register: 
	    0x0000RRAA Attack and release are both 0-255	    
0x800000X8: Filter parameters, reserved.
0x800000XC: Beats me.

## PCM Register: just write raw data in

800000C0:  PCM_PLAY:
	   0x0000PPPP 16-bit PCM data, mixed with the synth voices 
           Note: PCM can get loud. Try global volumes around 0x0100.

## Config Register:
0x800000F0: VOLume
	    0x0000VVVV Sixteen bit global volume. 
	    0x200 is nominal for four simultaneous voices
	    If it's distorting, turn it down.

## Examples:
   SYNTHREG(AUDIO_CONFIG_VOLUME) = 0x100; 
   will set master volume a little lower, good for PCM or many voices
   (see audio.c and audio.h in IPL for tables)

   SYNTHREG(AUDIO_VOICE_SAW1 + AUDIO_CONFIG_REG_OFFSET) = \
			AUDIO_ATTACK(10) + AUDIO_RELEASE(255);
   sets the SAW1 voice to a very slow attack and a nearly instant release
   
   SYNTHREG(AUDIO_VOICE_SAW1) = AUDIO_PITCH(0x0C00) + AUDIO_DURATION(0x0120);
   will play the sawtooth voice 1 for around 100 ms at around 137 Hz
*/

#define AUDIO_CORE_BASE         0x80000000
#define AUDIO_PLAY_REG_OFFSET   0x0
#define AUDIO_CONFIG_REG_OFFSET 0x4
#define AUDIO_FILTER_REG_OFFSET 0x8 // (TBD)
#define AUDIO_MISC_REG_OFFSET   0xC // (TBD)

#define AUDIO_VOICE_SAW1   0x00
#define AUDIO_VOICE_SAW2   0x10
#define AUDIO_VOICE_PULSE  0x20
#define AUDIO_VOICE_SQUARE 0x30
#define AUDIO_VOICE_TRI1   0x40
#define AUDIO_VOICE_TRI2   0x50
#define AUDIO_VOICE_TRI3   0x60
#define AUDIO_VOICE_TRI4   0x70

#define AUDIO_PITCH(x)    (x)
#define AUDIO_DURATION(x) (x << 16)

#define AUDIO_ATTACK(x)   (x)
#define AUDIO_RELEASE(x)  (x << 8)

#define AUDIO_PCM           0xC0
#define AUDIO_DRUMS         0xD0
#define AUDIO_CONFIG_VOLUME 0xF0

/* -------------- PSRAM peripheral defines --------------------- */

/** Offset of the manual control for PSRAM */
#define PSRAM_CMD_OFFSET 0x90000000

#define PSRAM_CMD_CSR		0x00
#define PSRAM_CMD_RSP_NOWAIT	0x08
#define PSRAM_CMD_RSP_BLOCK	0x0C
#define PSRAM_CMD_SPI_WR_16B	0x20
#define PSRAM_CMD_SPI_WR_32B	0x24
#define PSRAM_CMD_SPI_RD_16B	0x28
#define PSRAM_CMD_SPI_RD_32B	0x2C
#define PSRAM_CMD_QPI_WR_16B	0x30
#define PSRAM_CMD_QPI_WR_32B	0x34
#define PSRAM_CMD_QPI_RD_16B	0x38
#define PSRAM_CMD_QPI_RD_32B	0x3C
