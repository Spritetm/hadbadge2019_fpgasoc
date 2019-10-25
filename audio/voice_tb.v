`timescale 1ns/1ns
`include "sample_clock.v"
module test();

localparam BITDEPTH    = 14;
localparam BITFRACTION = 6;
localparam SAMPLECLOCK_DIV = 8;
localparam SAMPLEFREQ  = 8000000 / 2**SAMPLECLOCK_DIV;  // 31,250 Hz or 32 us

initial begin
	$dumpvars(0,test);
	$display("Go!");
	/* $monitor(); */
end
/* Clocks */
reg clk = 0;
reg rst = 0;
always 
	#62 clk = !clk; // 8 MHz = 125 ns. Awkward.

// import in sample clock module
wire sample_clock;
sample_clock #( .SAMPLECLOCK_DIV(SAMPLECLOCK_DIV) ) mysampleclock ( 
	.clk(clk), .sample_clock(sample_clock) 
);

reg gate = 0;
reg [3:0] voice = 4'b0010;
reg [15:0] pitch = 22345;
wire [BITDEPTH-1:0] out;
/* Wires, registers, and module here */

voice DUT (
	.sample_clock(sample_clock),
	.rst(rst),
	.voice_select(voice),
  	.pitch_increment(pitch),
  	.envelope_attack(8'hf0),
  	.envelope_decay(8'h10),
	.gate(gate),
	.out(out)
);


initial begin
	// full cycle, attack, sustain, release
	#10000000 gate = 1;
	#50000000 pitch=22345;
	#10000000 voice =4'b0001;
	#50000000 gate = 0;
	#50000000 voice = 4'b1000;
	#10000000 gate = 1;
	#50000000 gate = 0;
	#100000000 $finish;
end

endmodule // test
