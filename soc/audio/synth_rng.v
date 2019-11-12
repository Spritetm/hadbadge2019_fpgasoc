/*
 * synth_rng.v
 *
 * vim: ts=4 sw=4
 *
 * Simple RNG with a couple of LFSR
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

// ---------------------------------------------------------------------------
// Main RNG
// ---------------------------------------------------------------------------

module synth_rng (
	output reg  [15:0] out,
	input  wire clk,
	input  wire rst
);

	// Signals
	wire [4:0] out5, out5rev;
	wire [15:0] out16;

	// Instanciate 4 LFSRs of different lengths
	synth_lfsr #(.WIDTH( 5), .POLY( 5'b01001)) lfsr5  (.out(out5),  .clk(clk), .rst(rst));
	synth_lfsr #(.WIDTH(16), .POLY(16'h6701 )) lfsr16 (.out(out16), .clk(clk), .rst(rst));

	// Reverse the 5 bit LFSR output
	genvar i;
	generate
		for (i=0; i<5; i=i+1)
			assign out5rev[i] = out5[4-i];
	endgenerate

	// Combine the outputs 'somehow'
	always @(posedge clk)
		out <= {
			out16[15:11] ^ out5rev,		// 5 bits
			out16[10: 6] ^ out5,		// 5 bits
			out16[5],					// 1 bit
			out16[4:0] ^ out5rev		// 5 bits
		};

endmodule // synth_rng


// ---------------------------------------------------------------------------
// LFSR sub module
// ---------------------------------------------------------------------------

module synth_lfsr #(
	parameter integer WIDTH = 8,
	parameter POLY = 8'h71
)(
	output reg  [WIDTH-1:0] out,
	input  wire clk,
	input  wire rst
);

	// Signals
	wire fb;

	// Linear Feedback
	assign fb = ^(out & POLY);

	// Register
	always @(posedge clk)
		if (rst)
			out <= { {(WIDTH-1){1'b0}}, 1'b1 };
		else
			out <= { fb, out[WIDTH-1:1] };

endmodule // synth_lfsr
