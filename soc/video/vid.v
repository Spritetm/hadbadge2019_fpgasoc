//This is a Verilator top simulation module.
//Not used for actual synthesis.

/*
 * Copyright (C) 2019  Jeroen Domburg <jeroen@spritesmods.com>
 * All rights reserved.
 *
 * BSD 3-clause, see LICENSE.bsd
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
	input next_field,

	input [31:0] qpi_rdata,
	output [23:0] qpi_addr,
	output qpi_do_read,
	input qpi_is_idle,
	input qpi_next_word
);


wire [19:0] vid_addr;
wire [23:0] vid_data_out;
wire vid_wen, vid_ren;
wire [23:0] vid_data_in;
wire [19:0] curr_vid_addr;
wire preload;

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
	.preload(preload),
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
	.preload(preload),
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
	.blue(blue),

	.lcd_next_pixel(1)
);

endmodule;
