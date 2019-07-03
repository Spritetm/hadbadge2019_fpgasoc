/*
This instantiates the video memory and connects it to the HDMI encoder. On the CPU end, it has 
direct access to the line buffer; on the video end, it allows a 640x480 image generator to 
connect to the other end of the video memory.

*/

module video_mem #(
	parameter integer ADDR_WIDTH = 11 // must be >=9
) (
	input clk,
	input reset,
	input [ADDR_WIDTH-1:0] addr,
	input [23:0] data_in,
	input wen, ren,
	output [23:0] data_out,
	output reg [ADDR_WIDTH-1:0] curr_vid_addr,
	output reg next_field_out,

	input lcd_next_pixel,
	output reg lcd_newfield,
	output reg lcd_wait,
	output [7:0] lcd_red,
	output [7:0] lcd_green,
	output [7:0] lcd_blue,

	input pixel_clk,
	input fetch_next,
	input next_line,
	input next_field,
	output [7:0] red,
	output [7:0] green,
	output [7:0] blue
);

reg [ADDR_WIDTH-1:0] video_addr;
reg [ADDR_WIDTH-1:0] video_addr_lcd;
wire [23:0] video_data;
wire [23:0] video_data_lcd;
assign red=video_data[7:0];
assign green=video_data[15:8];
assign blue=video_data[23:16];

ram_dp_24x2048 ram_hdmi (
	.ResetA(reset),
	.ClockA(clk),
	.ClockEnA(1'b1),
	.DataInA(data_in),
	.AddressA(addr),
	.WrA(wen),
	.QA(data_out),
	.WrB(0),

	.ResetB(reset),
	.ClockB(pixel_clk),
	.ClockEnB(1'b1),
	.DataInB('b0),
	.AddressB(video_addr),
	.QB(video_data)
);

//We could decimate the colors to 18bit rgb here, but ehhh...
ram_dp_24x2048 ram_lcd (
	.ResetA(reset),
	.ClockA(clk),
	.ClockEnA(1'b1),
	.DataInA(data_in),
	.AddressA(addr),
	.WrA(wen),
//	.QA(data_out),
	.WrB(0),

	.ResetB(reset),
	.ClockB(clk),
	.ClockEnB(1'b1),
	.DataInB('b0),
	.AddressB(video_addr_lcd),
	.QB(video_data_lcd)
);


//LCD. This is easy: the display is 480x320 and the framebuffer is that as well. Only 'issue' 
//is that the HDMI-interface is leading when it comes to timings (hello mr tearing) so we need
//to check if the next pixel is available already.
//Note video_addr_lcd[8:0] = xpos, video_addr_lcd[ADDR_WIDTH-1:9] = lcd_row_pos
//In theory, the LCD address will kinda-sortta-ish meander about the HDMI address, as the 
//(unscaled) throughput is about the same, but the scaling induces a more 'choppy' read pattern...
assign lcd_red = video_data_lcd[7:0];
assign lcd_green = video_data_lcd[15:8];
assign lcd_blue = video_data_lcd[23:16];
reg [8:0] lcd_curr_line;
always @(posedge clk) begin
	if (reset) begin
		video_addr_lcd <= 0;
		lcd_curr_line <= 0;
		lcd_newfield <= 0;
	end else begin
		if (video_addr_lcd[ADDR_WIDTH-1:9] == curr_vid_addr[ADDR_WIDTH-1:9] && video_addr_lcd[8:0]==479) begin
			//We're trying to go past the line that HDMI is processing
			lcd_wait <= 1;
		end else begin
			lcd_wait <= 0;
			if (lcd_next_pixel) begin
				lcd_newfield <= 0;
				if (video_addr_lcd[9:0] == 479) begin
					video_addr_lcd[ADDR_WIDTH-1:9] <= video_addr_lcd[ADDR_WIDTH-1:9] + 1;
					video_addr_lcd[9:0] <= 0;
					if (lcd_curr_line != 319) begin
						lcd_curr_line <= lcd_curr_line + 1;
					end else begin
						lcd_curr_line <= 0;
						lcd_newfield <= 1;
						video_addr_lcd <= 0;
					end
				end else begin
					video_addr_lcd <= video_addr_lcd + 1;
				end
			end
		end
	end
end


//HDMI
//The video display is 640x480, we want to show 480x320...
//Means we need to dup lines...probably better to do it with interpolating, but meh :/
// 640/480 = 3/4
// 480/320 = 2/3

reg [1:0] x_skip_ctr;
reg [1:0] y_skip_ctr;
reg [ADDR_WIDTH-1:0] video_addr_clkxing[1:0];
reg next_field_xing[1:0];

always @(posedge clk) begin
	//clock domain crossing things
	curr_vid_addr <= video_addr_clkxing[1];
	video_addr_clkxing[1] <= video_addr_clkxing[0];
	video_addr_clkxing[0] <= video_addr;
	next_field_out <= next_field_xing[1];
	next_field_xing[1] <= next_field_xing[0];
	next_field_xing[0] <= next_field;
end

always @(posedge pixel_clk) begin
	if (reset) begin
		video_addr <= 0;
	end else begin
		if (next_field) begin
			x_skip_ctr <= 0;
			y_skip_ctr <= 0;
			video_addr <= 0;
		end else if (next_line) begin
			y_skip_ctr <= (y_skip_ctr == 2) ? 0 : y_skip_ctr+1;
			if (y_skip_ctr != 2) begin
				video_addr[ADDR_WIDTH-1:9] <= video_addr[ADDR_WIDTH-1:9]+1;
			end
			video_addr[8:0] <= 0;
		end else if (fetch_next) begin
			x_skip_ctr <= x_skip_ctr + 1;
			if (x_skip_ctr != 3) begin
				video_addr <= video_addr + 1;
			end
		end
	end
end

endmodule