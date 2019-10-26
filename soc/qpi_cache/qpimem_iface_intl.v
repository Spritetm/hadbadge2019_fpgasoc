/*
Qpi interface to dual interleaved PSRAM chips. Note that this code assumes the chips already
are in whatever state it needs to be to accept read/write commands over a qpi interface, e.g. 
by having a microcontroller or state machine bitbang the lines manually.
*/
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

module qpimem_iface_intl #(
	//ly68l6400:
	parameter [7:0] READCMD = 'hEB,
	parameter [7:0] WRITECMD = 'h38,
	parameter integer READDUMMY = 7,
	parameter integer WRITEDUMMY = 0,
	parameter [3:0] DUMMYVAL = 0
) (
	input clk,
	input rst,
	
	input do_read,
	input do_write,
	output reg next_word,
	input [23:0] addr,
	input [31:0] wdata,
	output [31:0] rdata,
	output is_idle,

	output spi_clk,
	output reg spi_ncs,
	output reg [3:0] spi_sout_a,
	output reg [3:0] spi_sout_b,
	input [3:0] spi_sin_a,
	input [3:0] spi_sin_b,
	output reg spi_bus_qpi,
	output reg spi_oe
);

//Note: 32-bit words from RiscV are little-endian, but the way we send them is big-end first. Swap
//endian-ness to make tests happy.
wire [31:0] wdata_be;
assign wdata_be[31:24]=wdata[7:0];
assign wdata_be[23:16]=wdata[15:8];
assign wdata_be[15:8]=wdata[23:16];
assign wdata_be[7:0]=wdata[31:24];

reg [31:0] rdata_be;
assign rdata[31:24]=rdata_be[7:0];
assign rdata[23:16]=rdata_be[15:8];
assign rdata[15:8]=rdata_be[23:16];
assign rdata[7:0]=rdata_be[31:24];

reg [6:0] state;
reg [4:0] bitno; //note: this sometimes indicates byte-no or nibble-no, not bitno. Also used to store dummy nibble count.
reg [3:0] spi_sin_sampled_a;
reg [3:0] spi_sin_sampled_b;
reg [31:0] data_shifted;

reg clk_active;
assign spi_clk = !clk & clk_active;

parameter STATE_IDLE = 0;
parameter STATE_CMDOUT = 1;
parameter STATE_ADDRESS = 2;
parameter STATE_DUMMYBYTES = 3;
parameter STATE_DATA = 4;
parameter STATE_TRANSEND = 8;


assign is_idle = (state == STATE_IDLE) && !do_read && !do_write;

always @(negedge clk) begin
	spi_sin_sampled_a <= spi_sin_a;
	spi_sin_sampled_b <= spi_sin_b;
end

reg curr_is_read;
wire [7:0] command;
assign command = curr_is_read ? READCMD : WRITECMD;
reg keep_transferring;

wire [23:0] psram_addr;
assign psram_addr = {1'b0, addr[23:1]};

always @(posedge clk) begin
	if (rst) begin
		state <= 0;
		bitno <= 0;
		spi_oe <= 0;
		spi_ncs <= 1;
		spi_sout_a <= 0;
		spi_sout_b <= 0;
		curr_is_read <= 0;
		keep_transferring <= 0;
		spi_bus_qpi <= 0;
	end else begin
		if (next_word) begin
			keep_transferring <= (do_read || do_write);
		end

		next_word <= 0;
		if (state == STATE_IDLE) begin
			spi_ncs <= 1;
			clk_active <= 0;
			if (do_read || do_write) begin
				//New write or read cycle starts.
				state <= STATE_CMDOUT;
				bitno <= 7;
				curr_is_read <= do_read;
				spi_bus_qpi <= 1;
				clk_active <= 1;
			end
		end else if (state == STATE_CMDOUT) begin
			//Send out command
			spi_ncs <= 0;
			spi_oe <= 1;
			spi_sout_a <= command[bitno -: 4];
			spi_sout_b <= command[bitno -: 4];
			if (bitno == 3) begin
				bitno <= 5;
				state <= STATE_ADDRESS;
			end else begin
				bitno <= bitno - 4;
			end
		end else if (state == STATE_ADDRESS) begin
			//Address, in qpi. Note that because we store the data in 2 PSRAMS, the
			//addresses are multiplied by 2.
			spi_sout_a <= psram_addr[bitno*4+3 -: 4];
			spi_sout_b <= psram_addr[bitno*4+3 -: 4];
			if (bitno == 0) begin
				if ((do_read ? READDUMMY : WRITEDUMMY)==0) begin
						state <= STATE_DATA;
						bitno <= 3;
					if (curr_is_read) begin
						//nop
					end else begin
						//Make sure we already have the data to shift out.
						data_shifted <= wdata_be;
						next_word <= 1;
					end
				end else begin
					bitno <= do_read ? READDUMMY-1 : WRITEDUMMY-1;
					state <= STATE_DUMMYBYTES;
				end
			end else begin
				bitno <= bitno - 1;
			end
		end else if (state == STATE_DUMMYBYTES) begin
			//Dummy bytes. Amount of nibbles is in bitno.
			//Note that once the host has pulled down 
			spi_sout_a <= DUMMYVAL;
			spi_sout_b <= DUMMYVAL;
			bitno <= bitno - 1;
			if (bitno==0) begin
				//end of dummy cycle
				state <= STATE_DATA;
				if (curr_is_read) begin
					bitno <= 3;
					spi_oe <= 0; //abuse one cycle for turnaround
				end else begin
					//Make sure we already have the data to shift out.
					data_shifted <= wdata_be;
					next_word <= 1;
					bitno <= 3;
				end
			end
		end else if (state == STATE_DATA) begin
			//Data state.
			if (curr_is_read) begin //read
				if (bitno==0) begin
					rdata_be <= {data_shifted[31:8], spi_sin_sampled_a[3:0], spi_sin_sampled_b[3:0]};
					next_word <= 1;
					bitno <= 3;
					if (!do_read) begin //abort?
						state <= STATE_TRANSEND;
						spi_ncs <= 1;
					end
				end else begin
					data_shifted[bitno*8+7 -: 4]<=spi_sin_sampled_a;
					data_shifted[bitno*8+3 -: 4]<=spi_sin_sampled_b;
					bitno<=bitno-1;
				end
			end else begin //write
				spi_sout_a <= data_shifted[bitno*8+7 -: 4];
				spi_sout_b <= data_shifted[bitno*8+3 -: 4];
				if (bitno==0) begin
					//note host may react on next_word going high by putting one last word on the bus, then
					//lowering do_write. This is why we use keep_transfering instead of do_write
					if (!keep_transferring) begin //abort?
						state <= STATE_TRANSEND;
					end else begin
						data_shifted <= wdata_be;
						next_word <= 1;
						bitno <= 3;
					end
				end else begin
					bitno<=bitno-1;
				end
			end
		end else begin //state=STATE_TRANSEND
			spi_ncs <= 1;
			spi_oe <= 0;
			spi_bus_qpi <= 0;
			state <= 0;
			clk_active <= 0;
		end
	end
end


endmodule
