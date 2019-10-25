`timescale 1ns/1ns
`include "sample_clock.v"
`include "oscillator.v"
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
wire [15:0] increment = 16'd12345;
sample_clock #( .SAMPLECLOCK_DIV(SAMPLECLOCK_DIV) ) mysampleclock ( 
	.clk(clk), .sample_clock(sample_clock) 
);


wire [BITDEPTH-1:0] osc1_out;
oscillator mytri1
(
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(increment) ,  
	.voice_select(4'b0001), 
	.out (osc1_out)
);

wire [BITDEPTH-1:0] osc2_out;
oscillator mytri2
(
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(increment) ,  
	.voice_select(4'b0010), 
	.out (osc2_out)
);

wire [BITDEPTH-1:0] osc3_out;
oscillator mytri3
(
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(increment) ,  
	.voice_select(4'b0010), 
	.out (osc3_out)
);

wire [BITDEPTH-1:0] osc4_out;
oscillator mytri4
(
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(increment) ,  
	.voice_select(4'b1100), 
	.out (osc4_out)
);


/* Wires, registers, and module here */
wire [BITDEPTH-1:0] mix;

mixer4 mymixer (
	.in1(osc1_out),
	.in2(osc2_out),
	.in3(osc3_out),
	.in4(osc4_out),
	.mix(mix)
);


initial begin
	// full cycle, attack, sustain, release

	#100000000 $finish;


end

endmodule // test
