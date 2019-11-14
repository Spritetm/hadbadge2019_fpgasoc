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

module pic_wrapper #(
	parameter ROM_HEX = "rom_initial.hex"
) (
	input clk,
	input reset,

	//I/O for the PIC
	input [15:0] gpio_in,
	output [15:0] gpio_out,
	input [7:0] rng,

	//I/O for the master
	input [15:0] address,
	input [31:0] data_in,
	output reg [31:0] data_out,
	input wen,
	input ren,
	output ready
);

reg [13:0] prog_dat;   // ROM read data
wire [12:0] prog_adr;   // ROM address

reg [7:0] ram_dat_r;     // RAM read data, note only [7:0] are used
wire [7:0] ram_dat_w;     // RAM write data
wire [8:0] ram_adr;     // RAM address; ram_adr[8:7] indicates RAM-BANK
wire ram_we;            // RAM write strobe (H active)
reg pic_reset;
reg pic_int0;
reg pic_can_run;
reg pic_led_passthru;

wire [15:0] gpio_out_pic;

risc16f84_clk2x pic(
	.clk_i(clk),
	.clk_en_i(pic_can_run),
	.reset_i(reset || pic_reset),
	.int0_i(pic_int0),
	.porta_i(gpio_out_pic[15:8]),
	.portb_i(gpio_out_pic[7:0]),
	.porta_o(gpio_out_pic[15:8]),
	.portb_o(gpio_out_pic[7:0]),
	.rng_i(rng),
	.ram_we_o(ram_we),
	.ram_adr_o(ram_adr),
	.ram_dat_o(ram_dat_w),
	.ram_dat_i(ram_dat_r),
	.prog_adr_o(prog_adr),
	.prog_dat_i(prog_dat)
);

assign gpio_out = pic_led_passthru ? gpio_in : gpio_out_pic;

reg sel_progmem;
reg sel_datamem;
wire [13:0] dout_progmem;
wire [7:0] dout_datamem;

pic_progmem progmem (
	.ClockA(clk),
	.ClockB(clk),
	.ResetA(reset),
	.ResetB(reset),
	.ClockEnA(1),
	.ClockEnB(1),
	.DataInA(data_in),
	.DataInB(0),
	.WrA(wen & sel_progmem),
	.WrB(0),
	.AddressA(address[11:2]),
	.AddressB(prog_adr),
	.QA(dout_progmem),
	.QB(prog_dat)
);


pic_datamem datamem (
	.ClockA(clk),
	.ClockB(clk),
	.ResetA(reset),
	.ResetB(reset),
	.ClockEnA(1),
	.ClockEnB(1),
	.DataInA(data_in),
	.DataInB(ram_dat_w),
	.WrA(wen & sel_datamem),
	.WrB(ram_we),
	.AddressA(address[9:2]),
	.AddressB(ram_adr),
	.QA(dout_datamem),
	.QB(ram_dat_r)
);

reg is_ready;
assign ready = is_ready && (wen || ren);


always @(*) begin
	sel_progmem = 0;
	sel_datamem = 0;
	data_out = 0;
	if (address[15:14]==2'b00) begin
		data_out <= {29'b0, pic_led_passthru, pic_int0, pic_reset};
	end else if (address[15:14]==2'b00) begin
		sel_datamem = 1;
		data_out = {24'b0, dout_datamem};
	end else if (address[15]==1) begin
		sel_progmem = 1;
		data_out = {18'b0, dout_progmem};
	end
end

always @(posedge clk) begin
	if (reset) begin
		pic_can_run <= 0;
		pic_int0 <= 0;
		pic_reset <= 0;
		pic_led_passthru <= 1;
		is_ready <= 0;
	end else begin
		is_ready <= wen || ren;
		if (address[15:14]==2'b0 && wen) begin
			pic_led_passthru <= data_in[2];
			pic_int0 <= data_in[1];
			pic_reset <= data_in[0];
		end
		//We only run the PIC every other cycle to accomodate for the cycle of latency in RAM
		if (pic_can_run) begin
			pic_can_run <= 0;
		end else begin
			pic_can_run <= 1;
		end
	end
end

endmodule

