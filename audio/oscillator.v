`timescale 100ns/10ns
module oscillator 
#(
	parameter BITDEPTH   = 12,
	parameter BITFRACTION   = 8
) (
	input sample_clock,
	input [18:0] increment ,  
	output [BITDEPTH-1:0] out 
);
localparam TOPBIT = BITDEPTH+BITFRACTION-1;
// DDS


reg [TOPBIT:0] accumulator = 0 ;  
/* Set up divider counter */
always @(posedge sample_clock) begin 
	accumulator <= accumulator + increment;
end

assign out = accumulator[TOPBIT -: BITDEPTH] ; 
endmodule

