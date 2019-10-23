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
	// $monitor();
end
/* Clocks */
reg clk = 0;
always 
	#62 clk = !clk; // 8 MHz = 125 ns. Awkward.


wire sample_clock;
sample_clock #( .SAMPLECLOCK_DIV(SAMPLECLOCK_DIV) ) mysampleclock ( 
	.clk(clk), .sample_clock(sample_clock) 
);


/* Wires, registers, and module here */
reg gate = 0;
reg [7:0] a = 220;
reg [7:0] r = 60;
wire [7:0] volume;

envelope myenv
(
	.sample_clock(sample_clock),
	.gate(gate),
	.a(a),
	.r(r),
	.volume(volume)
);

initial begin
	// full cycle, attack, sustain, release
	#10000 gate = 1;
	#30000000 gate = 0;
	// attack, interrupted by gate 
	#50000000 a=100; gate = 1;
	#10000000 gate = 0;
	// 

	#100000000 $finish;


end

endmodule // test
