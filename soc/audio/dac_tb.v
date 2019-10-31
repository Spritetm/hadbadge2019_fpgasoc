`timescale 1ns/1ns
module test();
localparam SAMPLEFREQ = 8000000 / 2**8;
localparam BD=14;

reg [BD-1:0] pcm;
wire out;

initial begin
	$dumpvars(0,test);
	$display("Go!");
	// $monitor();
end
initial #80000 $finish;

/* Clocks */
reg clk = 0;
reg rst = 0;
always 
	#62.5 clk = !clk;

/* Wires, registers, and module here */
dac #(.BITDEPTH(BD)) dut (
	.clk(clk),
	.rst(rst),
	.pcm(pcm),
	.out(out)
);

initial begin
	pcm = 0;
	rst=1;
	#1000 rst=0;
	#10000 pcm = 2**7;
	#20000 pcm = 2**(BD-1)-1;
	#30000 pcm = 2**BD - 1;
end



endmodule // test
