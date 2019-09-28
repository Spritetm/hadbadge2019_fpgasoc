
`timescale 1 ns / 1 ps
module vid_tilemapmem (DataInA, DataInB, ByteEnA, ByteEnB, 
    AddressA, AddressB, ClockA, ClockB, ClockEnA, ClockEnB, WrA, WrB, 
    ResetA, ResetB, QA, QB)/* synthesis NGD_DRC_MASK=1 */;
    input wire [31:0] DataInA;
    input wire [31:0] DataInB;
    input wire [3:0] ByteEnA;
    input wire [3:0] ByteEnB;
    input wire [10:0] AddressA;
    input wire [10:0] AddressB;
    input wire ClockA;
    input wire ClockB;
    input wire ClockEnA;
    input wire ClockEnB;
    input wire WrA;
    input wire WrB;
    input wire ResetA;
    input wire ResetB;
    output reg [31:0] QA;
    output reg [31:0] QB;


	reg [31:0] mem[0:2048];

	always @(posedge ClockA) begin
		if (ResetA) begin
			QA <= 0;
		end else if (ClockEnA) begin
			QA <= mem[AddressA];
			if (WrA && ByteEnA[0]) mem[AddressA][7:0]<=DataInA[7:0];
			if (WrA && ByteEnA[1]) mem[AddressA][15:8]<=DataInA[15:8];
			if (WrA && ByteEnA[2]) mem[AddressA][23:16]<=DataInA[23:16];
			if (WrA && ByteEnA[3]) mem[AddressA][31:24]<=DataInA[31:24];
		end
	end

	always @(posedge ClockB) begin
		if (ResetB) begin
			QB <= 0;
		end else if (ClockEnB) begin
			QB <= mem[AddressB];
			if (WrB && ByteEnB[0]) mem[AddressB][7:0]<=DataInB[7:0];
			if (WrB && ByteEnB[1]) mem[AddressB][15:8]<=DataInB[15:8];
			if (WrB && ByteEnB[2]) mem[AddressB][23:16]<=DataInB[23:16];
			if (WrB && ByteEnB[3]) mem[AddressB][31:24]<=DataInB[31:24];
		end
	end

endmodule
