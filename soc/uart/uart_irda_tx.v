/*
 * uart_irda_tx.v
 *
 * vim: ts=4 sw=4
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

module uart_irda_tx #(
	parameter integer DIV_WIDTH = 8
)(
	output reg  tx,
	input  wire [7:0] data,
	input  wire valid,
	output reg  ack,
	input  wire [DIV_WIDTH-1:0] div,	// div - 2
	input  wire clk,
	input  wire rst
);

	// Signals
	wire go, done;
	reg  active;

	reg  ce_bit_pre;
	wire ce_bit;
	wire ce_sub;
	reg  [DIV_WIDTH:0] div_cnt;
	reg  [8:0] sub_cnt;

	reg  [9:0] shift;

	// Control
	assign go = valid & ~active;
	assign done = ce_bit & sub_cnt[8];

	always @(posedge clk or posedge rst)
		if (rst)
			active <= 1'b0;
		else
			active <= (active & ~done) | go;

	// Baud rate generator
	always @(posedge clk)
		if (~active | div_cnt[DIV_WIDTH])
			div_cnt <= { 1'b0, div };
		else
			div_cnt <= div_cnt - 1;

	assign ce_sub = div_cnt[DIV_WIDTH];

	// Bit / Sub-bit counter
	always @(posedge clk)
		if (~active)
			sub_cnt <= 9'h08f;
		else if (ce_sub)
			sub_cnt <= sub_cnt - 1;

	always @(posedge clk)
		ce_bit_pre <= ~|sub_cnt[3:0];

	assign ce_bit = ce_sub & ce_bit_pre;

	// Shift register
	always @(posedge clk or posedge rst)
		if (rst)
			shift <= 10'h3ff;
		else if (go)
			shift <= { 1'b1, data, 1'b0 };
		else if (ce_bit)
			shift <= { 1'b1, shift[9:1] };

	// Outputs
	always @(posedge clk)
		ack <= go;

	always @(posedge clk)
		tx <= ~shift[0] & (sub_cnt[3:0] >= 4'h7) & (sub_cnt[3:0] <= 4'h9);

endmodule // uart_irda_tx
