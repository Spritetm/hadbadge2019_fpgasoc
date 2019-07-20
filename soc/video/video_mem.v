/*
This instantiates the video memory blockram and connects it to the HDMI encoder and LCD output. We actually instantiate two 
RAM buffers here, so we can somewhat decouple HDMI and LCD timings.

Note that this module uses video_address registers. These registers indicate the address, with [19:9]=ypos, [8:0]=xpos. The
memory itself is not as large and will act as a fifo, only storing the last few lines being rendered.
*/

module video_mem (
	input clk,
	input reset,

	//Interface to line renderer
	input [19:0] addr,
	input [23:0] data_in,
	input wen, ren,
	output [23:0] data_out,
	output reg [19:0] curr_vid_addr,
	output reg next_field_out,

	//Interface to LCD
	input lcd_next_pixel,
	output reg lcd_newfield,
	output reg lcd_wait,
	output [7:0] lcd_red,
	output [7:0] lcd_green,
	output [7:0] lcd_blue,

	//Interface to HDMI encoder
	input pixel_clk,
	input fetch_next,
	input next_line,
	input next_field,
	output [7:0] red,
	output [7:0] green,
	output [7:0] blue
);

reg [19:0] video_addr_lcd;
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
	.AddressA(addr[11:0]),
	.WrA(wen),
	.QA(data_out),
	.WrB(0),

	.ResetB(reset),
	.ClockB(pixel_clk),
	.ClockEnB(1'b1),
	.DataInB('b0),
	.AddressB(video_addr[11:0]),
	.QB(video_data)
);

//We could decimate the colors to 18bit rgb here, but ehhh...
ram_dp_24x2048 ram_lcd (
	.ResetA(reset),
	.ClockA(clk),
	.ClockEnA(1'b1),
	.DataInA(data_in),
	.AddressA(addr[11:0]),
	.WrA(wen),
//	.QA(data_out),
	.WrB(0),

	.ResetB(reset),
	.ClockB(clk),
	.ClockEnB(1'b1),
	.DataInB('b0),
	.AddressB(video_addr_lcd[11:0]),
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
always @(posedge clk) begin
	if (reset) begin
		video_addr_lcd <= 0;
		lcd_newfield <= 0;
	end else begin
		if (video_addr_lcd[19:9] == curr_vid_addr[19:9] && video_addr_lcd[8:0]==479) begin
			//We're trying to go past the line that HDMI is processing. Wait until HDMI catches up.
			lcd_wait <= 1;
		end else begin
			lcd_wait <= 0;
			if (lcd_next_pixel) begin
				lcd_newfield <= 0;
				if (video_addr_lcd[8:0] == 479) begin //end of the line
					if (video_addr_lcd[19:9] < 320) begin
						//next line
						video_addr_lcd[19:9] <= video_addr_lcd[19:9] + 1;
						video_addr_lcd[8:0] <= 0;
					end else begin
						//new field
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

//Note: these are in pixel_clk domain
reg [1:0] x_skip_ctr;
reg [1:0] y_skip_ctr;
reg [19:0] video_addr;
reg [19:0] video_addr_clkxing[1:0];
reg next_field_xing[1:0];

always @(posedge clk) begin
	//As the pixel clock is independent of the
	//main clock, we need to do clock domain crossing.
	curr_vid_addr <= video_addr_clkxing[1];
	video_addr_clkxing[1] <= video_addr_clkxing[0];
	video_addr_clkxing[0] <= video_addr;
	next_field_out <= next_field_xing[1];
	next_field_xing[1] <= next_field_xing[0];
	next_field_xing[0] <= next_field;
end

//For some reason, the first 24 or so lines are in the overscan region? Perhaps the vga encoder 
//is slightly broken. This is a workaround, I should look into what's really happening...
reg [7:0] skip_lines;

always @(posedge pixel_clk) begin
	if (reset) begin
		video_addr <= 0;
		skip_lines <= 0;
	end else begin
		if (next_field) begin
			x_skip_ctr <= 0;
			y_skip_ctr <= 0;
			video_addr <= 0;
			skip_lines <= 0;
		end else if (next_line) begin
			if (skip_lines > 37) begin
				y_skip_ctr <= (y_skip_ctr == 2) ? 0 : y_skip_ctr+1;
				if (y_skip_ctr != 2 && video_addr[19:9] < 320) begin
					video_addr[19:9] <= video_addr[19:9]+1;
				end
				video_addr[8:0] <= 0;
			end else begin
				skip_lines <= skip_lines + 1;
			end
		end else if (fetch_next) begin
			x_skip_ctr <= x_skip_ctr + 1;
			if (x_skip_ctr != 3) begin
				video_addr <= video_addr + 1;
			end
		end
	end
end

endmodule