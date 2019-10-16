/*

Sprite engine.

Comparison:
GBA: 128 sprites, 8x8-64x64
SNES: 128 sprites, 8x8-64x64, 32/scanline max
Genesis: 80 sprites, 8x8-32x32, 20/scanline max
Amiga: 8 sprites, 16x? wide
Atari ST: no hw sprites
This: 512 sprites, 16x16, max 58'ish per scanline when unscaled

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

Output memory... we need to compose a line at a time, then send it to the line renderer.

*/

module vid_spriteeng (
	input clk,
	input reset,

	input [8:0] cpu_addr,
	input [31:0] cpu_din,
	output [31:0] cpu_dout,
	input [3:0] cpu_wstrb,
	input [12:0] offx,
	input [12:0] offy,

	input [8:0] vid_xpos,
	input [8:0] vid_ypos,
	output [8:0] sprite_pix,
	input pix_done, //set to 1 if done with the current pixel
	
	output [3:0] tilemem_x,
	output [3:0] tilemem_y,
	output [8:0] tilemem_no,
	input [3:0] tilemem_data,
	//Note: this being high means 'I have processed your input, feel free to change your output,
	//you will get your data the next cycle.
	input tilemem_ack 
);

wire [7:0] spritemem_addr;
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
	.DataInA(cpu_din),
	.WrA(cpu_wstrb!=0),
	.QA(cpu_dout),
	.AddressB(spritemem_addr),
	.DataInB(0),
	.WrB(0),
	.QB(spritemem_out)
);

wire [10:0] linebuf_out_addr;
assign linebuf_out_addr = {1'b0, vid_ypos[0], vid_xpos};

wire [13:0] lb_xpos;
reg [10:0] linebuf_w_addr;
reg [10:0] linebuf_w_addr_next;
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
	.DataInA(~0),
	.WrA(pix_done),
	.QA(sprite_pix),
	.AddressB(linebuf_w_addr),
	.DataInB(lb_din),
	.WrB(lb_wr),
	.QB(lb_dout)
);

/*
 Because we have very few cycles here, the loop through the sprite memory is
 pipelined:
 - Stage 1: Dump spritemem_addr into sprite mem. Mem takes 1 clock cycle to resolve this. 
            Also increase spritemem_addr
 - Stage 2: Memory is slow - dump into the pipeline registers
 - Stage 3: Fetch sprite data. Feed size_y into LUT ROM to get dy.
 - Stage 4: Feed DY into multiplier to get tile_ypos.
 - Stage 5: Check if sprite needs to be drawn. If so, send entire set of data we retrieved to
            sprite draw logic.
 - Stage 6: pipeline hangs here if sprite drawing hw is busy

Data format is 64 bit:
[12:0] xpos
[14] xchain
[15] xflip
[28:16] ypos
[30] ychain
[31] yflip
[39:32] xsize
[47:40] ysize
[56:48] tile
[63:57] pal_sel 
*/

//This contains the sprite ram data for stages 2-6
reg [63:0] spritemem_data [0:4];

wire [7:0] reciproc_y_in;
wire [15:0] reciproc_y_out;

//For each address a, this returns (65536/a).
size_to_d_lookup_rom reciproc_rom_y (
	.clk(clk),
	.reset(reset),
	.a_in(reciproc_y_in),
	.d_out(reciproc_y_out)
);

wire [12:0] virt_ypos;
wire [12:0] virt_xpos;
assign virt_ypos = vid_ypos + offy;
assign virt_xpos = vid_xpos + offx;

wire [17:0] gfx_ypos; //ypos within the scaled output tile
assign gfx_ypos = {7'h0, virt_ypos} - {4'h0, spritemem_data[2][29:16]}; //stage 4
wire [35:0] tile_ypos_multiplied;
reg [15:0] reciproc_y_out_reg; //for stage 4

