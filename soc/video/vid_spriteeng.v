/*

Sprite engine.

Comparison:
GBA: 128 sprites, 8x8-64x64
SNES: 128 sprites, 8x8-64x64, 32/scanline max
Genesis: 80 sprites, 8x8-32x32, 20/scanline max
Amiga: 8 sprites, 16x? wide
Atari ST: no hw sprites

The logic here is: we have 1920 cycles (480*4) to generate a line of sprites. This means walking
the OAM memory, inspecting which sprites need to be drawn, and squirting them to a line buffer. We
also have 2/4 cycles to grab a pixel of tile info. (But we can grab 32-bit of pixel data at once
if we want to.)

What we would like:
- Scaling sprites would be awesomesauce. (We're only gonna assume positive scaling, so xend>xstart and yend>ystart.)
- Multi-sized sprites als would be nice.

The Issues:
- We need to figure out if we need to draw the sprite at the current line.
  * In case we store sprite size in pixels, this is easy: xstart < xcur < xstart+xsize
  * In case we store increment in tilememory, this is hard: xtart < xcur < xstart+xsize/dx
- We need to figure out the current pixel value (in tilemem) to draw.
  * In case we store sprite size in pixels: tilex=(xcur-xstart)/xsize*tilesize
    --> PITA because divide by non-const (xsize)
    --> Alternative: for each tile pixel, figure out up to where it is supposed to go, then
        draw the pixel val until we reached that pixel.
        --> Problem: from which Ypos to draw? Need: tiley=(ycur-ystart)/ysize*tilesize...
  * In case we store 

  Solution: - 8-bit spritesize & LUT for spritesize -> tilepos_inc?
  - Means we can have sprites of 1x1 up to 256x256 -> enough.
  - Seeing if we need to draw a sprite is trivial.
  - Finding ypos = ypos_in_fb * lutval
  - Finding xpos = xpos_in_fb * lutval


OAM memory. Need to store:
- Tile (9-bit)
- Xpos (10-bit)
- Ypos (10-bit)
- Xsize (8-bit)
- Ysize (8-bit)
- flags (9-bit?)
  - size_sel 2-bit: 16x16, 32x32, 64x64?
  - flip_x?
  - flip-y?
  - pal_sel (5-bit)

Total 54 bits. Dump it in 64-bit perhaps?
w1:
0-9: Xpos
15: flip-x
16-27: ypos
31: flip-y
w2:
0-7: xsize
9-15: ysize
16-24: tile
25-26: sizesel
27-31: pal_sel



EBR is 512x18. Say we store:

- Ypos / Ysize





- Ypos/Ysize/flag_b
- Tile/Flags
- ?/?



Output memory... we need to compose a line at a time, then send it to the line renderer.

*/

module vid_spriteeng (
	input clk,
	input reset,

	input [8:0] cpu_addr,
	input [31:0] cpu_din,
	output [31:0] cpu_dout,
	input [3:0] cpu_wstrb,

	input [8:0] vid_xpos,
	input [8:0] vid_ypos,
	output [8:0] sprite_pix,
	input pix_done //set to 1 if done with the current pixel
);

reg [7:0] spritemem_addr;
wire [63:0] spritemem_out;

vid_spritemem spritemem (
	.ClockA(clk),
	.ClockB(clk),
	.ClockEnA(1),
	.ClockEnB(1),
	.ResetA(reset),
	.ResetB(reset),
	.ByteEnA(cpu_wstrb),
	.ByteEnB(0),
	.AddressA(cpu_addr),
	.AddressB(spritemem_addr),
	.WrA(cpu_wstrb!=0),
	.WrB(0),
	.DataInA(cpu_din),
	.DataInB(0),
	.QA(cpu_dout),
	.QB(spritemem_out)
);

wire [10:0] linebuf_out_addr;
assign linebuf_out_addr = {1'b0, vid_ypos[0], vid_xpos};

reg [8:0] lb_xpos;
wire [10:0] linebuf_w_addr;
assign linebuf_w_addr = {1'b0, ~vid_ypos[0], lb_xpos};
reg [8:0] lb_din;
reg lb_wr;
wire [8:0] lb_dout;

vid_sprite_linebuf linebuf(
	.ClockA(clk),
	.ClockB(clk),
	.ClockEnA(1),
	.ClockEnB(1),
	.ResetA(reset),
	.ResetB(reset),
	.AddressA(linebuf_out_addr),
	.DataInA(9'h1ff),
	.WrA(pix_done),
	.QA(sprite_pix),
	.AddressB(linebuf_w_addr),
	.DataInB(lb_din),
	.WrB(lb_wr),
	.QB(lb_dout)
);

always @(posedge clk) begin
	lb_xpos <= vid_ypos;
	lb_din <= 'h123;
	lb_wr <= 1;
end

endmodule