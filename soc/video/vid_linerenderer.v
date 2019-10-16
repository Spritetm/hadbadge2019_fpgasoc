/*
This effectively is the GPU. It has a slave interface to the CPU, for register-settings and 
'on-chip' video memory, as well as a master interface for the SPI RAM, for grabbing a bitmap.

It's called a line renderer as it renders lines asynchroneously from the pixel output (i.e.
as fast as possible), then writes it into the video memory. This video memory is only 4 lines
and is used as a FIFO. The downstream video hardware reads from this memory at it's own pace
(namely the HDMI and/or LCD pixel clock) and spits out the pixels to the respective display
devices.
*/

/*
Backgrounds are simple, for this: take a bunch of tiles in tilemem and a tilemap. Tilemap 
resolves current tile for (x,y), tile mem resolves the pixel, palette mem resolves color.

Sprites are harder because they can be anywhere. A sane setup would probably involve
a dual memory to render in: one gets filled (random-access) by the sprite subsystem, the
other is both read and zeroed by the line renderer.

Now we have memory we can just randomly dump sprites in... how to do that? We don't have time
to scan all sprites (how many?) every pixel, unfortunately. How many sprites do we want to have
anyway?

Let's say we do it like most consoles seem to do it: have x sprites in total, with a max of y
sprites on one scanline. Take the snes: it can do max 32 sprites per scanline (or 256 pixels),
128 sprites max. In our hw, we have 4 clocks per pixel, or 1920 clocks in total to process one
line of sprites. Let's assume all sprites have one fixed size for now (although it would be
awesome if we could add scaling or rotation to the mix.) Let's assume we wat to do max 32x32
sprites.

One of the ways to fix this up would be by just iterating over all 512 sprites; as soon as we find one
that is supposed to be on the current line, we draw it out. This means we can process all 512
sprites at the same time, perhaps iterating over them multiple times for priority stuff. Given we
write pixels to the line memory one by one and we have 2/4 accesses to tile memory, this
should cost us (512 + 32*2*32)=2560 cycles, with no prio and 32 sprites simultaneously. That ain't no
good...

Say, we hit this thing with 32 bit at a time. 4x per sprite, we read 32 bit from the tile memory.
Then, 5x, we read what is in the current tile memory, overlay the 32-bits we have, and write it back.
This means we need (512+5*2*32)=832 cycles. Nice, but no chance of rotation/scaling...

Maybe meet in the middle? There's nothing stopping us from fetching 32 bit (8 pixels) from tile 
mem at a time. We can process these in parallel with fetching the next one. That would worst-case
cost us (512+32*32)=1536 cycles. That fits and allows us to do X-scaling as well.

*/



module vid_linerenderer (
	input clk, reset,

	//Slave iface from cpu
	input [24:0] addr,
	input [31:0] din,
	input [3:0] wstrb,
	input ren,
	output reg [31:0] dout,
	output ready,
	
	//Video mem iface
	output reg [19:0] vid_addr, //assume 1 meg-words linebuf mem max
	input preload, //will go high 4 lines before video frame starts (with vid_address=0)
	output [23:0] vid_data_out,
	output reg vid_wen, vid_ren,
	input [23:0] vid_data_in,
	input [19:0] curr_vid_addr,
	input next_field,

	//Master iface to spi mem
	output reg m_do_read,
	input m_next_word,
	output reg [23:0] m_addr,
	input [31:0] m_rdata,
	input m_is_idle
);


reg [23:0] fb_addr;
reg [15:0] pitch;
reg [3:0] layer_en;

reg [23:0] dma_start_addr;
reg dma_run;
wire dma_ready;
reg dma_do_read;
wire [31:0] dma_data;
qpimem_dma_rdr dma_rdr(
	.clk(clk),
	.rst(reset),
	.addr_start(dma_start_addr),
	.addr_end(dma_start_addr+(fb_is_8bit?480:(480/2))),
	.run(dma_run),
	.do_read(dma_do_read),
	.ready(dma_ready),
	.rdata(dma_data),

	.qpi_do_read(m_do_read),
	.qpi_next_word(m_next_word),
	.qpi_addr(m_addr),
	.qpi_rdata(m_rdata),
	.qpi_is_idle(m_is_idle)
);

