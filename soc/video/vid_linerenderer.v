/*
This effectively is the GPU. It has a slave interface to the CPU, for register-settings and 
'on-chip' video memory, as well as a master interface for the SPI RAM, for grabbing a bitmap.
*/



module vid_linerenderer (
	input clk, reset,

	//Slave iface from cpu
	input [24:0] addr,
	input [31:0] din,
	input [3:0] wstrb,
	input ren,
	output reg [31:0] dout,
	output reg ready,
	
	//Video mem iface
	output reg [19:0] vid_addr, //assume 1 meg-words linebuf mem max
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
reg [31:0] dma_data;
qpimem_dma_rdr dma_rdr(
	.clk(clk),
	.rst(reset),
	.addr_start(dma_start_addr),
	.addr_end(dma_start_addr+(480/2)),
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

reg [15:0] tilea_xoff;
reg [15:0] tilea_yoff;
reg [15:0] tileb_xoff;
reg [15:0] tileb_yoff;

wire [31:0] dout_tilemapa;
wire [31:0] dout_tilemapb;
wire [31:0] dout_palette;
wire [31:0] dout_tilemem;
reg tilea_8x16;

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
			dout = {16'h0, pitch};
		end else if (addr[5:2]==REG_SEL_LAYER_EN) begin
			dout = {23'h0, tilea_8x16, layer_en};
		end else if (addr[5:2]==REG_SEL_TILEA_OFF) begin
			dout = {tilea_yoff, tilea_xoff};
		end else if (addr[5:2]==REG_SEL_TILEB_OFF) begin
			dout = {tileb_yoff, tileb_xoff};
		end
	end else if (addr[16:13]=='h1) begin
		cpu_sel_palette = 1;
		dout = dout_palette;
	end else if (addr[16:13]=='h2) begin
		cpu_sel_tilemap_a = 1;
		dout = dout_tilemapa;
	end else if (addr[16:13]=='h3) begin
		cpu_sel_tilemap_b = 1;
		dout = dout_tilemapb;
	end else if (addr[16:13]=='h4) begin
		cpu_sel_sprites = 1;
		//dout = dout_sprites;
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
reg [3:0] tilenib_sel;
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


reg [16:0] tilea_x;
reg [16:0] tilea_y;
wire [9:0] tilea_data;
reg [31:0] tilemapa_word;
wire [10:0] tilemapa_addr;
assign tilemapa_addr = {tilea_y[5:0], tilea_x[5:1]};
reg tilemapa_hsel;
always @(posedge clk) tilemapa_hsel<=tilea_x[0];
assign tilea_data = tilemapa_hsel? tilemapa_word[31:16] : tilemapa_word[15:0];

vid_tilemapmem tilemapa (
	.ClockA(clk),
	.ClockB(clk),
	.ResetA(reset),
	.ResetB(reset),
	.ClockEnA(1),
	.ClockEnB(1),
	.DataInA(din),
	.DataInB(0),
	.ByteEnA(wstrb==0 ? 'hf : wstrb),
	.ByteEnB('hf),
	.WrA((wstrb!=0) & cpu_sel_tilemap_a),
	.WrB(0),
	.AddressA(addr[12:2]),
	.AddressB(tilemapa_addr),
	.QA(dout_tilemapa),
	.QB(tilemapa_word)
);

reg [16:0] tileb_x;
reg [16:0] tileb_y;
wire [9:0] tileb_data;
reg [31:0] tilemapb_word;
wire [10:0] tilemapb_addr;
assign tilemapb_addr = {tileb_y[5:0], tileb_x[5:1]};
reg tilemapb_hsel;
always @(posedge clk) tilemapb_hsel<=tileb_x[0];
assign tileb_data = tilemapb_hsel? tilemapb_word[31:16] : tilemapb_word[15:0];

vid_tilemapmem tilemapb (
	.ClockA(clk),
	.ClockB(clk),
	.ResetA(reset),
	.ResetB(reset),
	.ClockEnA(1),
	.ClockEnB(1),
	.DataInA(din),
	.DataInB(0),
	.ByteEnA(wstrb==0 ? 'hf : wstrb),
	.ByteEnB('hf),
	.WrA((wstrb!=0) & cpu_sel_tilemap_b),
	.WrB(0),
	.AddressA(addr[12:2]),
	.AddressB(tilemapb_addr),
	.QA(dout_tilemapb),
	.QB(tilemapb_word)
);


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
	FB palette data -> pixel hold
1:
	TileA palette data -> pixel hold
	TileB tilemem pixel -> palette
2:
	TileA X/Y -> tilemap
	TileB palette data -> pixel hold
	Sprite linebuf pixel -> palette
3:
	TileA tilemap -> tilemem
	TileB X/Y -> tilemap
	Sprite palette data -> pixel hold
	FB data -> palette

*/


reg [1:0] cycle;

reg [19:0] write_vid_addr;
wire [8:0] vid_ypos;
wire [8:0] vid_xpos;
assign vid_xpos = write_vid_addr[8:0];
assign vid_ypos = write_vid_addr[17:9];

always @(*) begin
	if (tilea_8x16) begin
		tilea_x = ({7'h0,vid_xpos} + tilea_xoff)/8;
	end else begin
		tilea_x = ({7'h0,vid_xpos} + tilea_xoff)/16;
	end
	tilea_y = ({7'h0,vid_ypos} + tilea_yoff)/16;
	tileb_x = ({7'h0,vid_xpos} + tileb_xoff)/16;
	tileb_y = ({7'h0,vid_ypos} + tileb_yoff)/16;
	if (cycle==0) begin
		tilepix_x = (vid_xpos + tileb_xoff);
		tilepix_y = (vid_ypos + tileb_yoff);
		tilemem_no = tileb_data[8:0];
		pal_addr = {5'h2, tilemem_pixel}; //from tilemap a
	end else if (cycle==1) begin
		tilepix_x = 0;
		tilepix_y = 0;
		tilemem_no = 0;
		pal_addr = {5'h1, tilemem_pixel}; //from tilemap b
	end else if (cycle==2) begin
		tilepix_x = 0;
		tilepix_y = 0;
		tilemem_no = 0;
		pal_addr = {5'h0, dma_data[vid_xpos[3:0]*4+:4]}; //from fb
	end else if (cycle==3) begin
		if (tilea_8x16) begin
			tilepix_x[2:0] = (vid_xpos + tilea_xoff);
			tilepix_x[3] = tilea_data[0];
			tilepix_y = (vid_ypos + tilea_yoff);
			tilemem_no = {1'h0, tilea_data[8:1]};
		end else begin
			tilepix_x = (vid_xpos + tilea_xoff);
			tilepix_y = (vid_ypos + tilea_yoff);
			tilemem_no = tilea_data[8:0];
		end
		pal_addr = 3; //todo: sprite
	end
end

reg [31:0] pixel_hold;
assign vid_data_out = pixel_hold[23:0];

always @(posedge clk) begin
	if (reset) begin
		ready <= 0;
		fb_addr <= 'h7E0000; //top 128K of RAM
		pitch <= 512;
		write_vid_addr <= 'h400; //2 lines in advance, so we start writing immediately (good for sim)
		vid_addr <= 0;
		vid_ren <= 0;
		dma_start_addr <= fb_addr;
		tilea_xoff <= 0;
		tileb_xoff <= 0;
		tilea_xoff <= 0;
		tileb_xoff <= 0;
		tilea_8x16 <= 0;
	end else begin
		/* CPU interface */
		ready <= ((wstrb!=0) | ren);
		if ((&wstrb) && cpu_sel_regs) begin
			if (addr[5:2]==REG_SEL_FB_ADDR) begin
				fb_addr <= din[23:0];
			end else if (addr[5:2]==REG_SEL_FB_PITCH) begin
				pitch <= din[15:0];
			end else if (addr[5:2]==REG_SEL_LAYER_EN) begin
				layer_en <= din[3:0];
				tilea_8x16 <= din[4];
			end else if (addr[5:2]==REG_SEL_TILEA_OFF) begin
				tilea_xoff <= din[15:0];
				tilea_yoff <= din[31:16];
			end else if (addr[5:2]==REG_SEL_TILEB_OFF) begin
				tileb_xoff <= din[15:0];
				tileb_yoff <= din[31:16];
			end
		end

		//vid_addr is write_vid_addr delayed by one cycle, so we can make
		//decisions of the data to write depending on the contents of write_vid_addr.
		vid_addr <= write_vid_addr;
		dma_do_read <= 0;
		vid_wen <= 0;

		//Line renderer proper statemachine.
		if (write_vid_addr[19:9]>=320) begin
			//We're finished with this frame. Wait until the video generator starts drawing the next frame.
			dma_run <= 0;
			if (next_field) begin
				write_vid_addr <= 0;
				dma_start_addr <= fb_addr;
			end else begin
				//Not yet, keep idling
			end
		end else if (write_vid_addr[10:9] != curr_vid_addr[10:9]) begin
			//If we're here, there is room in the line memory to write a new line into.
			dma_run <= 1;
			if (dma_ready || write_vid_addr[2:0]!=0) begin
				if (write_vid_addr[2:0] == 7 && cycle==2) begin
					//We need a new word. Enable read here because:
					// dma_do_read actually goes high next cycle
					// correct data will get returned next next cycle
					dma_do_read <= 1;
				end

				cycle <= cycle + 1;
				if (cycle==0) begin
					pixel_hold <= 0;
					if (layer_en[0]) pixel_hold <= pal_data; //fb data
				end else if (cycle==1) begin
					if (layer_en[1]) pixel_hold <= pal_data; //tilemap a
				end else if (cycle==2) begin
					if (layer_en[2]) pixel_hold <= pal_data; //tilemap b
				end else if (cycle==3) begin
					if (layer_en[3]) pixel_hold <= pal_data; //sprite
					//Move to the next pixel
					vid_wen <= 1;
					if (write_vid_addr[8:0]>479) begin
						//next line
						write_vid_addr[19:9] <= write_vid_addr[19:9] + 'h1;
						write_vid_addr[8:0] <= 0;
						dma_start_addr <= dma_start_addr + pitch/2;
						dma_run <= 0;
					end else begin
						write_vid_addr <= write_vid_addr + 'h1;
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

