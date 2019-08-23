`timescale 1us/1ns

module stimulus();

reg clk, rst;
wire [15:0] gpio_out;
wire wen, ren;

pic_wrapper picw(
	.clk(clk),
	.reset(rst),
	.gpio_in(16'hAA55),
	.gpio_out(gpio_out),
	.address(16'b0),
	.data_in(32'b0),
	.wen(1'b0),
	.ren(1'b0)
	//.data_out(),
	//.ready()
);

//clock toggle
always #0.5 clk = !clk;

integer i;
initial begin
	$dumpfile("pic_testbench.vcd");
	$dumpvars(0, stimulus);
	clk <= 0;
	rst <= 1;
	#2 rst <= 0;

	#5000000 $finish;
end



endmodule