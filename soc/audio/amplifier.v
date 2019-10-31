`timescale 1ns/1ns
module amplifier #(
	parameter BITDEPTH = 14,
	parameter VOLBITS  = 8
)(
	input [BITDEPTH-1:0] in,
	input [VOLBITS-1:0] volume,
	output [BITDEPTH-1:0] out
);

localparam OFFSET  = 2**(BITDEPTH -1); // idles at mid-volume

wire [BITDEPTH+VOLBITS-1:0] summer;
wire [BITDEPTH+VOLBITS-1:0] offset;

assign offset = (2**VOLBITS - volume)*OFFSET;
assign summer = in * volume + offset;
assign out = summer[BITDEPTH+VOLBITS-1 -: BITDEPTH] ;

endmodule

