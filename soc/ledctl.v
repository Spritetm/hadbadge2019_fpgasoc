module ledctl (
	input clk,
	input rst,
	input [8:0] led,
	output reg [10:0] ledc,
	output reg [2:0] leda
);

reg [10:0] ctr;


always @(posedge clk) begin
	if (rst) begin
		ctr <= 0;
		leda <= 0;
		ledc <= 0;
	end else begin
		ctr <= ctr + 1;
		if (ctr == 0) begin
			leda <= 'b001;
			ledc <= { 2'b11, (led & 9'b100010101)};
		end else if (ctr == 85) begin
			leda <= 'b010;
			ledc <= { 2'b00, (led & 9'b000101010)};
		end else if (ctr == 170) begin
			leda <= 'b100;
			ledc <= { 2'b00, (led & 9'b011000000)};
		end
	end
end

endmodule