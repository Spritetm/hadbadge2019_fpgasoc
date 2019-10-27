`timescale 1ns/1ns
`include "sample_clock.v"
`include "scales_rom.v"

module test();
localparam SAMPLEFREQ = 8000000 / 2**8;
localparam BD=14;

initial begin
	$dumpvars(0,test);
	$display("Go!");
	// $monitor();
end
/* Clocks */
reg clk = 0;
always 
	#62.5 clk = !clk;

reg rst = 0;
reg sample_clock = 0;
reg [7:0] sample_count = 0;
always @(posedge clk) begin
	sample_count <= sample_count + 1;
	sample_clock <= sample_count[7];
end

reg [6:0] note;
wire [15:0] pitch_increment;
midi_note_to_accumulator m (
	.clk(sample_clock),
	.reset(rst),
	.midi_note(note),
	.increment(pitch_increment)
);


/* Wires, registers, and module here */
wire [BD-1:0] saw;
wire [BD-1:0] triangle;
wire [BD-1:0] pulse;
wire [BD-1:0] sub;
oscillator #( .BITDEPTH(BD), .BITFRACTION(6), .VOICE(0)) testsaw (
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(pitch_increment), 
	.out(saw)
);

oscillator #( .BITDEPTH(BD), .BITFRACTION(6), .VOICE(1)) testtri (
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(pitch_increment), 
	.out(triangle)
);
oscillator #( .BITDEPTH(BD), .BITFRACTION(6), .VOICE(2)) testpulse (
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(pitch_increment), 
	.out(pulse)
);
oscillator #( .BITDEPTH(BD), .BITFRACTION(6), .VOICE(3)) testsub (
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(pitch_increment), 
	.out(sub)
);

initial begin
	rst=1;
	note = 60;
	#100000 rst=0;
	#30000000 $finish;

end

endmodule // test
