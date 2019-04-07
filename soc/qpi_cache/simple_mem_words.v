
module simple_mem_words #(
	parameter integer WORDS = 256,
	parameter INITIAL_HEX = ""
) (
	input clk,
	input [3:0] wen,
	input [$clog2(WORDS)-1:0] addr,
	input [31:0] wdata,
	output reg [31:0] rdata
);
	reg [31:0] mem [0:WORDS-1];
	wire [31:0] write_data;
	assign write_data[0:7] = wen[0] ? wdata[0:7] : mem[addr][0:7];
	assign write_data[8:15] = wen[1] ? wdata[8:15] : mem[addr][8:15];
	assign write_data[16:23] = wen[2] ? wdata[16:23] : mem[addr][16:23];
	assign write_data[24:31] = wen[3] ? wdata[24:31] : mem[addr][24:31];
	
	integer i;
	initial begin
		for (i=0; i<WORDS; i=i+1) mem[i]='hdeadbeef;
		if (INITIAL_HEX != "") $readmemh("rom.hex", mem);
	end

	always @(posedge clk) begin
		rdata <= mem[addr];
		if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
		if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
		if (wen[2]) mem[addr][23:16] <= wdata[23:16];
		if (wen[3]) mem[addr][31:24] <= wdata[31:24];
	end
endmodule

