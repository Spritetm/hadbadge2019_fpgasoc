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
module video_alphamixer(
	input [31:0] in_a,
	input [31:0] in_b,
	input [7:0] rate,
	output [31:0] out
);

wire [35:0] mulr_out_a[0:3];
wire [35:0] mulr_out_b[0:3];
reg [8:0] alpha_a;
reg [8:0] alpha_b;

always @(*) begin
	if (rate=='hff) begin
		//Hack because otherwise we can never get 100% dst
		alpha_a = 'h100;
		alpha_b = 0;
	end else begin
		alpha_a = {1'0, rate};
		alpha_b = ('h100 - rate);
	end
end

genvar i;
for (i=0; i<4; i++) begin
	mul_18x18 mult_s (
		.a({10'h0, in_a[i*8+:8]}),
		.b({9'h0, alpha_a}),
		.dout(mulr_out_a[i])
	);
	mul_18x18 mult_d (
		.a({10'h0, in_b[i*8+:8]}),
		.b({9'h0, alpha_b}),
		.dout(mulr_out_b[i])
	);
	assign out[i*8+:8] = mulr_out_a[i][15:8]+mulr_out_b[i][15:8];
end

endmodule