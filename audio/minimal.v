// This is the file that I flash to the boards.  It should represent the basic
// state of the synth chain, and it's also good for the back-and-forth with
// simulation.  

`include "dac.v"
`include "oscillator.v"
`include "ar.v"
`include "sample_clock.v"

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
reg [20:0] increment = `CALC_INCREMENT(262) ; 

wire [BITDEPTH-1:0] osc_out;
oscillator #( .BITDEPTH(BITDEPTH), .BITFRACTION(BITFRACTION)) mysaw 
(
	.sample_clock(sample_clock),
	.increment(increment) ,  
	.voice_select(4'b0010), 
	.out (osc_out)
);

wire gate;
assign gate = ~btn[1];
assign led[0] = gate;
wire [BITDEPTH-1:0] mix;

ar #(.BITDEPTH(BITDEPTH)) myar (
	.sample_clock(sample_clock),
	.in(osc_out),
	.envelope_attack(8'h40),
	.envelope_decay(8'h10),
	.gate(gate),
	.out(mix)
);

dac #(.BITDEPTH(BITDEPTH)) mydac (
	.clk (clk),
	.sample_clock (sample_clock),
	.pcm (mix), // input to DAC
	.out (pwmout) // connect to PWM pin
);

endmodule

