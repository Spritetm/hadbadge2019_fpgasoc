module vid (
	input clk,
	input reset,
	
	input [24:0] addr,
	input [31:0] din,
	output [31:0] dout,
	input wen, ren,
	output ready,
	
	input pixelclk,
	input fetch_next,
	output [7:0] red,
	output [7:0] green,
	output [7:0] blue,
	input next_line,
	input next_field
);


wire [19:0] vid_addr;
wire [23:0] vid_data_out;
wire vid_wen, vid_ren;
wire [23:0] vid_data_in;
wire [19:0] curr_vid_addr;

vid_linerenderer linerenderer (
	.clk(clk),
	.reset(reset),
	.addr(addr),
	.din(din),
	.wen(wen),
	.ren(ren),
	.dout(dout),
	.ready(ready),

	.vid_addr(vid_addr),
	.vid_data_out(vid_data_out),
	.vid_wen(vid_wen),
	.vid_ren(vid_ren),
	.vid_data_in(vid_data_in),
	.curr_vid_addr(curr_vid_addr)
);

video_mem video_mem (
	.clk(clk),
	.reset(reset),
	.addr(vid_addr),
	.data_in(vid_data_out),
	.data_out(vid_data_in),
	.wen(vid_wen),
	.ren(vid_ren),
	.curr_vid_addr(curr_vid_addr),
	
	.pixel_clk(pixelclk),
	.fetch_next(fetch_next),
	.red(red),
	.green(green),
	.blue(blue),
	.next_line(next_line),
	.next_field(next_field)
);

endmodule;
