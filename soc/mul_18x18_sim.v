module mul_18x18(
//	input clock, reset,
	input [17:0] a,
	input [17:0] b,
	output [35:0] dout
);

	assign dout = $signed(a)*$signed(b);

endmodule