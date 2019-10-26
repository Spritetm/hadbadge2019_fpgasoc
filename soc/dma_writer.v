/*
 * Simple buffered DMA writer.
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

module dma_writer (
	input clk,
	input reset,

	input [31:0] dst_addr, //note: 2 lsbs ignored by memory
	input [15:0] len, //in words
	input run,
	output done,

	input [31:0] src_data,
	input src_strobe,
	output src_done,

	output reg [31:0] mem_addr,
	output reg [31:0] mem_data,
	output mem_wr,
	input mem_rdy
);

reg [8:0] fifo_wraddr;
reg [8:0] fifo_rdaddr;

dma_wr_fifomem fifo (
	.clk(clk),
	.w_en(src_strobe),
	.w_data(src_data),
	.w_addr(fifo_wraddr),
	.r_data(mem_data),
	.r_addr(fifo_rdaddr)
);

reg [15:0] words_left_src;
reg [15:0] words_left_mem;

assign src_done = (words_left_src == 0);
assign done = (words_left_mem == 0);

reg mem_do_wr;
assign mem_wr = mem_do_wr;// && !mem_rdy;

always @(posedge clk) begin
	if (reset) begin
		mem_addr <= 0;
		mem_do_wr <= 0;
		fifo_wraddr <= 0;
		fifo_rdaddr <= 0;
		words_left_src <= 0;
		words_left_mem <= 0;
	end else begin
		if (done) begin
			fifo_wraddr <= 0;
			fifo_rdaddr <= 0;
			if (run) begin
				mem_addr[31:2] <= dst_addr[31:2];
				mem_addr[1:0] <= 0;
				words_left_src <= len;
				words_left_mem <= len;
			end
		end else begin
			if (words_left_src != 0) begin
				if (src_strobe) begin
					fifo_wraddr <= fifo_wraddr + 1;
					words_left_src <= words_left_src - 1;
				end
			end
			if (words_left_mem != 0) begin
				if (mem_do_wr) begin
					if (mem_rdy) begin
						mem_do_wr <= 0;
						fifo_rdaddr <= fifo_rdaddr + 1;
						words_left_mem <= words_left_mem - 1;
						mem_addr[31:2] <= mem_addr[31:2] + 1;
					end
				end else begin
					if (fifo_rdaddr != fifo_wraddr) begin
						mem_do_wr <= 1;
					end
				end
			end
		end
	end
end

endmodule

module dma_wr_fifomem #(
	parameter integer FIFO_WORDS = 512
) (
	input clk,
	input w_en,
	input [31:0] w_data,
	input [$clog2(FIFO_WORDS)-1:0] w_addr,
	output [31:0] r_data,
	input [$clog2(FIFO_WORDS)-1:0] r_addr
);

reg [31:0] ram [0:FIFO_WORDS-1];

assign r_data = ram[r_addr];
always @(posedge clk) begin
	if (w_en) ram[w_addr] <= w_data;
end

endmodule

