/*
Qpi interface. Note that this code assumes the chip already is in whatever state it needs to be to 
accept read/write commands over a qpi interface, e.g. by having a microcontroller or state machine bitbang 
the lines manually.
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


/*
This has both an interface for 'automated' QPI reading/writing, currently used by the PSRAM, as well as 
a method of sending user SPI commands, intended for flash writing and 'misc'.

How to use:
- Wait until is_idle is 1
- Put first word on wdata if write
- Put address to start reading/writing on addr
- Activate do_rdata or do_wdata
- When next_word is high, put next word on wdata or read word from rdata
- De-activate do_rdata or do_wdata when done

Note:
- Do_read/do_write should stay active as long as there's data to read/write. If it goes inactive,
  the current word will finish writing.
- This code needs at least one dummy cycle on read.

Wrt upgrading speed to 2x memory bus clock using a 2nd tap from the same PLL:
(on needing domain-crossing flipflops)
06:34 < tnt> Sprite_tm: no, you can get aways with much less in theory. _but_ ... nextpnr currently can't constraint clock 
             domain path.
06:34 < tnt> err "cross-clock domain path"
06:49 < Sprite_tm> tnt: Erm, what does that mean in practice? It doesn't know the two clocks are related?
06:55 < tnt> Sprite_tm: yes and it won't do any analysis on that path (just report the max-delay but without pass/fail or 
             attempt to optimize AFAIK).
06:56 < tnt> In general for those, I don't use a full cross clock, but I do make sure the output is a register and the input is 
             either a register or a single LUT + FF.
06:56 < Sprite_tm> Hm, gotcha, good advice, thanks.


*/

module qpimem_iface #(
	//ly68l6400:
	parameter [7:0] READCMD = 'hEB,
	parameter [7:0] WRITECMD = 'h38,
	parameter integer READDUMMY = 7,
	parameter integer WRITEDUMMY = 0,
	parameter [3:0] DUMMYVAL = 0,
	parameter [0:0] CMD_IS_SPI = 0
/*
	//w25q32:
	//NOTE: untested/not working. Write is probably impossible to get to work (because it's a flash part).
	parameter [7:0] READCMD = 'hEb,
	parameter [7:0] WRITECMD = 'hA5,
	parameter integer READDUMMY = 7,
	parameter [3:0] DUMMYVAL = 'hf,
	parameter integer WRITEDUMMY = 1,
	parameter [0:0] CMD_IS_SPI = 1
*/
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

	input spi_xfer_claim, //pull high to claim for SPI transaction (will lower CS while set and stop qpi interface from interfering)
	input do_spi_xfer,    //Pull high for one clock cycle, transaction will start. Wait for is_idle to be nonzero and it will be done. Note: spi_xfer_wdata latches on this.
	output spi_xfer_idle, //high if spi xfer is claimed and idling
	input [7:0] spi_xfer_wdata,
	output reg [7:0] spi_xfer_rdata,

	output spi_clk,
	output spi_ncs,
	output reg spi_selected,
	output [3:0] spi_sout,
	input [3:0] spi_sin,
	output reg spi_bus_qpi,
	output reg spi_oe
);


reg spi_ncs_u;
reg [3:0] spi_sout_u;
reg [3:0] spi_sin_r;
reg spi_bus_qpi_u, spi_oe_u;