reg cpu_sel_tilemem;
reg cpu_sel_tilemap_a;
reg cpu_sel_tilemap_b;
reg cpu_sel_palette;
reg cpu_sel_regs;
reg cpu_sel_sprites;

parameter REG_SEL_FB_ADDR = 0;
parameter REG_SEL_FB_PITCH = 1;
parameter REG_SEL_LAYER_EN = 2;
parameter REG_SEL_TILEA_OFF = 3;
parameter REG_SEL_TILEB_OFF = 4;
parameter REG_SEL_TILEA_INC_COL = 5;
parameter REG_SEL_TILEA_INC_ROW = 6;
parameter REG_SEL_TILEB_INC_COL = 7;
parameter REG_SEL_TILEB_INC_ROW = 8;
parameter REG_SEL_VIDPOS = 9;
parameter REG_SEL_BGNDCOL = 10;
parameter REG_SEL_SPRITE_OFF = 11;

//Reminder: we have 64x64 tiles of 16x16 pixels, so in total a field of 1024x1024 pixels. Say we have one overflow bit, we need 11 bit
//for everything... that leaves 5 bits for sub-pixel addressing in scaling modes. That sounds OK.
reg [15:0] tilea_xoff;
reg [15:0] tilea_yoff;
reg [15:0] tileb_xoff;
reg [15:0] tileb_yoff;
reg [12:0] sprite_xoff;
reg [12:0] sprite_yoff;

wire [17:0] dout_tilemapa;
wire [17:0] dout_tilemapb;
wire [31:0] dout_palette;
wire [31:0] dout_tilemem;
wire [31:0] dout_sprites;
reg fb_is_8bit;
reg [31:0] bgnd_color;
reg [8:0] fb_pal_offset;

reg [1:0] cycle;
reg [19:0] write_vid_addr;
reg [19:0] write_vid_addr_next;
wire [8:0] vid_ypos;
wire [8:0] vid_xpos;
assign vid_xpos = write_vid_addr[8:0];
assign vid_ypos = write_vid_addr[17:9];
wire [8:0] vid_ypos_next;
wire [8:0] vid_xpos_next;
assign vid_xpos_next = write_vid_addr_next[8:0];
assign vid_ypos_next = write_vid_addr_next[17:9];

reg [15:0] tilea_colinc_x;
reg [15:0] tilea_colinc_y;
reg [15:0] tilea_rowinc_x;
reg [15:0] tilea_rowinc_y;
reg [15:0] tileb_colinc_x;
reg [15:0] tileb_colinc_y;
reg [15:0] tileb_rowinc_x;
reg [15:0] tileb_rowinc_y;
wire [8:0] sprite_pix;

