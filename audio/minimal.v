// This is the file that I flash to the boards.  It should represent the basic
// state of the synth chain, and it's also good for the back-and-forth with
// simulation.  

`include "dac.v"
`include "sample_clock.v"
`include "voice.v" 
`include "mixer4.v"

module top( 
	input clk, 
	input [7:0] btn, 
	output [5:0] led, 
	output pwmout
);
/* Button and audio workout */

localparam BITDEPTH    = 14;
localparam BITFRACTION = 6;
localparam SAMPLECLOCK_DIV = 8;
localparam SAMPLEFREQ  = 8000000 / 2**SAMPLECLOCK_DIV;  // 31,250 Hz or 32 us

wire sample_clock;
sample_clock #( .SAMPLECLOCK_DIV(SAMPLECLOCK_DIV) ) mysampleclock ( 
	.clk(clk), .sample_clock(sample_clock) 
);

`define CALC_INCREMENT(hz) $rtoi(hz * 2**(BITDEPTH+BITFRACTION)/SAMPLEFREQ*2)
`define MIDI_NOTE(n) $rtoi(440 * 2**((n-69)/12) * 2**(BITDEPTH+BITFRACTION)/SAMPLEFREQ*2)

reg [3:0] voice;
reg gate1;
reg gate2;
reg gate3;
reg gate4;

wire [BITDEPTH-1:0] osc1_out;
wire [BITDEPTH-1:0] osc2_out;
wire [BITDEPTH-1:0] osc3_out;
wire [BITDEPTH-1:0] osc4_out;

/* reg [7:0] buttons; */
/* always @(posedge clk) begin */
/* 	buttons <= ~btn[7:0]; */
/* 	gate1 <= buttons[0]; */
/* 	gate2 <= buttons[1]; */
/* 	gate3 <= buttons[2]; */
/* 	gate4 <= buttons[3]; */
/* 	voice <= buttons[7:4]; */
/* end */
reg [23:0] slow_counter=0;
always @(posedge sample_clock) begin
	slow_counter <= slow_counter + 1;
	gate1 <= slow_counter[20];
	gate2 <= slow_counter[21];
	gate3 <= slow_counter[22];
	gate4 <= slow_counter[23];
	voice <= slow_counter[23:20];
end

voice osc1 (
	.sample_clock(sample_clock),
	.voice_select(voice),
  	.pitch_increment(`MIDI_NOTE(60)),
  	.envelope_attack(8'h70),
  	.envelope_decay(8'h10),
	.gate(gate1),
	.out(osc1_out)
);
voice osc2 (
	.sample_clock(sample_clock),
	.voice_select(voice),
  	.pitch_increment(`MIDI_NOTE(62)),
  	.envelope_attack(8'h70),
  	.envelope_decay(8'h10),
	.gate(gate2),
	.out(osc2_out)
);
voice osc3 (
	.sample_clock(sample_clock),
	.voice_select(voice),
  	.pitch_increment(`MIDI_NOTE(64)),
  	.envelope_attack(8'h70),
  	.envelope_decay(8'h10),
	.gate(gate3),
	.out(osc3_out)
);
voice osc4 (
	.sample_clock(sample_clock),
	.voice_select(voice),
  	.pitch_increment(`MIDI_NOTE(65)),
  	.envelope_attack(8'h70),
  	.envelope_decay(8'h10),
	.gate(gate4),
	.out(osc4_out)
);

wire [BITDEPTH-1:0] mix;
mixer4 mixer (
	.in1(osc1_out),
	.in2(osc2_out),
	.in3(osc3_out),
	.in4(osc4_out),
	.mix(mix)
);

dac #(.BITDEPTH(BITDEPTH)) mydac (
	.clk (clk),
	.sample_clock (sample_clock),
	.pcm (mix), // input to DAC
	.out (pwmout) // connect to PWM pin
);

endmodule

