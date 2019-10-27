`include "oscillator.v"
`include "ar.v"
`include "scales_rom.v"

module voice #( 
	parameter BITDEPTH   = 14,
	parameter BITFRACTION   = 6,
	parameter [1:0] VOICE = 1
)(
	input sample_clock,
	input rst,
  	input [6:0] note,
  	input [7:0] envelope_attack,
  	input [7:0] envelope_decay,
	input gate,

	output [BITDEPTH-1:0] out
);

wire [15:0] pitch_increment;
midi_note_to_accumulator m (
	.clk(sample_clock),
	.reset(rst),
	.midi_note(note),
	.increment(pitch_increment)
);

wire [BITDEPTH-1:0] osc_out;
oscillator #( .BITDEPTH(BITDEPTH), .BITFRACTION(BITFRACTION), .VOICE(VOICE)) myosc 
(
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(pitch_increment),  
	.out(osc_out)
);

wire [BITDEPTH-1:0] out;
ar myar (
	.sample_clock(sample_clock),
	.rst(rst),
	.in(osc_out),
	.envelope_attack(envelope_attack),
	.envelope_decay(envelope_decay),
	.gate(gate),
	.out(out)
);

endmodule

