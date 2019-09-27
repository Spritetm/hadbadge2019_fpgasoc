module ram_dp_24x2048 (
	input wire ClockA,
	input wire ClockB,
	input wire ClockEnA,
	input wire ClockEnB,
	input wire ResetA,
	input wire ResetB,
	input wire [23:0] DataInA,
	input wire [23:0] DataInB,
	input wire [10:0] AddressA,
	input wire [10:0] AddressB,
	input wire WrA,
	input wire WrB,
	output reg [23:0] QA,
	output reg [23:0] QB
);

reg [23:0] mem[0:2047];


always @(posedge ClockA) begin
	if (ResetA) begin
		QA <= 0;
	end else begin
		QA <= mem[AddressA];
		if (WrA) begin
			mem[AddressA] <= DataInA;
		end
	end
end


always @(posedge ClockB) begin
	if (ResetB) begin
		QB <= 0;
	end else begin
		QB <= mem[AddressB];
		if (WrB) begin
			mem[AddressB] <= DataInB;
		end
	end
end

endmodule;
