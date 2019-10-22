`timescale 1ns/1ns
module amplifier #(
	parameter BITDEPTH = 14,
	parameter VOLBITS  = 8
)(
	input clk,
	input [BITDEPTH-1:0] unsigned_audio,
	input [VOLBITS-1:0] volume,
	output wire signed [BITDEPTH-1:0] unsigned_out
);

wire signed [VOLBITS:0] signed_volume;
assign signed_volume = {1'b0, volume[VOLBITS-1:0]};
reg signed [BITDEPTH+VOLBITS-1:0] signed_scaled_audio;

always @(posedge clk) begin
	signed_scaled_audio <= (unsigned_audio * signed_volume);
end

assign unsigned_out = signed_scaled_audio[BITDEPTH+VOLBITS-1 -: BITDEPTH] ;

endmodule