OFS1P3DX oreg_cs(.D(spi_ncs_u), .SP(1), .SCLK(clk), .CD(rst), .Q(spi_ncs));
genvar i;
for (i=0; i<4; i++) begin
	OFS1P3DX oreg_sout[i+1](.D(spi_sout_u[i]), .SP(1'b1), .SCLK(clk), .CD(rst), .Q(spi_sout[i]));
	IFS1P3DX ireg_sin[i+1](.D(spi_sin[i]), .SP(1'b1), .SCLK(clk), .CD(rst), .Q(spi_sin_r[i]));
end

reg clk_active;
reg clk_active_r;
assign spi_clk = !clk & clk_active_r;


always @(posedge clk) begin
	spi_bus_qpi <= spi_bus_qpi_u;
	spi_oe <= spi_oe_u;
	clk_active_r <= clk_active;
	spi_selected <= !spi_ncs_u;
end


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
reg [4:0] bitno; //note: this sometimes indicates nibble-no, not bitno. Also used to store dummy nibble count.
reg [31:0] data_shifted;


parameter STATE_IDLE = 0;
parameter STATE_CMDOUT = 1;
parameter STATE_ADDRESS = 2;
parameter STATE_DUMMYBYTES = 3;
parameter STATE_DATA = 4;
parameter STATE_SPIXFER_CLAIMED = 5;
parameter STATE_SPIXFER_DOXFER = 6;
parameter STATE_SPIXFER_LASTBIT = 7;
parameter STATE_TRANSEND = 8;

//If using registered I/O, we need 2 more dummy cycles.
parameter integer READDUMMY_ADJ = READDUMMY + 2;

reg [7:0] spi_xfer_wdata_latched;
reg [7:0] spi_xfer_rdata_shifted;

assign is_idle = (state == STATE_IDLE) && !do_read && !do_write && !spi_xfer_claim;
assign spi_xfer_idle = (state == STATE_SPIXFER_CLAIMED) && !do_spi_xfer;

reg curr_is_read;
wire [7:0] command;
assign command = curr_is_read ? READCMD : WRITECMD;
reg keep_transferring;

always @(posedge clk) begin
	if (rst) begin
		state <= 0;
		bitno <= 0;
		spi_oe_u <= 0;
		spi_ncs_u <= 1;
		spi_sout_u <= 0;
		curr_is_read <= 0;
		keep_transferring <= 0;
		spi_xfer_wdata_latched <= 0;
		spi_xfer_rdata <= 0;
		spi_bus_qpi_u <= 0;
	end else begin
		if (next_word) begin
			keep_transferring <= (do_read || do_write);
		end

		next_word <= 0;
		if (state == STATE_IDLE) begin
			spi_ncs_u <= 1;
			clk_active <= 0;
			if (do_read || do_write) begin
				//New write or read cycle starts.
				state <= STATE_CMDOUT;
				bitno <= 7;
				curr_is_read <= do_read;
				spi_bus_qpi_u <= !(CMD_IS_SPI);
				clk_active <= 1;
			end else if (spi_xfer_claim) begin
				state <= STATE_SPIXFER_CLAIMED;
				bitno <= 7;
			end
		end else if (state == STATE_CMDOUT) begin
			//Send out command
			spi_ncs_u <= 0;
			spi_oe_u <= 1;
			if (CMD_IS_SPI) begin
				spi_sout_u <= {3'h6, command[bitno]};
				if (bitno == 0) begin
					state <= STATE_ADDRESS;
					bitno <= 5;
				end else begin
					bitno <= bitno - 1;
				end
			end else begin
				spi_sout_u <= command[bitno -: 4];
				if (bitno == 3) begin
					bitno <= 5;
					state <= STATE_ADDRESS;
				end else begin
					bitno <= bitno - 4;
				end
			end
		end else if (state == STATE_ADDRESS) begin
			//Address, in qpi
			spi_bus_qpi_u <= 1;
			spi_sout_u <= addr[bitno*4+3 -: 4];
			if (bitno == 0) begin
				if ((do_read ? READDUMMY_ADJ : WRITEDUMMY)==0) begin
					state <= STATE_DATA;
					bitno <= 7;
					if (curr_is_read) begin
						//nop
					end else begin
						//Make sure we already have the data to shift out.
						data_shifted <= wdata_be;
						next_word <= 1;
					end
				end else begin
					bitno <= do_read ? READDUMMY_ADJ-1 : WRITEDUMMY-1;
					state <= STATE_DUMMYBYTES;
				end
			end else begin
				bitno <= bitno - 1;
			end
		end else if (state == STATE_DUMMYBYTES) begin
			//Dummy bytes. Amount of nibbles is in bitno.
			spi_sout_u <= DUMMYVAL;
			bitno <= bitno - 1;
			if (bitno==2) begin
				//last cycles are actually already when the flash is already sending back data,
				//but because of registers it takes a while for us to see that.
				spi_oe_u <= 0;
			end
			if (bitno==0) begin
				//end of dummy cycle
				state <= STATE_DATA;
				if (curr_is_read) begin
					bitno <= 7;
				end else begin
					//Make sure we already have the data to shift out.
					data_shifted <= wdata_be;
					next_word <= 1;
					bitno <= 7;
				end
			end
		end else if (state == STATE_DATA) begin
			//Data state.
			if (curr_is_read) begin //read
				if (bitno==0) begin
					rdata_be <= {data_shifted[31:4], spi_sin_r[3:0]};
					next_word <= 1;
					bitno <= 7;
					if (!do_read) begin //abort?
						state <= STATE_TRANSEND;
						spi_ncs_u <= 1;
					end
				end else begin
					data_shifted[bitno*4+3 -: 4]<=spi_sin_r;
					bitno<=bitno-1;
				end
			end else begin //write
				spi_sout_u <= data_shifted[bitno*4+3 -: 4];
				if (bitno==0) begin
					//note host may react on next_word going high by putting one last word on the bus, then
					//lowering do_write. This is why we use keep_transfering instead of do_write
					if (!keep_transferring) begin //abort?
						state <= STATE_TRANSEND;
					end else begin
						data_shifted <= wdata_be;
						next_word <= 1;
						bitno <= 7;
					end
				end else begin
					bitno<=bitno-1;
				end
			end
		end else if (state == STATE_SPIXFER_CLAIMED) begin
			//Send out user spi byte
			bitno <= 7;
			spi_ncs_u <= 0;
			clk_active <= 0;
			if (do_spi_xfer) begin
				state <= STATE_SPIXFER_DOXFER;
				spi_xfer_wdata_latched <= spi_xfer_wdata;
			end else if (!spi_xfer_claim) begin
				state <= STATE_TRANSEND;
			end
		end else if (state == STATE_SPIXFER_DOXFER) begin
			clk_active <= 1;
			spi_sout_u <= {3'h6, spi_xfer_wdata_latched[7]};
			spi_xfer_wdata_latched <= {spi_xfer_wdata_latched[6:0], 1'h0};
			spi_xfer_rdata_shifted <= {spi_xfer_rdata_shifted[6:0], spi_sin_r[1]};
			if (bitno == 0) begin
				state <= STATE_SPIXFER_LASTBIT;
				bitno <= 2; //need to wait for the transfer to get through the output/input registers
			end else begin
				bitno <= bitno - 1;
			end
		end else if (state == STATE_SPIXFER_LASTBIT) begin
			clk_active <= 0;
			//sample final input bit, send to output
			spi_xfer_rdata_shifted <= {spi_xfer_rdata_shifted[6:0], spi_sin_r[1]};
			spi_xfer_rdata <= {spi_xfer_rdata_shifted[6:0], spi_sin_r[1]};
			if (bitno == 0) begin
				state <= STATE_SPIXFER_CLAIMED;
			end else begin
				bitno <= bitno - 1;
			end
		end else begin //state=STATE_TRANSEND
			spi_ncs_u <= 1;
			spi_oe_u <= 0;
			spi_bus_qpi_u <= 0;
			state <= 0;
			clk_active <= 0;
		end
	end
end


endmodule
