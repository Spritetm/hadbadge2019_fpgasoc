/*
 * synth_mix.v
 *
 * vim: ts=4 sw=4
 *
 * Audio synthesizer: Final mixing and volume scaling
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

module synth_mix #(
	parameter integer IN_WIDTH = 14,
	parameter integer SHIFT = 0
)(
	// Volume settings
	input  wire [ 7:0] vol_global_1,
	input  wire [ 7:0] vol_envelope_1,
	input  wire [ 7:0] vol_voice_l_2,
	input  wire [ 7:0] vol_voice_r_2,

	// Control
	input  wire first_0,
	input  wire last_0,

	// Data
	input  wire [IN_WIDTH-1:0] in_data_3,

	// Output
	output reg [15:0] out_l,
	output reg [15:0] out_r,

	output reg [11:0] out_dc,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);
	// Signals
	reg  [35:0] vol_ge_2;
	reg  [35:0] vol_l_3,    vol_r_3;
	reg  [35:0] data_l_4,   data_r_4;
	wire [15:0] sum_in_l_4, sum_in_r_4;
	reg  [15:0] sum_l_5,    sum_r_5;
	wire first_2, first_4;
	wire last_3, last_5;

	reg  [11:0] dc_sum_3;

	// Control delay
	delay_bit #(2) dly_first02 ( first_0, first_2, clk );
	delay_bit #(2) dly_first24 ( first_2, first_4, clk );
	delay_bit #(3) dly_last03  ( last_0,  last_3,  clk );
	delay_bit #(2) dly_last35  ( last_3,  last_5,  clk );

	// Combine envelope volume with global one
	always @(posedge clk)
		vol_ge_2 <= $signed({10'h000, vol_global_1}) * $signed({10'h000, vol_envelope_1});

	// Combine left / right channel volumes
	always @(posedge clk)
	begin
		vol_l_3 <= $signed(vol_ge_2[17:0]) * $signed({10'h000, vol_voice_l_2});
		vol_r_3 <= $signed(vol_ge_2[17:0]) * $signed({10'h000, vol_voice_r_2});
	end

	// Apply volume to input data
	always @(posedge clk)
	begin
		data_l_4 <= $signed(in_data_3) * $signed({2'b00, vol_l_3[23:8]});
		data_r_4 <= $signed(in_data_3) * $signed({2'b00, vol_r_3[23:8]});
	end

	// Summing
	assign sum_in_l_4 = data_l_4[31-SHIFT:16-SHIFT];
	assign sum_in_r_4 = data_l_4[31-SHIFT:16-SHIFT];

	always @(posedge clk)
	begin
		sum_l_5 <= sum_in_l_4 + (first_4 ? 16'h0000 : sum_l_5);
		sum_r_5 <= sum_in_r_4 + (first_4 ? 16'h0000 : sum_r_5);
	end

	// Final capture
	always @(posedge clk)
		if (last_5) begin
			out_l  <= sum_l_5;
			out_r  <= sum_l_5;
		end

	// DC level
	always @(posedge clk)
		dc_sum_3 <= (first_2 ? 12'h000 : dc_sum_3) + vol_ge_2[15:8] + 1;

	always @(posedge clk)
		if (last_3)
			out_dc <= dc_sum_3;

endmodule // synth_mix
