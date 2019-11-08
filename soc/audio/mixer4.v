module mixer4 #(
	parameter BITDEPTH = 14
)(
	input [BITDEPTH-1:0] in1,
	input [BITDEPTH-1:0] in2,
	input [BITDEPTH-1:0] in3,
	input [BITDEPTH-1:0] in4,
	output [BITDEPTH-1:0] mix

);

localparam OFFSET  = 2**(BITDEPTH -1); // idles at mid-volume

wire [BITDEPTH+2-1:0] summer; 
assign summer = in1 + in2 + in3 + in4;
assign mix = summer[BITDEPTH+2-1 -: BITDEPTH] ;

endmodule

