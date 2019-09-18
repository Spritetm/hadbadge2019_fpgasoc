module ledctl (
	input clk,
	input rst,
	input [8:0] led,
	output reg [10:0] ledc,
	output reg [2:0] leda
);

reg [21:0] ctr;


always @(posedge clk) begin
	if (rst) begin
		ctr <= 0;
		leda <= 0;
		ledc <= 0;
	end else begin
		ledc <= (ctr[5:4]==0)?11'hFFF:0;
		ctr <= ctr + 1;
		if (ctr == 0) begin
			if (leda==1) begin
				leda <= 2;
			end else if (leda==2) begin
				leda <= 4;
			end else begin
				leda <= 1;
			end
		end
	end
end

endmodule