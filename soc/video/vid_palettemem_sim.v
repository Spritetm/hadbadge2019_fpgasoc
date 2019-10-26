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

`timescale 1 ns / 1 ps
module vid_palettemem (DataInA, DataInB, AddressA, AddressB, 
    ClockA, ClockB, ClockEnA, ClockEnB, WrA, WrB, ResetA, ResetB, QA, QB)/* synthesis NGD_DRC_MASK=1 */;
    input wire [31:0] DataInA;
    input wire [31:0] DataInB;
    input wire [8:0] AddressA;
    input wire [8:0] AddressB;
    input wire ClockA;
    input wire ClockB;
    input wire ClockEnA;
    input wire ClockEnB;
    input wire WrA;
    input wire WrB;
    input wire ResetA;
    input wire ResetB;
    output reg [31:0] QA;
    output reg [31:0] QB;

	reg [31:0] mem[0:511];

	always @(posedge ClockA) begin
		if (ResetA) begin
			QA <= 0;
		end else if (ClockEnA) begin
			QA <= mem[AddressA];
			if (WrA) mem[AddressA]<=DataInA;
		end
	end

	always @(posedge ClockB) begin
		if (ResetB) begin
			QB <= 0;
		end else if (ClockEnB) begin
			QB <= mem[AddressB];
			if (WrB) mem[AddressB]<=DataInB;
		end
	end

endmodule
