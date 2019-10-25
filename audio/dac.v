/* Quick and dirty sigma-delta converter */
`timescale 1ns/1ns
module dac #(parameter BITDEPTH=12) (
	input clk,
	input rst,
	input sample_clock,
	input [BITDEPTH-1:0] pcm,
	output out
);


reg [BITDEPTH:0] accumulator;
reg [BITDEPTH:0] sample;

// buffer at sample clock

always @(posedge sample_clock) begin
	sample <= pcm;
end

always @(posedge clk) begin
	if (rst) begin
		accumulator <= 0;
		sample <= 0;
	end
	else begin
		accumulator <= accumulator[BITDEPTH-1:0] + sample;
	end
end

assign out = accumulator[BITDEPTH];

endmodule

