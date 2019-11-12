The graphics subsystem
======================

Marketing blurb: The graphic subsystem in the SoC combines a framebuffer with tile-based 
rendering and a sprite layer. It has full alpha-transparency (except for sprite interaction), 
24-bit color support (with up to 256 colors in the frame buffer, and 16 colors per tiles) 
and can output at 60 frames per second. Sprites can be individually scaled; tile layers can
be rotated as well. A copper can help in changing parameters while drawing the screen at exactly
the right position, allowing for fancy display effects without using any CPU power. All of this
is rendered both to the build-in 480x320 LCD as well as upscaled from 480x320 and sent to the
HDMI port.

Note about the rest of this text: the memory addresses and registers referred herein are 
defined in
[ldscript.ld](apps-sdk/gloss/ldscript.ld) and [mach_defines.h](soc/ipl/gloss/mach_defines.h).

Layers
------

The graphics subsystem has 5 layers: the background, the framebuffer layer, the two tilemaps and
the sprite layer. These layers are always rendered in this order. Note that if a pixel in a certain
layer is rendered that has an alpha value that is not 0xFF, the color of that pixel will be
mixed with the underlying layer (alpha shading). If the alpha value of a pixel is 0, that pixel will
not be drawn at all and the pixel keeps the value that resulted from drawing the previous layers. Note
that the ordering of layers is fixed and cannot be changed. Note that all layers except for the background
layer can be disabled; it will not be drawn at all in that case.

* The background layer is rendered first. This is a single, opaque color.
* The framebuffer layer is rendered second.
* Tile layer A is rendered third.
* Tile layer B is rendered fourth.
* The sprite layer is drawn last.

Colors
------

In order to save memory, the data for the graphics is stored in an indexed format. That is, a
pixel is defined by an index of only 4 or 8 bits, leading to a maximumum of 16 or 256 
colors. In order to convert these indexes to RGBA values, the graphics hardware uses a
palette lookup memory consisting of 512 32-bit RGBA values. This memory can be accessed
as GFXPAL. As this memory defines more entries than the pixels can index, both the
tile memory as well as the sprites have an option to select an offset into this table. 
This allows for tiles that have separate palettes.

Background layer
----------------

This layer always has one single, opaque color. Unlike all other layers, the RGBA value of this
color is not obtained from the palette memory, but set by writing the RGBA value directly
into `GFX_BGNDCOL_REG.`

Framebuffer layer
-----------------

The framebuffer is a range of memory in main memory that is read by the graphics hardware using 
DMA and interpreted as pixels. The layer is enabled by setting the `GFX_LAYEREN_FB` bit in
`GFX_LAYEREN_REG`. The framebuffer can either be 4-bit, in which case each byte in the memory
region is interpreted as two pixels, or 8-bit in which case each byte is 1 pixel. In 4-bit mode,
the lower 4 bit are drawn right of the higher 4 bit.

The memory range that is drawn is freely selectable by writing the start address to `GFX_FBADDR_REG`.
The pitch of the image (that is, how much is added to the address for each next line) is written
to the lower 16 bits of `GFX_FBPITCH_REG`. Normally, you'd write either the width of the display 
(480) or the nearest power of two (512, so calculations get easier) here, but it's possible to 
use other values as well for e.g. horizontal scrolling.

To select between 4 and 8 bits, clear or set GFX_LAYEREN_FB_8BIT in GFX_LAYEREN_REG, respectively.
The palette entry offset for the pixel indexes can be set by writing to bit 24 to 16 of 
`GFX_FBPITCH_REG`.

Note that the IPL has helper functions (in [gfx_load.h](soc/ipl/syscallable/gfx_load.h)) that
can help loading a PNG or TGA into framebuffer memory.

Tiles
-----

Both the tilemap layer as well as the sprites use tiles as their source of graphics. Tiles, in this
graphics hardware implementation, are images of 16x16 pixels, where each pixel is a 4-bit index into
the palette table, as described above. The graphics hardware stores these in tile memory, at
`GFXTILES`. Each tile occupies a contiguous region of (16*16*4bit=)128 bytes here, and the tile
memory can store 512 tiles in total.

The tiles are stored in a left-to-right, top-to-bottom fashion, with the lower 4 bit in a byte to
the left of the top 4 byte:

```
0L   0H   1L   1H   2L   2H   3L   3H   4L   4H   5L   5H   6L   6H   7L   7H
8L   8H   9L   9H ...
...
120L 120H 121L 121H 122L 122H 123L 123H 124L 124H 125L 125H 126L 126H 127L 127H
```

