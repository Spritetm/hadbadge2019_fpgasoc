`timescale 1ns/1ns
module oscillator 
#(
	parameter BITDEPTH   = 14,
	parameter BITFRACTION   = 8
) (
	input sample_clock,
	input rst,
	input [15:0] increment,  
	input [3:0] voice_select,
	output reg [BITDEPTH-1:0] out 

);
localparam TOPBIT     = BITDEPTH+BITFRACTION-1;
localparam PULSEWIDTH = 2**(BITDEPTH-4);
localparam MIDPOINT   = 2**(BITDEPTH-1)-1;


reg [TOPBIT:0] accumulator = 0 ;  
always @(posedge sample_clock) begin 
	if (rst) begin 
		accumulator <= 0 ;  
	end
	else begin
		accumulator <= accumulator + increment;
	end
end

reg [BITDEPTH-1:0] saw      = MIDPOINT;
reg [BITDEPTH-1:0] triangle = MIDPOINT;
reg [BITDEPTH-1:0] square   = 0;
reg [BITDEPTH-1:0] pulse    = MIDPOINT;


always @(posedge sample_clock) begin 
	saw <= accumulator[TOPBIT -: BITDEPTH] ; 
	triangle <= accumulator[TOPBIT] ? ~accumulator[TOPBIT-1 -: BITDEPTH] : accumulator[TOPBIT-1 -: BITDEPTH];

	pulse <= accumulator[TOPBIT -: BITDEPTH] < PULSEWIDTH ? 2**BITDEPTH-1 : 0 ;
end
always @(posedge accumulator[TOPBIT]) // suboctave square is so much cooler
	square <= ~square;

reg [1:0] gain;
reg [2:0] num_ones = 0;
// simple submixer
always @(posedge sample_clock) begin 
	num_ones = voice_select[0] + voice_select[1] + voice_select[2] + voice_select[3];
	case (num_ones) 	    
		1: out <= voice_select[0]*saw   + voice_select[1]*triangle   + voice_select[2] *square   + voice_select[3]*pulse;
		2: out <= voice_select[0]*saw/2 + voice_select[1]*triangle/2 + voice_select[2] *square/2 + voice_select[3]*pulse/2;
		3: out <= voice_select[0]*saw/4 + voice_select[1]*triangle/4 + voice_select[2] *square/4 + voice_select[3]*pulse/4 + MIDPOINT/2; // extra offset here?
		4: out <= voice_select[0]*saw/4 + voice_select[1]*triangle/4 + voice_select[2] *square/4 + voice_select[3]*pulse/4;
		default: out <= MIDPOINT; 
	endcase
end

endmodule

