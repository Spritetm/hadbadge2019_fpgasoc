`timescale 1ns/1ns
module test();
localparam SAMPLEFREQ = 8000000 / 2**8;
localparam BD=12;

reg [BD-1:0] pcm;
wire out;

initial begin
	$dumpvars(0,test);
	$display("Go!");
	// $monitor();
end
initial #40000 $finish;

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
dac #(.BITDEPTH(BD)) dut (
	.clk(clk),
	.sample_clock(sample_clock),
	.pcm(pcm),
	.out(out)
);

initial begin
	pcm = 0;
	#10000 pcm = 2**6;
	#20000 pcm = 2**8;
	#30000 pcm = 2**BD - 1;
end



endmodule // test
