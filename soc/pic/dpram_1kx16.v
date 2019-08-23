module dpram_1kx16 #(
		parameter INIT_FILE = ""
   ) (
	input clk,
	input rst,
	
	input [9:0] addr_a,
	input [15:0] wdata_a,
	output reg [15:0] rdata_a,
	input wen_a,
	
	input [9:0] addr_b,
	input [15:0] wdata_b,
	output reg [15:0] rdata_b,
	input wen_b
);

reg [15:0] mem [0:1023];

integer i;
initial begin
	if (INIT_FILE == "") begin
		for (i=0; i<1024; i=i+1) mem[i]='h0;
	end else begin
		$readmemh(INIT_FILE, mem);
	end
end


always @(posedge clk) begin
	if (rst) begin
		rdata_a <= 0;
		rdata_b <= 0;
	end else begin
		if (wen_a) mem[addr_a] <= wdata_a;
		if (wen_b) mem[addr_b] <= wdata_b;
		rdata_a <= mem[addr_a];
		rdata_b <= mem[addr_b];
	end
end

endmodule
