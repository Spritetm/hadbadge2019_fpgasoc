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

/*

Interface for the LCD.

Registers:
00 - Send command to LCD
04 - Send data to LCD
08 - set control bits
  0 - backlight en
  1 - lcd reset
  2 - lcd cs
  3 - switch to line renderer on next vbl (auto-sets 4)
  4 - line render input ena
0C - read status
10 - command to start sending data in linerenderer mode

*/


module lcdiface(
	//CPU interface
	input clk,
	input nrst,
	input [2:0] addr,
	input wen,
	input ren,
	output reg [31:0] rdata,
	input [31:0] wdata,
	output wire ready,

	//Video mem interface
	output reg lcdvm_next_pixel, //note: flag, only hi for 1 clock cycle.
	input lcdvm_newfield, //1 for new field. Make sure to make 0 before lcdvm_wait goes low.
	input lcdvm_wait,
	input [7:0] lcdvm_red,
	input [7:0] lcdvm_green,
	input [7:0] lcdvm_blue,

	//LCD interface
	output reg [17:0] lcd_db,
	output reg lcd_rd,
	output reg lcd_wr,
	output reg lcd_rs,
	output lcd_cs,
	input lcd_id,
	output lcd_rst,
	input lcd_fmark,
	output lcd_blen
);

reg [2:0] state;
reg [4:0] out_ctl;
reg [17:0] lcd_readbuf;
reg lcd_rw_done;
reg [17:0] startcmd;
wire lcd_vm_ena;
wire lcd_vm_start;

assign lcd_vm_ena = out_ctl[4] || (out_ctl[3] && lcdvm_newfield);
assign lcd_vm_start = out_ctl[3];
assign lcd_cs = out_ctl[2];
assign lcd_rst = ~out_ctl[1]; //note: inverted inverted
assign lcd_blen = out_ctl[0];

reg [31:0] rdata_c;
reg ready_c;
reg ready_n;
always @(*) begin
	if (addr=='h2) begin //xx08
		rdata_c = out_ctl;
		ready_c = wen || ren;
	end else if (addr=='h3) begin //xx0c
		rdata_c = {lcd_id, lcd_fmark};
		ready_c = wen || ren;
	end else if (addr=='h4) begin //xx10
		rdata_c = startcmd;
		ready_c = wen || ren;
	end else begin
		rdata_c = lcd_readbuf;
		//Note we ready on state==3, so the CPU can lower its read line on state==4 so it's low when we re-sample
		//it on state==0
		ready_c = (state == 3);
	end
end

always @(posedge clk) begin
	if (!nrst) begin
		rdata <= 0;
		ready_n <= 0;
	end else begin
		rdata <= rdata_c;
		ready_n <= ready_c;
	end
end

assign ready = ready_n & (ren || wen);

reg is_write;
reg sent_newfield;

always @(posedge clk) begin
	if (!nrst) begin
		lcd_rw_done <= 0;
		out_ctl <= 'h6;
		startcmd <= 'h2c;
		state <= 0;
		lcd_readbuf <= 0;
		lcd_rs <= 0;
		lcd_rd <= 1;
		lcd_wr <= 1;
		is_write <= 0;
		lcdvm_next_pixel <= 0;
		sent_newfield <= 0;
	end else begin
		//set lcd_vm_en on start of frame
		if (lcd_vm_start && lcdvm_newfield) out_ctl[4]<=1;
		
		//by default, lcdvm_next_pixel should always be 1 if disabled but running, 0 otherwise
		lcdvm_next_pixel <= (!lcd_vm_ena) && lcd_vm_start;
		if (state==0) begin
			if (wen && addr == 'h2) begin //xx08
				out_ctl <= wdata;
			end else if (wen && addr == 'h4) begin //xx10
				startcmd <= wdata;
			end else if (lcd_vm_ena) begin
				if (lcdvm_newfield && !sent_newfield) begin
					lcd_rs <= 0; //command
					lcd_db <= startcmd;
					state <= 1;
					is_write <= 1;
					sent_newfield <= 1;
				end else if (!lcdvm_wait) begin
					lcd_rs <= 1;
					//lcd unfortunately is wired for 16-bit mode only :/
					lcd_db <= {2'b0, lcdvm_red[7:3], lcdvm_green[7:2], lcdvm_blue[7:3]};
					lcdvm_next_pixel <= 1;
					state <= 1;
					is_write <= 1;
					sent_newfield <= 0;
				end
			end else if ((addr=='h0 || addr=='h1) && (ren || wen)) begin //xx00/xx04
				lcd_rs <= addr[0];
				lcd_db <= wdata[17:0];
				is_write <= wen;
				state <= 1;
			end
		end else if (state==1) begin
			lcd_rd <= is_write;
			lcd_wr <= ~is_write;
			state <= 3; //HACK! Speed up to go >10MHz
		end else if (state==2) begin
			state <= 3;
		end else if (state==3) begin
			state <= 4;
		end else if (state==4) begin
			lcd_readbuf <= lcd_db; //ToDo: LCD_Rin or so
			lcd_rd <= 1;
			lcd_wr <= 1;
			lcd_rw_done <= 1;
			if (!(ren || wen)) state <= 0;
		end else begin
			state <= 0; //fallback
		end
	end
end

endmodule
