module mul_18x18(
	input clock, reset,
	input [17:0] a,
	input [17:0] b,
	output reg [35:0] dout
);

	always @posedge(clock) begin
		dout <= $signed(a)*$signed(b);
	end

endmodule