Each tile has an index: the first tile in tile memory has index 0, the next one index 1
and so forth. These indexes are used in the tilemap and the sprites to select which tile
is drawn.

Note that, again, the IPL has helper functions (in [gfx_load.h](soc/ipl/syscallable/gfx_load.h)) that
can help loading a PNG or TGA into tile memory.


Tilemaps
--------

The graphics hardware has two tilemaps, A and B. The hardware processing these tilemaps
is exactly the same; the only differences are the locations of the registers and  that 
in the end composited image, tilemap B is drawn over tilemap A. Only tilemap A is described
here; the description for tilemap B can be gotten by replacing A with B in the register and
memory location names.

Tilemaps, as most other layers, can be enabled and disabled. Tilemap A is enabled by setting
the GFX_LAYEREN_TILEA bit in GFX_LAYEREN_REG, and disabled by clearing that bit.

Tilemaps start out with the actual map: a piece of memory containing a 'raster' defining which
tiles are drawn where. It's the same as a bitmap image, which defines which color is drawn at
which pixel, only instead of pixels, entire tiles are drawn. The tilemaps here are 64x64 tiles,
allowing them to define a 'virtual' image of 1024x1024 pixels. In the case of tilemap A, this
tilemap comes in the form of a memory of (64x64=)4096 32-bit entries at `GFXTILEMAPA`.

These 32 bit have the following meaning:

* Bit 0 - 8: Index of the tile at this position.
* Bit 9: If 1, the tile is drawn horizontally flipped.
* Bit 10: If 1, the tile is drawn vertically flipped.
* Bit 11: If 1, the tile is drawn 'diagonally flipped': X and Y is swapped.
* Bit 12 - 17: These bits set the palette offset, in increments of 8.

While it certainly is an option to draw the tilemap 1-to-1, there also are some options
to distort the tilemap in some way. Specifically, affine transforms can be done, including
shearing, scaling and rotating. All these are accomplished by 'disconnecting' the direct 
mapping between LCD pixels and tilemap pixels. To make this understandable, let's define
two 'cursors'. The LCD cursor points to a pixel on the LCD, while the virtual cursor points
to a pixel on the tilemap, defined as all the tiles pointed to in the tilemap assembled into
one big 1024x1024 image.

NOTE: All virtual cursor movement values should be written in increments of 1/64th tilemap
pixel. For instance, to get tilemap pixel (1,2) to show up at LCD position (0,0), you would
write an offset of (64,128) to `GFX_TILEA_OFF`. Also note that all values are signed.

- When the LCD cursor is at the top left of the screen (x=0, y=0), the virtual
cursor is placed at an X-position encoded in the lower 16 bits of `GFX_TILEA_OFF`,
and an Y-position encoded in the upper 16 bits of that register.

- For each pixel the LCD cursor goes to the right, the virtual cursor goes right by
the value defined in the lower 16 bit of `GFX_TILEA_INC_COL` and down by the upper 
16 bits of `GFX_TILEA_INC_COL`.

- For each pixel the LCD cursor goes down, the virtual cursor goes right by
the value defined in the lower 16 bit of `GFX_TILEA_INC_ROW` and down by the upper 
16 bits of `GFX_TILEA_INC_ROW`.

Note that after a reset, these registers are reset to have an 1-to-1 mapping between
virtual and LCD pixels. If that is what you need, there's no need to change these 
registers. The IPL is also guaranteed to start an elf file with the registers set 
like this.

Sprites
-------

The graphics hardware has support for placing sprites consisting of any 16x16 tile 
that can be placed onto any random location on the screen. These sprites can be 
scaled to as small as 1x1 or as large as 255x255 pixels. The amount of sprites per
scanline isn't limited to any fixed number, but a rule of thumb is that all X-sizes
added up shouldn't be more than 720 pixels, if not you run the risk of the most
high priority sprites not being drawn.

It should be noted that transparency between sprites is handled a bit differently than 
transparency in the rest of the graphics subsystem. The rest of the graphics 
subsystem uses the alpha value of the palette entry to 'mix' the color of the layer
and the color of the layer under it. In contrast, the sprite layer uses a single 
fixed fully transparent color index 0; if a sprite contains this color index, nothing
is drawn there and any previous sprite will shine through. This will have some weird
effects if sprites use palette entries that have semitranslucent alpha values: while
these sprites will work as expected when there's only background layers behind it, if
there is another sprite behind it, it looks like the sprite 'bites a chunk out of' the
sprite under it.

