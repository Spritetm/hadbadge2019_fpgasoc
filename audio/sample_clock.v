`timescale 1ns/1ns
module sample_clock #(
	parameter SAMPLECLOCK_DIV=8
)(
	input clk,
	output sample_clock
);

reg sample_clock       = 0;
reg [SAMPLECLOCK_DIV-1:0] sample_count = 0;
always @(posedge clk) begin
	sample_count <= sample_count + 1;
	sample_clock <= sample_count[SAMPLECLOCK_DIV-1];
end

endmodule
