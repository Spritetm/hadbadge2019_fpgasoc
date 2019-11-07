/*
 * synth_cfg_reg.v
 *
 * vim: ts=4 sw=4
 *
 * Audio synthesizer - Multicontext configuration register
 *
 * Copyright (C) 2019  Sylvain Munaut <tnt@246tNt.com>
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

`default_nettype none

module synth_cfg_reg #(
	parameter [2:0] ADDR = 3'h0,
	parameter integer WIDTH = 16
)(
	// Read
	input  wire [3:0]       ctx_0,
	output wire [WIDTH-1:0] out_1,

	// Config bus
	input  wire [31:0] cb_data,
	input  wire [ 3:0] cb_voice,
	input  wire [ 2:0] cb_reg,
	input  wire cb_stb,

	// Clock / Reset
	input  wire clk
);

	wire we = cb_stb & (cb_reg == ADDR);

	synth_reg #(
		.WIDTH(WIDTH)
	) reg_I (
		.rd_data_1(out_1),
		.rd_ctx_0(ctx_0),
		.wr_data(cb_data[WIDTH-1:0]),
		.wr_ctx(cb_voice),
		.wr_ena(we),
		.clk(clk)
	);

endmodule // synth_cfg_reg
