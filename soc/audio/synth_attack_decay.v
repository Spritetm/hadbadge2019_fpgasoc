/*
 * synth_attack_decay.v
 *
 * vim: ts=4 sw=4
 *
 * Audio synthesizer: Exponential attack/decay for envelope
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

module synth_attack_decay #(
	parameter integer WIDTH = 8
)(
	input  wire [WIDTH-1:0] vol_in_0,
	input  wire [7:0] k_attack_0,
	input  wire [7:0] k_decay_0,
	input  wire mode_0,	// 0 Rise / 1 Decay

	output reg  [WIDTH-1:0] vol_out_1,

	input  wire [15:0] rng,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);
	// Signals
	wire [17:0] a0, a1;
	wire [17:0] a;
	wire [17:0] b;
	wire [35:0] m;
	wire [35:0] mo;
	reg  [35:0] mo_r;

	// Input muxing
	assign a0 = { {(18-WIDTH){1'b0}}, vol_in_0 };
	assign a1 = mode_0 ? 18'h0000 : 18'h00100;
	assign b  = { 6'h00, mode_0 ? k_decay_0 : k_attack_0, 4'h8 };

	// DSP: Pre-adder
	assign a = a0 - a1;

	// DSP: Multiplier
	assign m = $signed(a) * $signed(b);

	// DSP: Post adder
	assign mo = { vol_in_0, rng } - m;

	// DSP: Output register
	always @(posedge clk)
		if (rst)
			mo_r <= 0;
		else
			mo_r <= mo;

	// Final saturation
	always @(*)
		if (mo_r[35])
			vol_out_1 = 8'h00;
		else if (|mo_r[WIDTH+19:WIDTH+16])
			vol_out_1 = 8'hff;
		else
			vol_out_1 = mo_r[WIDTH+15:16];

endmodule // synth_attack_decay
