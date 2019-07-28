
module TRELLIS_IO #(
	parameter DIR = "BIDIR"
) (
	input I,
	input T,
	inout B,
	output O
);

assign B = T ? 'hZ : I;
assign O = T ? I : B;

endmodule