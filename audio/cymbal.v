/* `include "ar.v" */
/* `include "lfsr.v" */

module cymbal #( 
	parameter BITDEPTH   = 14,
	parameter BITFRACTION   = 6
)(
	input sample_clock,
	input rst,
	input [7:0] envelope_attack,
	input [7:0] envelope_decay,
	input gate,
	output [BITDEPTH-1:0] out
);

wire [7:0] lfsr_out;
lfsr cymballfsr (
	.clk(sample_clock),
	.rst(rst),
	.dout(lfsr_out)
);

wire [BITDEPTH-1:0] ar_in;
assign ar_in = lfsr_out << (BITDEPTH - 8);

ar cymbalar (
	.sample_clock(sample_clock),
	.rst(rst),
	.in(ar_in),
	.envelope_attack(envelope_attack),
	.envelope_decay(envelope_decay),
	.gate(gate),
	.out(out)
);

endmodule

