module clk_8_250_125_25(input clki, 
    output clks1,
    output clks2,
    output locked,
    output clko
);
wire clkfb;
wire clkos;
wire clkop;
(* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .CLKOP_FPHASE(0),
        .CLKOP_CPHASE(1),
        .OUTDIVIDER_MUXA("DIVA"),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(2),
        .CLKOS_ENABLE("ENABLED"),
        .CLKOS_DIV(4),
        .CLKOS_CPHASE(1),
        .CLKOS_FPHASE(0),
        .CLKOS2_ENABLE("ENABLED"),
        .CLKOS2_DIV(20),
        .CLKOS2_CPHASE(1),
        .CLKOS2_FPHASE(0),
        .CLKFB_DIV(63),
        .CLKI_DIV(2),
        .FEEDBK_PATH("INT_OP")
    ) pll_i (
        .CLKI(clki),
        .CLKFB(clkfb),
        .CLKINTFB(clkfb),
        .CLKOP(clkop),
        .CLKOS(clks1),
        .CLKOS2(clks2),
        .RST(1'b0),
        .STDBY(1'b0),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b0),
        .PHASESTEP(1'b0),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(locked)
	);
assign clko = clkop;
endmodule
