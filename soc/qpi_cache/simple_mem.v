//note: output is registered
module simple_mem #(
	parameter integer WORDS = 256,
	parameter integer WIDTH = 8,
	parameter [WORDS-1:0] INITIAL_FILL = 0,
	parameter INIT_FILE = ""
) (
	input clk,
	input wen,
	input [$clog2(WORDS)-1:0] addr,
	input [WIDTH-1:0] wdata,
	output reg [WIDTH-1:0] rdata
);
	reg [WIDTH:0] mem [0:WORDS-1];
	
	integer i;
	initial begin
		if (INIT_FILE == "") begin
			for (i=0; i<WORDS; i++) mem[i]=INITIAL_FILL;
		end else begin
			$readmemh(INIT_FILE, mem);
		end
	end

	always @(posedge clk) begin
		rdata <= mem[addr];
		if (wen) mem[addr] <= wdata;
	end
endmodule

