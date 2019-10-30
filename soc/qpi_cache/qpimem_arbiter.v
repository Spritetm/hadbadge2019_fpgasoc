/*
 * This is an arbiter that allows multiple masters speaking the QPI memory interface protocol to 
 * talk to one QPI memory device.
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


/*
Note: Verilog-2005 (and Yosys, at this time of writing) do not support arrays as ports. Instead, we pack
n m-sized arrays into one n*m-sized array.
*/

module qpimem_arbiter #(
	parameter integer MASTER_IFACE_CNT = 1
) (
	input clk, reset,

	input [32*MASTER_IFACE_CNT-1:0] addr,
	input [32*MASTER_IFACE_CNT-1:0] wdata,
	output reg [32*MASTER_IFACE_CNT-1:0] rdata,
	input [MASTER_IFACE_CNT-1:0] do_read,
	input [MASTER_IFACE_CNT-1:0] do_write,
	output reg [MASTER_IFACE_CNT-1:0] next_word,
	output reg [MASTER_IFACE_CNT-1:0] is_idle,
	
	output reg [31:0] s_addr,
	output reg [31:0] s_wdata,
	input [31:0] s_rdata,
	output reg s_do_write,
	output reg s_do_read,
	input s_is_idle,
	input s_next_word
);

/*
The connected masters are priority-encoded by index; higher index = higher prio. We can do something more fanciful later
(round-robin, fractional priority, ...) but for now this is simple and stupid.
*/

`ifdef verilator
genvar i;
`else
integer i;
`endif

`define SLICE_32(v, i) v[32*i+:32]

reg idle;
reg [$clog2(MASTER_IFACE_CNT)-1:0] active_iface;
reg hold;		//if 1, hold_iface is permanently routed to slave iface
reg [$clog2(MASTER_IFACE_CNT)-1:0] hold_iface;

always @(*) begin
	idle=0;
	active_iface=0;
	for (i=0; i<MASTER_IFACE_CNT; i=i+1) begin : genblk
		`SLICE_32(rdata, i)=s_rdata; //no need to mux this
		is_idle[i]=!(do_read[i] || do_write[i]); //we'll override this if selected
		next_word[i]=0;
		if ((hold && (hold_iface==i)) || ((!hold) && (do_read[i] || do_write[i]))) begin
			idle=0;
			active_iface=i;
		end
	end
	s_addr=`SLICE_32(addr, active_iface);
	s_wdata=`SLICE_32(wdata,  active_iface);
	s_do_read=do_read[active_iface];
	s_do_write=do_write[active_iface];
	//Note: verilator complains about some circular dependency because of this line... no clue what it's on about.
	if (!idle) begin
		next_word[active_iface]=s_next_word;
		is_idle[active_iface]=s_is_idle;
	end
end

always @(posedge clk) begin
	if (reset) begin
		hold <= 0;
		hold_iface <= 0;
	end else begin
		if (hold && s_is_idle) begin
			//Read/write is done; un-hold
			hold <= 0;
		end else if (!idle) begin //note: idle is also 0 if hold was set last run
			//We're serving a master.
			hold <= 1;
			hold_iface <= active_iface;
		end else begin
			hold <= 0;
		end
	end
end

endmodule