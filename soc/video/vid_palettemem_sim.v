
`timescale 1 ns / 1 ps
module vid_palettemem (DataInA, DataInB, AddressA, AddressB, 
    ClockA, ClockB, ClockEnA, ClockEnB, WrA, WrB, ResetA, ResetB, QA, QB)/* synthesis NGD_DRC_MASK=1 */;
    input wire [31:0] DataInA;
    input wire [31:0] DataInB;
    input wire [8:0] AddressA;
    input wire [8:0] AddressB;
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

	reg [31:0] mem[0:511];

	always @(posedge ClockA) begin
		if (ResetA) begin
			QA <= 0;
		end else if (ClockEnA) begin
			QA <= mem[AddressA];
			if (WrA) mem[AddressA]<=DataInA;
		end
	end

	always @(posedge ClockB) begin
		if (ResetB) begin
			QB <= 0;
		end else if (ClockEnB) begin
			QB <= mem[AddressB];
			if (WrB) mem[AddressB]<=DataInB;
		end
	end

endmodule
