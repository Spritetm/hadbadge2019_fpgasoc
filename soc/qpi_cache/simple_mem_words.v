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

module simple_mem_words #(
	parameter integer WORDS = 256,
	parameter INITIAL_HEX = ""
) (
	input clk,
	input [3:0] wen,
	input [$clog2(WORDS)-1:0] addr,
	input [31:0] wdata,
	output reg [31:0] rdata
);
	reg [31:0] mem [0:WORDS-1];
	wire [31:0] write_data;
	assign write_data[7:0] = wen[0] ? wdata[7:0] : mem[addr][7:0];
	assign write_data[15:8] = wen[1] ? wdata[15:8] : mem[addr][15:8];
	assign write_data[23:16] = wen[2] ? wdata[23:16] : mem[addr][23:16];
	assign write_data[31:24] = wen[3] ? wdata[31:24] : mem[addr][31:24];
	
	integer i;
	initial begin
		if (INITIAL_HEX == "") begin
			for (i=0; i<WORDS; i=i+1) mem[i]='hdeadbeef;
		end else begin
			$readmemh(INITIAL_HEX, mem);
		end
	end

	always @(posedge clk) begin
		rdata <= mem[addr];
		if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
		if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
		if (wen[2]) mem[addr][23:16] <= wdata[23:16];
		if (wen[3]) mem[addr][31:24] <= wdata[31:24];
	end

`ifdef FORMAL
    // see https://zipcpu.com/zipcpu/2018/07/13/memories.html for details
    localparam AW = $clog2(WORDS);
    (* anyconst *) wire [AW-1:0] f_addr;
    reg [32-1:0] f_data;
    reg f_past_valid = 0;

    // allow solver to choose data and put it at some (constant) address
    initial assume(mem[f_addr] == f_data);

    always @(posedge clk) begin
        f_past_valid <= 1;
        // if a write happens at the address then update the data
        if(wen && f_addr == addr) begin
            if (wen[0]) f_data[ 7: 0] <= wdata[ 7: 0];
            if (wen[1]) f_data[15: 8] <= wdata[15: 8];
            if (wen[2]) f_data[23:16] <= wdata[23:16];
            if (wen[3]) f_data[31:24] <= wdata[31:24];
        end

        // assert data coming out is good
        if(f_past_valid)
            if(f_addr == $past(addr))
                assert(rdata == $past(f_data));
    end

    // memory at the address can't change
    always @(*)
        assert(mem[f_addr] == f_data);
`endif

endmodule

endmodule

