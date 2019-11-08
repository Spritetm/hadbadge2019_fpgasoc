`timescale 1ns/1ns
module oscillator 
#(
	parameter BITDEPTH   = 14,
	parameter BITFRACTION   = 6,
	parameter [1:0] VOICE = 0
) (
	input sample_clock,
	input rst,
	input [15:0] increment,  
	output reg [BITDEPTH-1:0] out 

);
localparam TOPBIT     = BITDEPTH+BITFRACTION-1;
localparam PULSEWIDTH = 2**(BITDEPTH-3);
localparam MIDPOINT   = 2**(BITDEPTH-1)-1;
localparam PULSELO    = MIDPOINT - 2**(BITDEPTH-4); 
localparam PULSEHI    = MIDPOINT + 2**(BITDEPTH-4); 

localparam SAW   = 2'd0;
localparam TRI   = 2'd1;
localparam PULSE = 2'd2;
localparam SUB   = 2'd3;

reg [TOPBIT+1:0] accumulator;  
reg sub;
always @(posedge sample_clock,  posedge rst) begin 
	if (rst) begin 
		accumulator <= 0 ;  
		out <= MIDPOINT;
		sub <= 0;
	end
	else begin
		accumulator <= accumulator[TOPBIT:0] + increment;
		case (VOICE)
			SAW: out <= accumulator[TOPBIT -: BITDEPTH] ; 
			TRI: out <= accumulator[TOPBIT] ? ~accumulator[TOPBIT-1 -: BITDEPTH] : accumulator[TOPBIT-1 -: BITDEPTH];
			PULSE: out <= accumulator[TOPBIT -: BITDEPTH] < PULSEWIDTH ? 2**BITDEPTH-1 : 0 ;
			SUB: out <= (((accumulator[TOPBIT -: BITDEPTH] < PULSEHI) && (accumulator[TOPBIT -: BITDEPTH] > PULSELO) ) ?  2**BITDEPTH-1 : 0)/2 + sub << (BITDEPTH-1); 
			default: out <= MIDPOINT;
		endcase 
		sub <= accumulator[TOPBIT+1] ? ~sub : sub ;
	end
end

endmodule