//This calculates the Ypos in the tile graphic from the real-life Ypos and the scale factor.
//Input is anywhere 0-255 on gfx_ypos, 65536-0 on tile_ypos_multiplied.
//Multiplied, this gives a number from 0 to 16K.
mul_18x18 mul_ypos(
	.a(reciproc_y_out_reg),
	.b(gfx_ypos),
	.dout(tile_ypos_multiplied)
);

wire [3:0] tile_ypos;	//actual ypos in tile mem corresponding to current virt_ypos and current sprite
wire tile_ypos_ovf;		//1 if ypos is outside tile
//stage 5
assign tile_ypos = tile_ypos_multiplied[15:12];
assign tile_ypos_ovf = (tile_ypos_multiplied[35:16]!=0);

reg [3:0] tile_ypos_reg; //tile_ypos, stage 6

reg last_y_lsb;			//to see if we flipped to the next line
reg [7:0] curr_sprite;	//index in sprite mem
reg drawable_ready;
wire spritedrawer_busy;

reg [7:0] spritemem_addr_cur;
wire pipeline_stall;
assign pipeline_stall = (drawable_ready && spritedrawer_busy) || vid_xpos==0;
assign spritemem_addr = pipeline_stall ? spritemem_addr_cur : spritemem_addr_cur + 1;
assign reciproc_y_in = pipeline_stall ? spritemem_data[1][47:40] : spritemem_data[0][47:40]; //stage 3
reg line_done;

//This is the logic that walks the sprite table and tries to find out if a sprite is drawable
//(and possibly chains it in the future as well).
always @(posedge clk) begin
	if (reset) begin
		spritemem_addr_cur <= ~0;
		last_y_lsb <= 0;
		reciproc_y_out_reg <= 0;
		drawable_ready <= 0;
		line_done <= 0;
	end else begin
		last_y_lsb <= vid_ypos[0];
		if (last_y_lsb != vid_ypos[0]) begin
			//Line changed. Restart on new line.
			spritemem_addr_cur <= ~0;
			line_done <= 0;
		end else begin
			spritemem_addr_cur <= spritemem_addr;
			if (spritemem_addr_cur==254 && spritemem_addr == 255) begin
				line_done <= 1;
			end
		end

		if (pipeline_stall) begin
			//need to wait until spritedrawer is done with the current sprite and can move on to
			//the next one we already found is drawable
		end else begin
			drawable_ready <= 0;
			spritemem_data[0] <= spritemem_out; //stage 2
			spritemem_data[1] <= spritemem_data[0]; //stage 3
			spritemem_data[2] <= spritemem_data[1]; //stage 4
			spritemem_data[3] <= spritemem_data[2]; //stage 5
			spritemem_data[4] <= spritemem_data[3]; //stage 6
			reciproc_y_out_reg <= reciproc_y_out; //stage 4
			tile_ypos_reg <= tile_ypos;
			if (spritemem_data[2][29:16]<=virt_ypos && !tile_ypos_ovf && spritemem_data[2][39:32]!=0 && spritemem_data[2][47:40]!=0) begin
				drawable_ready <= !line_done;
			end
		end
	end
end

//This is the logic that actually draws a sprite.
reg [13:0] dspr_xpos; //actual xpos of sprite on screen
reg [13:0] dspr_xoff;//current offset from dspr_xpos
reg [3:0] dspr_tile_ypos;
reg [7:0] dspr_xsize;
reg [8:0] dspr_tile;
reg [6:0] dspr_pal_sel;
reg [3:0] dspr_state;

assign lb_xpos = dspr_xpos + dspr_xoff - offx;

parameter DSPR_STATE_IDLE = 0;
parameter DSPR_STATE_PREP1 = 1;
parameter DSPR_STATE_DRAW = 2;

assign spritedrawer_busy = (dspr_state != DSPR_STATE_IDLE);

wire [15:0] reciproc_x_out;
reg [15:0] reciproc_x_out_reg;

//For each address a, this returns (65536/a).
size_to_d_lookup_rom reciproc_rom_x (
	.clk(clk),
	.reset(reset),
	.a_in(dspr_xsize),
	.d_out(reciproc_x_out)
);

