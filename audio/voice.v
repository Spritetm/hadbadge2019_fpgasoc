`include "oscillator.v"
`include "ar.v"

module voice #( 
	parameter BITDEPTH   = 14,
	parameter BITFRACTION   = 8
)(
	input sample_clock,
	input rst,
	input [3:0] voice_select,
  	input [15:0] pitch_increment,
  	input [7:0] envelope_attack,
  	input [7:0] envelope_decay,
	input gate,

	output [BITDEPTH-1:0] out
);

`define CALC_INCREMENT(hz) $rtoi(hz * 2**(BITDEPTH+BITFRACTION)/SAMPLEFREQ*2)
`define MIDI_NOTE(n) $rtoi(440.0 * 2**((n-69)/12)/SAMPLEFREQ*2.0 * 2**(BITDEPTH+BITFRACTION))
// midi note to pitch increment
// should probably end up a lookup table?

wire [BITDEPTH-1:0] osc_out;
oscillator #( .BITDEPTH(BITDEPTH), .BITFRACTION(BITFRACTION)) myosc 
(
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(pitch_increment) ,  
	.voice_select(voice_select), 
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

