`timescale 100ns/10ns
module test();
localparam SAMPLEFREQ = 8000000 / 2**8;
localparam BD=12;

reg [18:0] increment;
wire [BD-1:0] out;

initial begin
	$dumpvars(0,test);
	$display("Go!");
	// $monitor();
end
/* Clocks */
reg clk = 0;
always 
	#1 clk = !clk;

reg sample_clock = 0;
reg [8:0] sample_count = 0;
always @(posedge clk) begin
	sample_count <= sample_count + 1;
	sample_clock <= sample_count[7];
end

/* Wires, registers, and module here */
oscillator #( .BITDEPTH(12), .BITFRACTION(12)) testsaw (
	.sample_clock(sample_clock),
	.increment(increment), 
	.out(out)
);

initial begin
	increment = 0;
	#100000 increment = 2**4;
	#300000 increment = 2**13;
	#2000000 $finish;


end

endmodule // test
