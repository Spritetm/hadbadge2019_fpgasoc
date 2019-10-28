/* ripoff of the SID RNG */
// https://github.com/gundy/tiny-synth/tree/develop/hdl

module lfsr (
	input clk,
	input rst,
	output wire [7:0] dout
);

reg [22:0] lfsr = 23'b01101110010010000101011;

always @(posedge clk) begin
	if (rst) begin
		lfsr <= 23'b01101110010010000101011;
	end
	else begin
		lfsr <= lfsr == 0 ? 23'b01101110010010000101011 : { lfsr[21:0], lfsr[22] ^ lfsr[17] };
	end
end

assign dout = { lfsr[22], lfsr[20], lfsr[16], lfsr[13], lfsr[11], lfsr[7], lfsr[4], lfsr[2] };

endmodule