always @(*) begin
	cpu_sel_tilemem = 0;
	cpu_sel_tilemap_a = 0;
	cpu_sel_tilemap_b = 0;
	cpu_sel_palette = 0;
	cpu_sel_regs = 0;
	cpu_sel_sprites = 0;
	dout = 0;
	if (addr[16:13]=='h0) begin
		cpu_sel_regs = 1;
		if (addr[5:2]==REG_SEL_FB_ADDR) begin
			dout = {8'h4, fb_addr};
		end else if (addr[5:2]==REG_SEL_FB_PITCH) begin
			dout = {7'h0, fb_pal_offset, pitch};
		end else if (addr[5:2]==REG_SEL_LAYER_EN) begin
			dout = {15'h0, fb_is_8bit, 12'h0,  layer_en};
		end else if (addr[5:2]==REG_SEL_TILEA_OFF) begin
			dout = {tilea_yoff, tilea_xoff};
		end else if (addr[5:2]==REG_SEL_TILEB_OFF) begin
			dout = {tileb_yoff, tileb_xoff};
		end else if (addr[5:2]==REG_SEL_TILEA_INC_COL) begin
			dout = {tilea_colinc_x, tilea_colinc_y};
		end else if (addr[5:2]==REG_SEL_TILEA_INC_ROW) begin
			dout = {tilea_rowinc_x, tilea_rowinc_y};
		end else if (addr[5:2]==REG_SEL_TILEB_INC_COL) begin
			dout = {tileb_colinc_x, tileb_colinc_y};
		end else if (addr[5:2]==REG_SEL_TILEB_INC_ROW) begin
			dout = {tileb_rowinc_x, tileb_rowinc_y};
		end else if (addr[5:2]==REG_SEL_VIDPOS) begin
			dout = {7'h0, vid_ypos, 7'h0, vid_xpos};
		end else if (addr[5:2]==REG_SEL_BGNDCOL) begin
			dout = bgnd_color;
		end else if (addr[5:2]==REG_SEL_SPRITE_OFF) begin
			dout = {4'h0, sprite_yoff, 4'h0, sprite_xoff};
		end
	end else if (addr[16:13]=='h1) begin
		cpu_sel_palette = 1;
		dout = dout_palette;
	end else if (addr[16:14]=='h1) begin //2,3
		cpu_sel_tilemap_a = 1;
		dout = {14'h0, dout_tilemapa};
	end else if (addr[16:14]=='h2) begin //4,5
		cpu_sel_tilemap_b = 1;
		dout = {14'h0, dout_tilemapb};
	end else if (addr[16:13]=='h6) begin
		cpu_sel_sprites = 1;
		dout = dout_sprites;
	end else if (addr[16]==1) begin
		cpu_sel_tilemem = 1;
		dout = dout_tilemem;
	end
end


reg [3:0] tilepix_x;
reg [3:0] tilepix_y;
reg [8:0] tilemem_no;
wire [3:0] tilemem_pixel;
wire [31:0] tilemem_word;

wire [13:0] tilemem_addr;
assign tilemem_addr = {tilemem_no, tilepix_y, tilepix_x[3]};
reg [2:0] tilenib_sel;
always @(posedge clk) begin
	tilenib_sel <= tilepix_x[2:0];
end
assign tilemem_pixel=tilemem_word[4*tilenib_sel+:4];

vid_tilemem tilemem(
	.ClockA(clk),
	.ClockB(clk),
	.ResetA(reset),
	.ResetB(reset),
	.ClockEnA(1),
	.ClockEnB(1),
	.DataInA(din),
	.DataInB(0),
	.WrA(&wstrb & cpu_sel_tilemem),
	.WrB(0),
	.AddressA(addr[15:2]),
	.AddressB(tilemem_addr),
	.QA(dout_tilemem),
	.QB(tilemem_word)
);


//Tilemap data:
// 8:0 - tile
// 9 - inv x
// 10 - inv y
// 17-11 - palette offset *4

reg [16:0] tilea_x;
reg [16:0] tilea_y;
wire [17:0] tilea_data;
wire [11:0] tilemapa_addr;
assign tilemapa_addr = {tilea_y[15:10], tilea_x[15:10]};

vid_tilemapmem tilemapa (
	.ClockA(clk),
	.ClockB(clk),
	.ResetA(reset),
	.ResetB(reset),
	.ClockEnA(1),
	.ClockEnB(1),
	.DataInA(din[17:0]),
	.DataInB(0),
	.WrA(&wstrb & cpu_sel_tilemap_a),
	.WrB(0),
	.AddressA(addr[13:2]),
	.AddressB(tilemapa_addr),
	.QA(dout_tilemapa),
	.QB(tilea_data)
);

reg [16:0] tileb_x;
reg [16:0] tileb_y;
wire [17:0] tileb_data;
wire [11:0] tilemapb_addr;
assign tilemapb_addr = {tileb_y[15:10], tileb_x[15:10]};

vid_tilemapmem tilemapb (
	.ClockA(clk),
	.ClockB(clk),
	.ResetA(reset),
	.ResetB(reset),
	.ClockEnA(1),
	.ClockEnB(1),
	.DataInA(din[17:0]),
	.DataInB(0),
	.WrA(&wstrb & cpu_sel_tilemap_b),
	.WrB(0),
	.AddressA(addr[13:2]),
	.AddressB(tilemapb_addr),
	.QA(dout_tilemapb),
	.QB(tileb_data)
);

reg sprite_pix_done;


wire [3:0] sprite_tilemem_x;
wire [3:0] sprite_tilemem_y;
wire [8:0] sprite_tilemem_no;
reg sprite_tilemem_ack;


vid_spriteeng spriteeng (
	.clk(clk),
	.reset(reset),
	.cpu_addr(addr[10:2]),
	.cpu_din(din),
	.cpu_dout(dout_sprites),
	.cpu_wstrb(cpu_sel_sprites ? wstrb : 0),
	.offx(sprite_xoff),
	.offy(sprite_yoff),

	.vid_xpos(vid_xpos),
	.vid_ypos(vid_ypos),
	.sprite_pix(sprite_pix),
	.pix_done(sprite_pix_done),

	.tilemem_x(sprite_tilemem_x),
	.tilemem_y(sprite_tilemem_y),
	.tilemem_no(sprite_tilemem_no),
	.tilemem_data(tilemem_pixel),
	.tilemem_ack(sprite_tilemem_ack)
);

reg [16:0] tilea_linestart_x;
reg [16:0] tilea_linestart_y;
reg [16:0] tileb_linestart_x;
reg [16:0] tileb_linestart_y;

reg [8:0] pal_addr;
wire [31:0] pal_data;

vid_palettemem palettemem(
	.ClockA(clk),
	.ClockB(clk),
	.ResetA(reset),
	.ResetB(reset),
	.ClockEnA(1),
	.ClockEnB(1),
	.DataInA(din),
	.DataInB(0),
	.WrA((wstrb=='hf) && cpu_sel_palette),
	.WrB(0),
	.AddressA(addr[10:2]),
	.AddressB(pal_addr),
	.QA(dout_palette),
	.QB(pal_data)
);

reg [31:0] alphamixer_in_b;
reg [7:0] alphamixer_rate;
wire [31:0] alphamixer_out_cur;
reg [31:0] alphamixer_out;

video_alphamixer mixer(
	.in_a(pal_data),
	.in_b(alphamixer_in_b),
	.rate(alphamixer_rate),
	.out(alphamixer_out_cur)
);


/*
Note we have slightly more than 4 clock cycles per pixel here. This means we can have 4 layers.

Layer FB - Framebuffer, from psram
Layer TA - Tile layer A
Layer TB - Tile layer B
Layer SP - Sprite layer.

We have 4 states per pixel, 0-3 This is what happens in each state:

0:
	TileA tilemem pixel -> palette
	TileB tilemap -> tilemem
	FB palette data -> alpha mixer
1:
	TileA palette data -> alpha mixer
	TileB tilemem pixel -> palette
2:
	TileA X/Y -> tilemap
	TileB palette data -> alpha mixer
	Sprite linebuf pixel -> palette
3:
	TileA tilemap -> tilemem
	TileB X/Y -> tilemap
	Sprite palette data -> alpha mixer
	FB data -> palette

*/

reg [7:0] fb_pixel;

always @(*) begin
	tilepix_x=0;
	tilepix_y=0;
	tilemem_no=0;
	pal_addr=0;
	sprite_pix_done=0;
	sprite_tilemem_ack=0;

	if (cycle==0) begin
		tilepix_x = tileb_data[9] ? (15-tileb_x[9:6]) : tileb_x[9:6];
		tilepix_y = tileb_data[10] ? (15-tileb_y[9:6]) : tileb_y[9:6];
		tilemem_no = tileb_data[8:0];
		pal_addr = tilemem_pixel + {tilea_data[17:11], 2'b0}; //from tilemap a
		alphamixer_rate = layer_en[0] ? pal_data[31:24] : 0; //fb
		alphamixer_in_b = bgnd_color; //background
	end else if (cycle==1) begin
		tilepix_x = sprite_tilemem_x;
		tilepix_y = sprite_tilemem_y;
		tilemem_no = sprite_tilemem_no;
		sprite_tilemem_ack = 1;
		pal_addr = tilemem_pixel + {tileb_data[17:11], 2'b0}; //from tilemap b
		alphamixer_rate = layer_en[1] ? pal_data[31:24] : 0; //tilemap a
		alphamixer_in_b = alphamixer_out; //bgnd+fb
	end else if (cycle==2) begin
		tilepix_x = sprite_tilemem_x;
		tilepix_y = sprite_tilemem_y;
		tilemem_no = sprite_tilemem_no;
		sprite_tilemem_ack = 1;
		pal_addr = sprite_pix;
		sprite_pix_done = 1;
		alphamixer_rate = layer_en[2] ? pal_data[31:24] : 0; //tilemap b
		alphamixer_in_b = alphamixer_out; //bgnd+fb+tilemap_a
	end else begin //cycle==3
		tilepix_x = tilea_data[9] ? (15-tilea_x[9:6]) : tilea_x[9:6];
		tilepix_y = tilea_data[10] ? (15-tilea_y[9:6]) : tilea_y[9:6];
		tilemem_no = tilea_data[8:0];
		pal_addr = {fb_pixel+fb_pal_offset}; //from fb
		alphamixer_rate = layer_en[3] ? pal_data[31:24] : 0; //sprite
		alphamixer_in_b = alphamixer_out; //bgnd+fb+tilemap_a+tilemap_b
	end
end

assign vid_data_out = alphamixer_out[23:0];
reg ready_delayed;
assign ready = ready_delayed & ((wstrb!=0) || ren);

always @(posedge clk) begin
	if (reset) begin
		ready_delayed <= 0;
		fb_addr <= 'h7E0000; //top 128K of RAM
		pitch <= 512;
		write_vid_addr_next <= 'h400; //2 lines in advance, so we start writing immediately (good for sim)
		vid_addr <= 0;
		vid_ren <= 0;
		dma_start_addr <= fb_addr;
		tilea_xoff <= 0;
		tileb_xoff <= 0;
		tilea_xoff <= 0;
		tileb_xoff <= 0;
		tilea_linestart_x <= 0;
		tilea_linestart_y <= 0;
		tileb_linestart_x <= 0;
		tileb_linestart_y <= 0;
		tilea_colinc_x <= (1<<6);
		tilea_colinc_y <= 0;
		tilea_rowinc_x <= 0;
		tilea_rowinc_y <= (1<<6);
		tileb_colinc_x <= (1<<6);
		tileb_colinc_y <= 0;
		tileb_rowinc_x <= 0;
		tileb_rowinc_y <= (1<<6);
		fb_is_8bit <= 0;
		alphamixer_out <= 0;
		bgnd_color <= 0;
		sprite_yoff <= 64;
		sprite_xoff <= 64;
	end else begin
		/* CPU interface */
		ready_delayed <= ((wstrb!=0) | ren);
		if ((&wstrb) && cpu_sel_regs) begin
			if (addr[5:2]==REG_SEL_FB_ADDR) begin
				fb_addr <= din[23:0];
			end else if (addr[5:2]==REG_SEL_FB_PITCH) begin
				pitch <= din[15:0];
				fb_pal_offset=din[24:16];
			end else if (addr[5:2]==REG_SEL_LAYER_EN) begin
				layer_en <= din[3:0];
				fb_is_8bit <= din[16];
			end else if (addr[5:2]==REG_SEL_TILEA_OFF) begin
				tilea_xoff <= din[15:0];
				tilea_yoff <= din[31:16];
			end else if (addr[5:2]==REG_SEL_TILEB_OFF) begin
				tileb_xoff <= din[15:0];
				tileb_yoff <= din[31:16];
			end else if (addr[5:2]==REG_SEL_TILEA_INC_COL) begin
				tilea_colinc_x <= din[15:0];
				tilea_colinc_y <= din[31:16];
			end else if (addr[5:2]==REG_SEL_TILEA_INC_ROW) begin
				tilea_rowinc_x <= din[15:0];
				tilea_rowinc_y <= din[31:16];
			end else if (addr[5:2]==REG_SEL_TILEB_INC_COL) begin
				tileb_colinc_x <= din[15:0];
				tileb_colinc_y <= din[31:16];
			end else if (addr[5:2]==REG_SEL_TILEB_INC_ROW) begin
				tileb_rowinc_x <= din[15:0];
				tileb_rowinc_y <= din[31:16];
			end else if (addr[5:2]==REG_SEL_BGNDCOL) begin
				bgnd_color <= din;
			end else if (addr[5:2]==REG_SEL_SPRITE_OFF) begin
				sprite_xoff <= din[12:0];
				sprite_yoff <= din[28:16];
			end
		end

		//vid_address is the address that is sent to the write hardware. As this actually increases
		//at the same time as we set the write strobe, we make sure it is write_vid_address delayed by
		//one cycle. write_vid_address now is the address of the pixel we're reading from the palette
		//memory and writing to the video memory.
		vid_addr <= write_vid_addr;
		//As the tile and sprite hardware needs some extra cycles to get the data from tile memory,
		//we generate write_vid_address by delaying write_vid_address_next by one. This way, if 
		//write_vid_address is the current pixel position, write_vid_address_next is the future one.
		write_vid_addr <= write_vid_addr_next;
		dma_do_read <= 0;
		vid_wen <= 0;

		//Line renderer proper statemachine.
		if (write_vid_addr[19:9]>=320) begin
			//We're finished with this frame. Wait until the video generator starts drawing the next frame.
			dma_run <= 0;
			tilea_linestart_x <= tilea_xoff + tilea_rowinc_x;
			tilea_linestart_y <= tilea_yoff + tilea_rowinc_y;
			tilea_x <= tilea_xoff;
			tilea_y <= tilea_yoff;
			tileb_linestart_x <= tileb_xoff + tileb_rowinc_x;
			tileb_linestart_y <= tileb_yoff + tileb_rowinc_y;
			tileb_x <= tileb_xoff;
			tileb_y <= tileb_yoff;
			if (next_field) begin
				write_vid_addr_next <= 0;
				dma_start_addr <= fb_addr;
			end else begin
				//Not yet, keep idling
			end
		end else if (write_vid_addr[10:9] != curr_vid_addr[10:9] || preload) begin
			//If we're here, there is room in the line memory to write a new line into.
			dma_run <= layer_en[0];
			if (dma_ready || (fb_is_8bit==0 && write_vid_addr[3:0]!=0) || (fb_is_8bit==1 && write_vid_addr[2:0]!=0) || layer_en[0]==0) begin
				if (((fb_is_8bit==0 && write_vid_addr[2:0] == 7) || (fb_is_8bit==1 && write_vid_addr[1:0]==3)) && cycle==3) begin
					//We need a new word. Enable read here (at cycle 2) because:
					// dma_do_read actually goes high next cycle
					// correct data will get returned next next cycle
					dma_do_read <= 1;
				end

				alphamixer_out <= alphamixer_out_cur;
				cycle <= cycle + 1;
				if (cycle==0) begin
					if (fb_is_8bit) begin
						fb_pixel <= {dma_data[vid_xpos[3:0]*8+:8]};
					end else begin
						fb_pixel <= {4'h0, dma_data[vid_xpos[3:0]*4+:4]};
					end
				end else if (cycle==1) begin
					tileb_x <= tileb_x + tileb_colinc_x;
					tileb_y <= tileb_y + tileb_colinc_y;
				end else if (cycle==3) begin
					//Move to the next pixel
					vid_wen <= 1;
					if (write_vid_addr[8:0]>479) begin
						//next line
						write_vid_addr_next[19:9] <= write_vid_addr_next[19:9] + 'h1;
						write_vid_addr_next[8:0] <= 0;
						dma_start_addr <= dma_start_addr + (fb_is_8bit?pitch:pitch/2);
						dma_run <= 0;
						tilea_x <= tilea_linestart_x;
						tilea_y <= tilea_linestart_y;
						tilea_linestart_x <= tilea_linestart_x + tilea_rowinc_x;
						tilea_linestart_y <= tilea_linestart_y + tilea_rowinc_y;
						tileb_x <= tileb_linestart_x;
						tileb_y <= tileb_linestart_y;
						tileb_linestart_x <= tileb_linestart_x + tileb_rowinc_x;
						tileb_linestart_y <= tileb_linestart_y + tileb_rowinc_y;
					end else begin
						write_vid_addr_next <= write_vid_addr_next + 'h1;
						tilea_x <= tilea_x + tilea_colinc_x;
						tilea_y <= tilea_y + tilea_colinc_y;
					end
				end
			end else begin
				//waiting for dma to have something
			end
		end else begin
			//wait for next line
			dma_run <= 0;
		end
	end
end

endmodule

