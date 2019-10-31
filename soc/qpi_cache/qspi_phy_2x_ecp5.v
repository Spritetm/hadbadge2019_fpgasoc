/*
 * qspi_phy_2x_ecp5.v
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

module qspi_phy_2x_ecp5 #(
	parameter integer N_CS = 1
)(
	// SPI Pads
	inout  wire [3:0] spi_io,
	inout  wire [N_CS-1:0] spi_cs,
	inout  wire spi_sck,

	// SPI PHY interface
	output wire [7:0] spi_io_i,
	input  wire [7:0] spi_io_o,
	input  wire [3:0] spi_io_t,

	input  wire [1:0] spi_sck_o,
	input  wire [N_CS-1:0] spi_cs_o,

	// Clock
	input  wire clk_2x,
	input  wire clk_1x,
	input  wire rst
);

	// Signals
	wire [3:0] spi_io_ir;
	wire [3:0] spi_io_or;
	reg  [3:0] spi_io_td[0:1];
	wire [3:0] spi_io_tr;

	reg  [N_CS-1:0] spi_cs_od[0:1];
	wire [N_CS-1:0] spi_cs_or;
	reg  [1:0] spi_sck_od[0:3];
	wire spi_sck_or;

	// IOs
		// Output DDR
	ODDRX1F phy_io_rego_I[3:0] (
		.D0(spi_io_o[7:4]),		// Rising edge
		.D1(spi_io_o[3:0]),		// Falling edge (after rising edge)
		.RST(1'b0),
		.SCLK(clk_1x),
		.Q(spi_io_or)
	);

		// Output tristate
	always @(posedge clk_1x)
	begin
		spi_io_td[0] <= spi_io_t;
		spi_io_td[1] <= spi_io_td[0];
	end

	OFS1P3DX phy_io_regt_I[3:0] (
		.CD(1'b0),
		.D(spi_io_td[1]),
		.SP(1'b1),
		.SCLK(clk_1x),
		.Q(spi_io_tr)
	);

		// IOB
	TRELLIS_IO #(
		.DIR("BIDIR")
	) phy_io_I[3:0] (
		.B(spi_io),
		.I(spi_io_or),
		.T(spi_io_tr),
		.O(spi_io_ir)
	);

		// Input DDR
	IDDRX1F phy_io_regi_I[3:0] (
		.D(spi_io_ir),
		.Q0(spi_io_i[7:4]),	// Rising edge
		.Q1(spi_io_i[3:0]),	// Falling edge (after rising edge)
		.SCLK(clk_1x),
		.RST(1'b0)
	);

	// Chip Selects
		// Delay match
	always @(posedge clk_1x)
	begin
		spi_cs_od[0] <= spi_cs_o;
		spi_cs_od[1] <= spi_cs_od[0];
	end

		// Output reg
	OFS1P3DX phy_cs_reg_I[N_CS-1:0] (
		.CD(rst),
		.D(spi_cs_od[1]),
		.SP(1'b1),
		.SCLK(clk_1x),
		.Q(spi_cs_or)
	);

		// IOB
	TRELLIS_IO #(
		.DIR("OUTPUT")
	) phy_cs_I[N_CS-1:0] (
		.B(spi_cs),
		.I(spi_cs_or),
		.T(1'b0),
		.O()
	);

	// Clock
		// Delay match
	always @(posedge clk_2x)
	begin
		spi_sck_od[0] <= spi_sck_o;
		spi_sck_od[1] <= spi_sck_od[0];
		spi_sck_od[2] <= spi_sck_od[1];
		spi_sck_od[3] <= spi_sck_od[2];
	end

		// Output DDR
	ODDRX1F phy_clk_rego_I (
		.D0(spi_sck_od[3][1]),		// Rising edge
		.D1(spi_sck_od[3][0]),		// Falling edge (after rising edge)
		.RST(rst),
		.SCLK(clk_2x),
		.Q(spi_sck_or)
	);

		// IOB
	TRELLIS_IO #(
		.DIR("OUTPUT")
	) phy_clk_I (
		.B(spi_sck),
		.I(spi_sck_or),
		.T(1'b0),
		.O()
	);

endmodule // qspi_phy_2x_ecp5
