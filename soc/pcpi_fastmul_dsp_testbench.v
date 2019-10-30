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

`timescale 1us/1ns

module stimulus();

reg clk, rst;

reg pcpi_valid;
reg [31:0] pcpi_insn;
reg [31:0] pcpi_rs1;
reg [31:0] pcpi_rs2;
wire [31:0] pcpi_rd_fastmul;
wire [31:0] pcpi_rd_orig;
wire pcpi_ready_fastmul;
wire pcpi_ready_orig;

pcpi_fastmul_dsp fastmul (
	.clk(clk),
	.reset(rst),
	.pcpi_valid(pcpi_valid),
	.pcpi_insn(pcpi_insn),
	.pcpi_rs1(pcpi_rs1),
	.pcpi_rs2(pcpi_rs2),
	.pcpi_rd(pcpi_rd_fastmul),
	.pcpi_ready(pcpi_ready_fastmul)
);

picorv32_pcpi_fast_mul rv32fastmul (
	.clk(clk),
	.resetn(!rst),
	.pcpi_valid(pcpi_valid),
	.pcpi_insn(pcpi_insn),
	.pcpi_rs1(pcpi_rs1),
	.pcpi_rs2(pcpi_rs2),
	.pcpi_rd(pcpi_rd_orig),
	.pcpi_ready(pcpi_ready_orig)
);

//clock toggle
always #0.5 clk = !clk;

reg [31:0] stimuli [0:10240]; 

integer i;
integer j;
integer k;
reg [31:0] res_a;
reg [31:0] res_b;
initial begin
	$dumpfile("pcpi_fastmul_dsp_testbench.vcd");
	$dumpvars(0, stimulus);
	$readmemh("pcpi_fastmul_dsp_stimuli.hex", stimuli);

	clk <= 0;
	rst<=1;
	pcpi_valid<=0;
	pcpi_insn<=0;
	pcpi_insn[6:0]<=7'b0110011;
	pcpi_insn[31:25]<=7'b0000001;
	#4 rst<=0;
	

	for (i=0; i<10240; i=i+2) begin
		for (k=0; k<4; k=k+1) begin
			pcpi_insn[14:12]<=k;
			pcpi_rs1=stimuli[i];
			pcpi_rs2=stimuli[i+1];
			pcpi_valid <= 1;
			#3;
			if (pcpi_rd_fastmul != pcpi_rd_orig) begin
				$display("Result mismatch! %d Insn %d %X x %X fast %X good %X", i, k, pcpi_rs1, pcpi_rs2, pcpi_rd_fastmul, pcpi_rd_orig);
			end
			pcpi_valid <= 0;
			#1;
		end
	end
	$finish;
end



endmodule