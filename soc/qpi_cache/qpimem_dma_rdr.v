/*
 * Simple buffered read-only DMA interface to QPI memory. Uses a blockram as a fifo.
 *
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


//Note: For interleaved psram @ 48MHz, burstlen should be <=32
module qpimem_dma_rdr #(
	//Simple 2-way cache.
	parameter integer FIFO_WORDS=512, //must be power of 2
	parameter unsigned [$clog2(FIFO_WORDS)-1:0] BURST_LEN=16, //in words; note: must be power of 2, <= FIFO_WORDS
	parameter integer ADDR_WIDTH=24 //qpi bus address width
) (
	input clk,
	input rst,
	
	input [ADDR_WIDTH-1:0] addr_start, //byte addr
	input [ADDR_WIDTH-1:0] addr_end, //byte addr
	input run,			//Start/continue DMA transaction. This going low will end the transaction.
	output ready,		//A word is available for reading
	output all_done,	//DMA transaction is complete.
	input do_read,		//Strobe for next word
	output [31:0] rdata,	//Data read
	
	//qpi memory interface
	output reg qpi_do_read,
	input qpi_next_word,
	output reg [ADDR_WIDTH-1:0] qpi_addr,
	input [31:0] qpi_rdata,
	input qpi_is_idle
);

reg [ADDR_WIDTH-1:0] out_addr;
wire [$clog2(FIFO_WORDS)-1:0] fifo_rptr;
wire [$clog2(FIFO_WORDS)-1:0] fifo_wptr;
assign fifo_rptr = out_addr[$clog2(FIFO_WORDS)-1+2:2]; //word addr
assign fifo_wptr = qpi_addr[$clog2(FIFO_WORDS)-1+2:2]; //word addr
assign ready = (fifo_rptr != fifo_wptr);
assign all_done = (out_addr >= addr_end);
wire qpi_done;
assign qpi_done = (qpi_addr >= addr_end);

qpimem_dma_rd_fifomem fifomem(
	.clk(clk),
	.w_en(qpi_next_word),
	.w_addr(fifo_wptr),
	.w_data(qpi_rdata),
	.r_addr(fifo_rptr),
	.r_data(rdata)
);

reg restarting;

always @(posedge clk) begin
	if (rst) begin
		out_addr <= 0;
		qpi_addr <= 0;
		qpi_do_read <= 0;
		restarting <= 1;
	end else begin
		//If we're reading, move out_addr
		if (ready && do_read) begin
			out_addr <= out_addr + 4; //we read one word at a time
		end

		//handle qpi logic
		if (!run) begin
			//End qpi transaction, but do not touch read side of fifo.
			qpi_addr <= addr_start;
			out_addr <= addr_start;
			qpi_do_read <= 0;
			restarting <= 1;
		end else if (restarting) begin
			restarting <= !qpi_is_idle; //we can begin when qpi has finished current transaction
		end else if (qpi_next_word) begin
			qpi_addr <= qpi_addr + 4; //we read one word at a time
			if ((fifo_wptr & (BURST_LEN-1)) == (BURST_LEN-1)) begin
				qpi_do_read <= 0; //abort burst
			end
			if ((qpi_addr+4) >= addr_end) begin
				qpi_do_read <= 0; //abort burst
			end
		end else if (qpi_is_idle && !qpi_do_read) begin
			//See if we should start reading again.
			localparam LOW_TIDE = {22'(FIFO_WORDS) - 22'(BURST_LEN), 2'b00};
			if ((qpi_addr - out_addr) < LOW_TIDE) begin
				if (qpi_addr < addr_end) begin
					qpi_do_read <= 1; //go read more.
				end
			end
		end
	end
end

endmodule

module qpimem_dma_rd_fifomem #(
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
