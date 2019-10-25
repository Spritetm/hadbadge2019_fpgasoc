`timescale 1ns/1ns
module test();
localparam SAMPLEFREQ = 8000000 / 2**8;
localparam BD=12;

reg [15:0] increment;
wire [BD-1:0] out;
reg [3:0] voice_select;
initial begin
	$dumpvars(0,test);
	$display("Go!");
	// $monitor();
end
/* Clocks */
reg clk = 0;
always 
	#125 clk = !clk;

reg sample_clock = 0;
reg rst = 0;
reg [8:0] sample_count = 0;
always @(posedge clk) begin
	sample_count <= sample_count + 1;
	sample_clock <= sample_count[7];
end

/* Wires, registers, and module here */
oscillator #( .BITDEPTH(12), .BITFRACTION(12)) testsaw (
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(increment), 
.voice_select(voice_select),
	.out(out)
);

initial begin
	increment = 0;
	voice_select = 1;
	#1000000 increment = 2**4;
	#3000000 increment = 2**13;
	#3500000 voice_select=2;
	#20000000 $finish;


end

endmodule // test
