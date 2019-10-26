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


risc16f84_clk2x pic(
	.clk_i(clk),
	.clk_en_i(pic_can_run),
	.reset_i(reset || pic_reset),
	.int0_i(pic_int0),
	.porta_i(gpio_out[15:8]),
	.portb_i(gpio_out[7:0]),
	.porta_o(gpio_out[15:8]),
	.portb_o(gpio_out[7:0]),
	.rng_i(rng),
	.ram_we_o(ram_we),
	.ram_adr_o(ram_adr),
	.ram_dat_o(ram_dat_w),
	.ram_dat_i(ram_dat_r),
	.prog_adr_o(prog_adr),
	.prog_dat_i(prog_dat)
);

//Needed for memory:
//- Program ram: 14bit*1K (max 8K, but 'F84 only has 1K)
//- Data ram: 8bit*256
wire [9:0] progmem_addr;
wire progmem_wr;
wire [13:0] progmem_dout;

pic_progmem #(
	.ROM_HEX(ROM_HEX)
) progmem (
	.clk(clk),
	.reset(reset),
	.addr(progmem_addr),
	.wr(progmem_wr),
	.din(data_in[13:0]),
	.dout(progmem_dout)
);

reg [7:0] datamem [0:511];

integer i;
initial begin
	for (i=0; i<512; i++) datamem[i]<=0;
end

reg is_ready;
assign ready = is_ready && (wen || ren);

//We run the PIC at half speed so we can use progmem/datamem as single-ported
always @(posedge clk) begin
	if (reset) begin
		pic_can_run <= 0;
		pic_int0 <= 0;
		pic_reset <= 0;
	end else begin
		is_ready <= 0;
		if (pic_can_run) begin
			//PIC just ran a cycle. Handle host bus interfacing.
			pic_can_run <= 0;
			if (ren) begin
				if (address[15:14]=='b00) begin
					data_out <= {30'b0, pic_int0, pic_reset};
				end else if (address[15:14]==2'b01) begin
					data_out <= {24'h0, datamem[address[10:2]]};
				end else if (address[15]==1) begin
					data_out <= {18'h0, progmem_dout};
				end
				is_ready <= 1;
			end
			if (wen) begin
				if (address[15:14]=='b00) begin
					pic_int0 <= data_in[1];
					pic_reset <= data_in[0];
				end else if (address[15:14]==2'b01) begin
					datamem[address[10:2]] <= data_in[7:0];
				end else if (address[15]==1) begin
					//progmem[address[11:2]] <= data_in[13:0];
				end
				is_ready <= 1;
			end
		end else begin
			//Run the PIC for another cycle.
			if (ram_we) begin
				datamem[ram_adr] <= ram_dat_w;
			end
			ram_dat_r <= datamem[ram_adr];
			pic_can_run <= 1;
		end
	end
end

endmodule

module pic_progmem #(
	parameter ROM_HEX = "rom_initial.hex"
) (
	input clk,
	input reset,
	input [9:0] addr,
	input wr,
	input [13:0] din,
	output [13:0] dout
);

reg [13:0] progmem [0:1023];
reg [9:0] addr_reg;
assign dout = progmem[addr_reg];

integer i;
initial begin
	$readmemh(ROM_HEX, progmem);
end

always @(posedge clk) begin
	if (reset) begin
		addr_reg <= 0;
	end else begin
		addr_reg <= addr;
		if (wr) progmem[addr]<=din;
	end
end

endmodule
