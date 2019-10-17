/* Quick and dirty 16-bit sigma-delta converter */
module dac (
	input clk,
	input [15:0] pcm,
	output out
);


reg [16:0] accumulator;
always @(posedge clk) begin
	accumulator <= accumulator[15:0] + pcm;
end
assign out = accumulator[16];

endmodule

