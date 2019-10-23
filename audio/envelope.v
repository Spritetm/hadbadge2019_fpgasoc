`timescale 1ns/1ns
module envelope #(
	parameter SAMPLE_CLK_FREQ = 31250 // but I don't scale this yet.
)
(
	input sample_clock,
	input gate,
	input [7:0] a,
	input [7:0] r,
	output reg [7:0] volume = 0
);

// state machine that advances volume while key pressed
localparam WAIT    = 2'd0;
localparam ATTACK  = 2'd1;
localparam SUSTAIN = 2'd2;
localparam RELEASE = 2'd3;

reg[1:0] state;

initial begin
	state = WAIT;
	volume = 0;
end

reg [9:0] attack_counter = 0;
reg [8:0] attack_exponential = 0;

reg [10:0] release_counter = 0; // 2x slower counter
reg [8:0] release_exponential = 0;

// state machine
always @(posedge sample_clock)
begin
	case (state)
		WAIT:  begin
			if (gate) 
				state <= ATTACK; attack_counter <= 0; 
		end
		ATTACK: begin
			attack_counter <= attack_counter[8:0] + a;
			if (attack_counter[9]) 	begin
				attack_exponential <= ((255-volume)>>6) > 0 ? (255-volume)>>6 : 1;
				volume <= (volume < 255-attack_exponential) ? (volume + attack_exponential) : 255 ;  
			end
				/* volume <= volume < 255 ? volume + 1 : 255; */
			if (volume == 255) 
				state <= SUSTAIN;
			if (!gate) begin 
				state <= RELEASE; 
				release_counter <= 0; 
			end
		end
		SUSTAIN: begin
			if (!gate) begin 
				state <= RELEASE; 
				release_counter <= 0; 
			end
		end
		RELEASE: begin
			release_counter <= release_counter[9:0] + r;
			if (release_counter[10]) begin				
				release_exponential <= (volume>>5) > 0 ? volume>>5 : 1;
				volume <= (volume > release_exponential) ? (volume - release_exponential) : 0 ;  
			end
			if (volume == 0) 
				state <= WAIT; 
			if (gate) begin 
				state <= ATTACK; 
				attack_counter <= 0; 
			end
		end
	endcase
end // state machine loop

endmodule
