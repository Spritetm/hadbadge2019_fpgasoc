
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
	assign write_data[7:0] = wen[0] ? wdata[7:0] : mem[addr][7:0];
	assign write_data[15:8] = wen[1] ? wdata[15:8] : mem[addr][15:8];
	assign write_data[23:16] = wen[2] ? wdata[23:16] : mem[addr][23:16];
	assign write_data[31:24] = wen[3] ? wdata[31:24] : mem[addr][31:24];
	
	integer i;
	initial begin
		if (INITIAL_HEX == "") begin
			for (i=0; i<WORDS; i=i+1) mem[i]='hdeadbeef;
		end else begin
			$readmemh("rom.hex", mem);
		end
	end

	always @(posedge clk) begin
		rdata <= mem[addr];
		if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
		if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
		if (wen[2]) mem[addr][23:16] <= wdata[23:16];
		if (wen[3]) mem[addr][31:24] <= wdata[31:24];
	end
endmodule

