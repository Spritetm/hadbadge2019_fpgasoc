/*
 * Simplified SPI SRAM model. Supports qpi only.
 *
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

module spiram (
	input spi_clk,
	input spi_ncs,
	input [3:0] spi_sin,
	output reg [3:0] spi_sout,
	input spi_oe
);

reg [7:0] mem [0:8*1024*1024-1];

reg [3:0] spi_sout_next;
always @(negedge spi_clk) begin
	spi_sout <= spi_sout_next;
end

integer state;
reg [23:0] addr;
reg [7:0] cmd;
reg hinib;
integer i;
initial begin
	state <= 0;
	for (i=0; i<8*1024*1024; i++) begin
		mem[i]=i & 'hff;
	end
end

always @(posedge spi_clk) begin
	if (spi_ncs) begin
		state <= 0;
		hinib <= 1;
	end else begin
		spi_sout_next <= 'hz;
		if (state==0) begin
			cmd[7:4]<=spi_sin;
		end else if (state==1) begin
			cmd[3:0]<=spi_sin;
		end else if (state==2) begin
			addr[23:20]<=spi_sin;
		end else if (state==3) begin
			addr[19:16]<=spi_sin;
		end else if (state==4) begin
			addr[15:12]<=spi_sin;
		end else if (state==5) begin
			addr[11:8]<=spi_sin;
		end else if (state==6) begin
			addr[7:4]<=spi_sin;
		end else if (state==7) begin
			addr[3:0]<=spi_sin;
		end else begin
			if (cmd=='heb) begin //fast read
				if (state>=13) begin
					if (hinib) begin
						spi_sout_next <= mem[addr][7:4];
						hinib <= 0;
					end else begin
						spi_sout_next <= mem[addr][3:0];
						hinib <= 1;
						addr <= addr + 1;
					end
				end
			end else if (cmd=='h02 || cmd=='h38) begin
				if (hinib) begin
					mem[addr][7:4] <= spi_sin;
					hinib <= 0;
				end else begin
					mem[addr][3:0] <= spi_sin;
					hinib <= 1;
					addr <= addr + 1;
				end
			end else begin
				$display("psram: unknown cmd %h", cmd);
			end
		end
		state <= state + 1;
	end
end

endmodule