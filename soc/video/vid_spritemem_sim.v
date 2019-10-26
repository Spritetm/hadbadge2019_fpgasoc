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
module vid_spritemem (DataInA, DataInB, ByteEnA, ByteEnB, AddressA, AddressB, 
    ClockA, ClockB, ClockEnA, ClockEnB, WrA, WrB, ResetA, ResetB, QA, QB)/* synthesis NGD_DRC_MASK=1 */;
    input wire [31:0] DataInA;
    input wire [63:0] DataInB;
    input wire [3:0] ByteEnA;
    input wire [3:0] ByteEnB;
    input wire [8:0] AddressA;
    input wire [7:0] AddressB;
    input wire ClockA;
    input wire ClockB;
    input wire ClockEnA;
    input wire ClockEnB;
    input wire WrA;
    input wire WrB;
    input wire ResetA;
    input wire ResetB;
    output reg [31:0] QA;
    output reg [63:0] QB;

	reg [63:0] mem[0:255];

	always @(posedge ClockA) begin
		if (ResetA) begin
			QA <= 0;
		end else if (ClockEnA) begin
			if (AddressA[0]==0) begin
				QA <= mem[AddressA[8:1]][31:0];
				if (WrA && ByteEnA[0]) mem[AddressA[8:1]][7:0]<=DataInA[7:0];
				if (WrA && ByteEnA[1]) mem[AddressA[8:1]][15:8]<=DataInA[15:8];
				if (WrA && ByteEnA[2]) mem[AddressA[8:1]][23:16]<=DataInA[23:16];
				if (WrA && ByteEnA[3]) mem[AddressA[8:1]][31:24]<=DataInA[31:24];
			end else begin
				QA <= mem[AddressA[8:1]][63:32];
				if (WrA && ByteEnA[0]) mem[AddressA[8:1]][39:32]<=DataInA[7:0];
				if (WrA && ByteEnA[1]) mem[AddressA[8:1]][47:40]<=DataInA[15:8];
				if (WrA && ByteEnA[2]) mem[AddressA[8:1]][55:48]<=DataInA[23:16];
				if (WrA && ByteEnA[3]) mem[AddressA[8:1]][63:56]<=DataInA[31:24];
			end
		end
	end

	always @(posedge ClockB) begin
		if (ResetB) begin
			QB <= 0;
		end else if (ClockEnB) begin
			QB <= mem[AddressB];
			if (WrB && ByteEnB[0]) mem[AddressB][7:0]<=DataInB[7:0];
			if (WrB && ByteEnB[1]) mem[AddressB][15:8]<=DataInB[15:8];
			if (WrB && ByteEnB[2]) mem[AddressB][23:16]<=DataInB[23:16];
			if (WrB && ByteEnB[3]) mem[AddressB][31:24]<=DataInB[31:24];
		end
	end

endmodule
