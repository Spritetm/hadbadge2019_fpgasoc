/* Quick and dirty sigma-delta converter */
`timescale 1ns/1ns

module dac #(parameter BITDEPTH=14) (
	input clk,
	input rst,
	/* input sample_clock, */
	input [BITDEPTH-1:0] pcm,
	output out
);



// buffer when comes in
reg [BITDEPTH-1:0] sample;
always @(pcm) begin
	if (!rst) begin
		sample = pcm;
	end
	else begin
		sample = 'h0;
	end
end

reg [BITDEPTH:0] accumulator;
always @(posedge clk) begin
	if (rst) begin
		accumulator <= 'h0;
	end
	else begin
		accumulator <= accumulator[BITDEPTH-1:0] + sample;
	end
end

assign out = accumulator[BITDEPTH];

endmodule

