`timescale 1ns/1ns
/* `include "sample_clock.v" */
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
	#62.5 clk = !clk; // 8 MHz = 125 ns. Awkward.

reg sample_clock = 0;
reg [7:0] sample_count = 0;
always @(posedge clk) begin
	sample_count <= sample_count + 1;
	sample_clock <= sample_count[7];
end

reg [6:0] midi;
reg gate;
wire [BITDEPTH-1:0] out;
/* Wires, registers, and module here */
voice #(.VOICE(0)) DUT (
	.sample_clock(sample_clock),
	.rst(rst),
  	.note(midi),
  	.envelope_attack(8'hf0),
  	.envelope_decay(8'h80),
	.gate(gate),
	.out(out)
);

initial begin
	// full cycle, attack, sustain, release
	rst=1;
	gate=0;
	midi = 60;
	#300000 rst=0;
	#10000000 gate = 1;
	#50000000 
	gate = 0;
	#10000000 
	midi=68 ;
	gate = 1;
	#50000000 gate = 0;
	#50000000 $finish;
end

endmodule // test
