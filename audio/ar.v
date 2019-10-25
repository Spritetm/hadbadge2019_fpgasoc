`include "amplifier.v"
`include "envelope.v"

module ar #(
	parameter BITDEPTH = 14
)(
	input sample_clock,
	input rst,
	input [BITDEPTH-1:0] in,
	input [7:0] envelope_attack,
	input [7:0] envelope_decay,
	input gate,
	output [BITDEPTH-1:0] out
);

// DANGER: if change bit depth, need to pass that info on to submodules

wire [7:0] volume;
envelope myenv (
	.sample_clock(sample_clock),
	.rst(rst),
	.gate(gate),
	.a(envelope_attack),
	.r(envelope_decay),
	.volume(volume) // returns
);

amplifier myamp (
	.in(in),
	.volume(volume),
	.out(out)
);

endmodule
