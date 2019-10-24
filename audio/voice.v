`include "oscillator.v"
`include "ar.v"

module voice #( 
	parameter BITDEPTH   = 14,
	parameter BITFRACTION   = 8
)(
	input sample_clock,
	input [3:0] voice_select,
  	input [15:0] pitch_increment,
  	input [7:0] envelope_attack,
  	input [7:0] envelope_decay,
	input gate,

	output [BITDEPTH-1:0] out
);

wire [BITDEPTH-1:0] osc_out;
oscillator #( .BITDEPTH(BITDEPTH), .BITFRACTION(BITFRACTION)) myosc 
(
	.sample_clock(sample_clock),
	.increment(pitch_increment) ,  
	.voice_select(voice_select), 
	.out(osc_out)
);

wire [BITDEPTH-1:0] out;
ar myar (
	.sample_clock(sample_clock),
	.in(osc_out),
	.envelope_attack(envelope_attack),
	.envelope_decay(envelope_decay),
	.gate(gate),
	.out(out)
);

endmodule

