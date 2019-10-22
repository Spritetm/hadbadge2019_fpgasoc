`timescale 100ns/10ns
module oscillator 
#(
	parameter BITDEPTH   = 12,
	parameter BITFRACTION   = 8
) (
	input sample_clock,
	input [20:0] increment,  
	input [3:0] voice_select,
	output [BITDEPTH-1:0] out 

);
localparam TOPBIT = BITDEPTH+BITFRACTION-1;
localparam PULSEWIDTH = 2**(BITDEPTH-4);

reg [TOPBIT:0] accumulator = 0 ;  
always @(posedge sample_clock) begin 
	accumulator <= accumulator + increment;
end

wire [BITDEPTH-1:0] saw;
wire [BITDEPTH-1:0] triangle;
wire [BITDEPTH-1:0] square; 
wire [BITDEPTH-1:0] pulse;


always @(posedge sample_clock) begin 
	saw <= accumulator[TOPBIT -: BITDEPTH] ; 
	triangle <= accumulator[TOPBIT] ? ~accumulator[TOPBIT-1 -: BITDEPTH] : accumulator[TOPBIT-1 -: BITDEPTH];
	square <= accumulator[TOPBIT] ? 2**BITDEPTH-1 : 0 ;
	pulse <= accumulator[TOPBIT -: BITDEPTH] < PULSEWIDTH ? 2**BITDEPTH-1 : 0 ;
end

reg [1:0] gain;
reg [2:0] num_ones = voice_select[0] + voice_select[1] + voice_select[2] + voice_select[3];
// simple submixer
always @(posedge sample_clock) begin 
	case (num_ones) 	    
		1: out <= voice_select[0]*saw   + voice_select[1]*triangle   + voice_select[2] *square   + voice_select[3]*pulse;
		2: out <= voice_select[0]*saw/2 + voice_select[1]*triangle/2 + voice_select[2] *square/2 + voice_select[3]*pulse/2;
		3: out <= voice_select[0]*saw/4 + voice_select[1]*triangle/4 + voice_select[2] *square/4 + voice_select[3]*pulse/4;
		4: out <= voice_select[0]*saw/4 + voice_select[1]*triangle/4 + voice_select[2] *square/4 + voice_select[3]*pulse/4;
		default: out <= 2**(BITDEPTH-1)-1; // center
	endcase
end

endmodule