Another gotcha is that an empty sprite layer is entirely filled with palette entry
0x1FF. (Note: Gotta fix this; at the moment it's 0x100.) If this palette entry isn't
defined as entirely transparent, the other layers will have a 'sheen' over them; if the
palette entry is defined as opaque, the background layers will even be entirely
invisible.

The entire sprite layer can be given an offset using the `GFX_SPRITE_OFF_REG` register:
the lower 16 bits give the X offset, the higher 16 bits the Y offset. The default
offset is (64, 64), meaning a sprite with an x,y coordinate of 64,64 will have its
top left corner in the top left corner of the screen. The reason this is done is because
the sprites coordinates are unsigned, and having this offset allows sprites to 'peek
out' from the left or top side of the screen.

Sprite definitions are encoded in 2 32-bit words; the sprite definitions are stored
consecutively at `GFXSPRITES`:

Word 1:

* Bits 13 - 0 : X position of top left corner of sprite
* Bit 15 : Flip sprite horizontally when 1
* Bit 29 - 16 : Y position of sprite
* Bit 31 : Flip sprite vertically when 1

Word 2:
* Bit 7 - 0 : Drawing width of sprite, in pixels. 16 for no scale.
* Bit 15 - 8 : Drawing height of sprite, in pixels. 16 for no scale.
* Bit 24 - 16: Tile number the sprite uses
* Bit 31 - 25: Palette offset, in increments of 4 palette entries

Sprites are always drawn first-to-last, that is, if a sprite appears earlier
in the sprite memory and a later sprite overlaps it, the later sprite will
be drawn over the earlier one.

The Copper
----------

The copper is a very limited coprocessor that runs inside the graphics controller. It
is capable of changing any register or memory location inside the graphics controller
when it is rendering a specific coordinate on the display. The copper executes
its program, the so-called copper list, from copper memory at `GFXCOPPEROPS`.
The instructions are all 32-bit, and defined as such:

* `COPPER_OP_WAIT(x, y)` - Wait for the renderer to have reached a specific coordinate. Note
   that if other copper instructions have caused the renderer to already be past this coordinate,
   the copper will wait for the next frame to reach this point instead.
* `COPPER_OP_WRITE(addr, ct)` - This instructs the copper to take the next `ct` instructions
  as data and write it to the address specified in `addr` instead. While doing this, the 
  copper will automatically increment the destination address. For instance, by setting
  `addr` to the first palette entry and `ct` to 4, the copper will overwrite the first 4 palette
  entries with the words following this instruction. Note that ct needs to be between 1 and 4; if
  you need to write more data, use multiple `COPPER_OP_WRITE` instructions.
* `COPPER_OP_IRQ` will trigger an interrupt in the host (RiscV) processor when executed.
* `COPPER_OP_RESET` will reset the copper and restart it from instruction 0.

Note that the rendering engine will halt when the copper is actually writing to addresses; the current
X and Y position will only increase again when the copper is executing a non-write instruction.

A restriction of the copper is that it can write any address within the graphics subsystem, but it
can *only* write addresses within the graphics subsystem. An attempt to write elsewhere may lead
to unintended effects.

Another thing to note is that, as the renderer is pipelined, not all operations happen at the same time
and while processing e.g. the palette lookup of one pixel, the renderer may already be processing the
tilemap coordinate of the next one. Sprites are an entirely different special case: the sprite memory
itself is processed a line before the results are rendered; this happens in an order that's not
related to the renderers X position. However, mapping sprite color indexes to palette entries does
happen in the main render hardware, so palette changes will have the expected result.

The Hardware
============

The graphics hardware is implemented as a line renderer, that is, instead of rendering the entire frame
layer by layer, the hardware renders it a line at the time. The rendering logic is in 
[vid_linerenderer.v](soc/video/vid_linerenderer.v) which also includes the CPU interface, the tile
and framebuffer logic as well as the copper and palette logic. The sprite engine is located in a
separate file, [vid_spriteeng.v](soc/video/vid_spriteeng.v), and assembles a video line one line 
before the line renderer needs it to composite it into the final line. The line renderer will put
the finished lines into the logic of [video_mem.v](soc/video/video_mem.v), which implements a
buffer of up to four lines, used  as a FIFO. Inside this file, the data is actually written to two
of these FIFOs. One is being read out at the pixel clock of the HDMI encoder and scaled up to the
HDMI output resolution. As the pixel clock doesn't wait, this FIFO is leading in allowing the line 
renderer to push more lines into the FIFO. The secondary FIFO is read by the LCD logic, and as the
LCD interface is faster than the unscaled HDMI interface, output to the LCD is stopped when it 
'catches up' with the HDMI output.