wire [35:0] tile_xpos_multiplied;

//This calculates the Ypos in the tile graphic from the real-life Ypos and the scale factor.
//Input is anywhere 0-255 on gfx_ypos, 65536-0 on tile_ypos_multiplied.
//Multiplied, this gives a number from 0 to 16K.
mul_18x18 mul_xpos(
	.a(reciproc_x_out_reg),
	.b(dspr_xoff),
	.dout(tile_xpos_multiplied)
);
wire [3:0] tile_xpos;
wire tile_xpos_ovf;
assign tile_xpos = tile_xpos_multiplied[15:12];
assign tile_xpos_ovf = (tile_xpos_multiplied[35:16] != 0);

assign tilemem_x = tile_xpos;
assign tilemem_y = dspr_tile_ypos;
assign tilemem_no = dspr_tile;
reg tilemem_has_data; //goes high 1 cycle after tilemem_ack

always @(posedge clk) begin
	if (reset) begin
		dspr_state <= DSPR_STATE_IDLE;
		lb_wr <= 0;
		dspr_xpos <= 0;
		dspr_xsize <= 0;
		dspr_xoff <= 0;
		dspr_pal_sel <= 0;
		dspr_tile <= 0;
		dspr_tile_ypos <= 0;
		lb_din <= 0;
		linebuf_w_addr <= 0;
		linebuf_w_addr_next <= 0;
	end else 
		lb_wr <= 0;
		linebuf_w_addr <= linebuf_w_addr_next;
		tilemem_has_data <= tilemem_ack;
		if (dspr_state==DSPR_STATE_IDLE) begin
			if (drawable_ready) begin
				//Latch input data as the sprite iterator will move on.
				dspr_state <= DSPR_STATE_PREP1;
				dspr_xpos <= spritemem_data[3][13:0];
				dspr_xsize <= spritemem_data[3][39:32];
				dspr_xoff <= 0;
				dspr_pal_sel <= spritemem_data[3][63:57];
				dspr_tile <= spritemem_data[3][56:48];
				dspr_tile_ypos <= tile_ypos_reg;
			end
		end else if (dspr_state==DSPR_STATE_PREP1) begin
			//LUT should have data now, will spit out correct dx next clock cycle.
				dspr_state <= DSPR_STATE_DRAW;
		end else if (dspr_state==DSPR_STATE_DRAW) begin
			//LUT has a result, feed into the multiplier.
			//Note that for the first cycle, the output of the multiplier is always 0, which is correct,
			//even if it doesn't have the correct value from reciproc_x yet.
			reciproc_x_out_reg <= reciproc_x_out;
			//See if we're done.
			if (tile_xpos_ovf) begin
				dspr_state <= DSPR_STATE_IDLE;
			end
			if (lb_xpos[13:9]!=0) begin
				//Can't draw this: out of bounds. Proceed to next pixel.
				dspr_xoff <= dspr_xoff + 1;
			end else if (tilemem_ack) begin
				//Set up write address; we'll write it next cycle
				linebuf_w_addr_next <= {1'b0, ~vid_ypos[0], lb_xpos[8:0]};
				dspr_xoff <= dspr_xoff + 1;
			end
			if (tilemem_has_data) begin
				if (tilemem_data != 0) begin
					lb_din <= tilemem_data + dspr_pal_sel*4;
					lb_wr <= 1;
				end
			end
		end
	end
endmodule


//This is a ROM that contains a lookup table. For an address a, it will spit out (65536/a) a clock
//cycle later.
module size_to_d_lookup_rom (
	input clk,
	input reset,
	input [7:0] a_in,
	output [15:0] d_out
);

reg [15:0] lut[0:255];

initial begin
	$readmemh("reciproc_lut.hex", lut);
end

reg [7:0] a_latch;
assign d_out = lut[a_latch];

always @(posedge clk) begin
	if (reset) begin
		a_latch <= 0;
	end else begin
		a_latch <= a_in;
	end
end

endmodule

