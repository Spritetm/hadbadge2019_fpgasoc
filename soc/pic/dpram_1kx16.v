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
module dpram_1kx16 #(
		parameter INIT_FILE = ""
   ) (
	input clk,
	input rst,
	
	input [9:0] addr_a,
	input [15:0] wdata_a,
	output reg [15:0] rdata_a,
	input wen_a,
	
	input [9:0] addr_b,
	input [15:0] wdata_b,
	output reg [15:0] rdata_b,
	input wen_b
);

reg [15:0] mem [0:1023];

integer i;
initial begin
	if (INIT_FILE == "") begin
		for (i=0; i<1024; i=i+1) mem[i]='h0;
	end else begin
		$readmemh(INIT_FILE, mem);
	end
end


always @(posedge clk) begin
	if (rst) begin
		rdata_a <= 0;
		rdata_b <= 0;
	end else begin
		if (wen_a) mem[addr_a] <= wdata_a;
		if (wen_b) mem[addr_b] <= wdata_b;
		rdata_a <= mem[addr_a];
		rdata_b <= mem[addr_b];
	end
end

endmodule
