
module OFS1P3DX (
	input D,
	input SP,
	input SCLK,
	input CD,
	output reg Q);

always @(posedge SCLK, posedge CD) begin
	if (CD) begin
		Q<=0;
	end else if (SP) begin
		Q<=D;
	end
end

endmodule


module IFS1P3DX (
	input D,
	input SP,
	input SCLK,
	input CD,
	output reg Q);

always @(posedge SCLK, posedge CD) begin
	if (CD) begin
		Q<=0;
	end else if (SP) begin
		Q<=D;
	end
end

endmodule
