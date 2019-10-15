#pragma once

//Hardware definitions of the SoC. Also is the main repo of documentation for the
//programmer-centric view of the hardware.

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

/** Start of memory range for the UART peripheral */
#define UART_OFFSET		0x10000000
/** Offset of the data register for the debug UART. A write here will send the
    data out of the UART. A write when a send is going on will halt the processor
    until the send is completed. A read will receive any byte that was received by
    the UART since the last read, or 0xFFFFFFFF when none was. */
#define UART_DATA_REG	0x0
/** UART divisor register. Baud rate used by the UART is 48MHz/UART_DIV_REG. */
#define UART_DIV_REG	0x4
/** Data register for IrDA UART. Works similar to UART_DATA_REG. */
#define UART_IRDA_DATA_REG	0x8
/** Divisor register for IrDA UART. Works similar to UART_DIV_REG */
#define UART_IRDA_DIV_REG	0xC

/** Start of memory range for the 'misc' peripheral, containing all sorts of
    non-specific SoC functionality */
#define MISC_OFFSET 0x20000000
/** LED offset. The lower bits here map directly to a LED. Write to set the LED
    values. Reading reads the last written value.*/
#define MISC_LED_REG 0x0
/** Button register. Reads return the status of the buttons (pressed = 1). Writes
    get ignored. */
#define MISC_BTN_REG 0x4
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
#define MISC_SOC_VER 0x8
/** If this bit is set, the software is running in a Verilator simulation. 
    (If you find this bit set on the real badge, please take the red pill.)*/
#define MISC_SOC_VER_VERILATOR (1<<16)
/** This reads the ID of the current CPU reading this. */
#define MISC_CPU_NO 0xC
/** PSRAM I/O override register for PSRAM A. Used to bitbang the SPI lines to
    get the PSRAM in the proper QPI mode. (ToDo: document bits)*/
#define MISC_PSRAMOVRA_REG 0x10
/** PSRAM I/O override register for PSRAM B. */
#define MISC_PSRAMOVRB_REG 0x14
/** Reset register for various CPUs in the SoC. (ToDo: document) */
#define MISC_RESETN_REG 0x18
/** Flash control register. Used to read from / write to both the on-board as
    well as the cartridge flash. (ToDo: document)*/
#define MISC_FLASH_CTL_REG 0x1C
#define MISC_FLASH_CTL_CLAIM (1<<0)
#define MISC_FLASH_CTL_IDLE (1<<1)
/** Flash write register. (ToDo: document) */
#define MISC_FLASH_WDATA_REG 0x20
/** Flash read register. (ToDo: document) */
#define MISC_FLASH_RDATA_REG 0x24
/** Random number register. A read returns a fully random number. Do not read more
    than once every 32 clock cycles for maximum random-ness. */
#define MISC_RNG_REG 0x28
/** Flash selection register. Write a value to select a flash chip. Also
    is used to reboot the FPGA into the next bitstream by pulling the PROGRAMN pin. */
#define MISC_FLASH_SEL_REG 0x2C
/** Write this to select cartridge flash */
#define MISC_FLASH_SEL_CARTFLASH 1
/** Write this to select internal flash */
#define MISC_FLASH_SEL_INTFLASH 0
/** Write this to reload the FPGA. Note that ORring this with one of the
   MISC_FLASH_SEL_* values will reload the FPGA from that particular flash
   chip. */
#define MISC_FLASH_SEL_FPGARELOAD_MAGIC (0xD0F1A5<<8)
/** SAR ADC register. ToDo: document */
#define MISC_ADC_CTL_REG 0x30
#define MISC_ADC_CTL_ENA (1<<0)
#define MISC_ADC_CTL_VALID (1<<1)
#define MISC_ADC_CTL_DIV(x) (x<<16)
/** SAR ADC value readout */
#define MISC_ADC_VAL_REG 0x34
/** General I/O input register. Bits 29-0 reflect the values of the corresponding lines on the cartridge I/O connector. */
#define MISC_GENIO_IN_REG 0x38
/** General I/O output register. Bits 29-0 set the values of the cartridge lines that are selected as outputs. */
#define MISC_GENIO_OUT_REG 0x3C
/** General I/O output enable registers. Set 1 to any of the bits 29-0 to make the corresponding line into an output. */
#define MISC_GENIO_OE_REG 0x40
/** Write 1 to set register. Any write of 1 will set the corresponding bit in MISC_GENIO_OUT_REG to 1. */
#define MISC_GENIO_W2S_REG 0x44
/** Write 1 to clear register. Any write of 1 will set the corresponding bit in MISC_GENIO_OUT_REG to 0. */
#define MISC_GENIO_W2C_REG 0x48
/** Extended I/O input register. The bits here reflect the values of the corresponding lines on the cartridge I/O connector:
   (ToDo: insert mapping here)
   Bit 31 reflects the status of the input-only USB VDET line, which is high when a +5V voltage is on the USB VBUS line.
    */
#define MISC_GPEXT_IN_REG 0x4C
/** Extended I/O: if a pin is an output, the corresponding bit here will set its value */
#define MISC_GPEXT_OUT_REG 0x50
/** Extended I/O: output enable register */
#define MISC_GPEXT_OE_REG 0x54
/** Extended I/O: write 1 to set output register */
#define MISC_GPEXT_W2S_REG 0x58
/** Extended I/O: write 1 to clear output register */
#define MISC_GPEXT_W2C_REG 0x5C

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

Sprites are still a WiP, you can't use them yet.

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
    Note the pitch is in pixels. Field length is */
#define GFX_FBPITCH_PITCH_OFF 0
/** Bits [24:15]: Palette offset. This is added to the nibbles or bytes retrieved 
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
/** Background color register. If all the layers are disabled, or 
    if a pixel is transparent or translucent in all layers, this
    color 'shines through'. This is a RGBA color, but the alpha
    probably isn't that useful.*/
#define GFX_BGNDCOL_REG 0x28
/** Offset of all the sprites. Defaults to (64, 64) meaning that
    a sprite placed on x=64, y=64 will appear in the top left
    corner.
#define GFX_SPRITE_OFF_REG 0x28
/** [12:0]: Sprite X position that maps to left of screen */
#define GFX_SPRITE_OFF_X_OFF 0
/** [28:16]: Sprite Y position that maps to top of screen */
#define GFX_SPRITE_Y_OFF 16


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
/** Bit [17:11]: Palette offset. If this is set to i, the 16 colors of 
    the tile will be looked up in the palette memory starting from entry 
    (i*4). */
#define GFX_TILEMAP_ENT_PAL_OFF 11

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
/** Word 0, bits [29:16]: X position of top left corner of sprite */
#define GFX_SPRITE_ENT_YPOS_OFF 16
/** Word 0, bit [30]: X chain. Unused for now. */
#define GFX_SPRITE_ENT_YCHAIN (1<<30)
/** Word 0, bit [31]: X flip of tile. */
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

