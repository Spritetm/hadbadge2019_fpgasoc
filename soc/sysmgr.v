/*
 * sysmgr.v
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

module sysmgr (
	input  wire clk_in,
	input  wire rst_in,
	output wire clk_24m,
	output wire clk_48m,
	output wire clk_96m,
	output wire rst_out
);

	// Signals
	wire clk_fb;

	wire pll_lock;
	wire pll_reset;

	wire clk_24m_i;
	wire clk_48m_i;
	wire clk_96m_i;
	wire rst_i;
	reg [7:0] rst_cnt;

	// PLL instance
	(* FREQUENCY_PIN_CLKI="8" *)
	(* FREQUENCY_PIN_CLKOP="96" *)
	(* FREQUENCY_PIN_CLKOS="48" *)
	(* FREQUENCY_PIN_CLKOS2="24" *)
	(* ICP_CURRENT="12" *)
	(* LPF_RESISTOR="8" *)
	(* MFG_ENABLE_FILTEROPAMP="1" *)
	(* MFG_GMCREF_SEL="2" *)
	EHXPLLL #(
        .PLLRST_ENA("ENABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .CLKOP_FPHASE(0),
        .CLKOP_CPHASE(5),
        .OUTDIVIDER_MUXA("DIVA"),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(6),
        .CLKOS_ENABLE("ENABLED"),
        .CLKOS_DIV(12),
        .CLKOS_CPHASE(2),
        .CLKOS_FPHASE(4),
        .CLKOS2_ENABLE("ENABLED"),
        .CLKOS2_DIV(24),
        .CLKOS2_CPHASE(2),
        .CLKOS2_FPHASE(4),
        .CLKFB_DIV(12),
        .CLKI_DIV(1),
        .FEEDBK_PATH("INT_OP")
    ) pll_I (
        .CLKI(clk_in),
        .CLKFB(clk_fb),
        .CLKINTFB(clk_fb),
        .CLKOP(clk_96m_i),
        .CLKOS(clk_48m_i),
        .CLKOS2(clk_24m_i),
        .RST(pll_reset),
        .STDBY(1'b0),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b0),
        .PHASESTEP(1'b0),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(pll_lock)
	);

	assign clk_24m = clk_24m_i;
	assign clk_48m = clk_48m_i;
	assign clk_96m = clk_96m_i;

	// PLL reset generation
	assign pll_reset = rst_in;

	// Logic reset generation
	always @(posedge clk_24m_i)
		if (!pll_lock)
			rst_cnt <= 8'h0;
		else if (~rst_cnt[7])
			rst_cnt <= rst_cnt + 1;

	assign rst_i = ~rst_cnt[7];

	assign rst_out = rst_i;

endmodule // sysmgr
