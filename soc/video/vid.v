//This is a Verilator top simulation module.
//Not used for actual synthesis.

module vid (
	input clk,
	input reset,
	
	input [24:0] addr,
	input [31:0] din,
	output [31:0] dout,
	input [3:0] wstrb,
	input ren,
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


reg [31:0] qpi_rdata;
wire [23:0] qpi_addr;
wire qpi_do_read;
reg qpi_is_idle;
reg qpi_next_word;

reg [2:0] qpi_tick;
always @(posedge clk) begin
	if (qpi_is_idle && !qpi_do_read) begin
		qpi_tick <= 'h0;
		qpi_rdata <= 0;
	end else begin
		qpi_tick <= qpi_tick + 1;
	end
	qpi_next_word <= 0;
	if (&qpi_tick) begin
		if (qpi_is_idle && qpi_do_read) begin
			qpi_rdata[3:0] <= qpi_addr[12:9];
			qpi_rdata[7:4] <= qpi_addr[12:9];
			qpi_rdata[11:8] <= qpi_addr[12:9];
			qpi_rdata[15:12] <= qpi_addr[12:9];
			qpi_rdata[19:16] <= qpi_addr[12:9];
			qpi_rdata[23:20] <= qpi_addr[12:9];
			qpi_rdata[27:24] <= qpi_addr[12:9];
			qpi_rdata[31:28] <= qpi_addr[12:9];
		end
		qpi_is_idle <= !qpi_do_read;
		qpi_next_word <= 1;
	end
end

vid_linerenderer linerenderer (
	.clk(clk),
	.reset(reset),
	.addr(addr),
	.din(din),
	.wstrb(wstrb),
	.ren(ren),
	.dout(dout),
	.ready(ready),

	.vid_addr(vid_addr),
	.vid_data_out(vid_data_out),
	.vid_wen(vid_wen),
	.vid_ren(vid_ren),
	.vid_data_in(vid_data_in),
	.curr_vid_addr(curr_vid_addr),
	.next_field(next_field),

	.m_next_word(qpi_next_word),
	.m_rdata(qpi_rdata),
	.m_do_read(qpi_do_read),
	.m_addr(qpi_addr),
	.m_is_idle(qpi_is_idle)
);

wire [8:0] linerenderer_w_x;
wire [8:0] linerenderer_w_y;
wire [8:0] curr_output_x;
wire [8:0] curr_output_y;

assign curr_output_x = curr_vid_addr[8:0];
assign curr_output_y = curr_vid_addr[17:9];

assign linerenderer_w_x = vid_addr[8:0];
assign linerenderer_w_y = vid_addr[17:9];

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
	.next_line(next_line),
	.next_field(next_field),
	.red(red),
	.green(green),
	.blue(blue)
);

endmodule;
