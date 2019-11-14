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

module pic_progmem (
	input wire ClockA,
	input wire ClockB,
	input wire ClockEnA,
	input wire ClockEnB,
	input wire ResetA,
	input wire ResetB,
	input wire [13:0] DataInA,
	input wire [13:0] DataInB,
	input wire [9:0] AddressA,
	input wire [9:0] AddressB,
	input wire WrA,
	input wire WrB,
	output reg [13:0] QA,
	output reg [13:0] QB
);

reg [13:0] mem[0:1023];


always @(posedge ClockA) begin
	if (ResetA) begin
		QA <= 0;
	end else begin
		QA <= mem[AddressA];
		if (WrA) begin
			mem[AddressA] <= DataInA;
		end
	end
end


always @(posedge ClockB) begin
	if (ResetB) begin
		QB <= 0;
	end else begin
		QB <= mem[AddressB];
		if (WrB) begin
			mem[AddressB] <= DataInB;
		end
	end
end

endmodule;
