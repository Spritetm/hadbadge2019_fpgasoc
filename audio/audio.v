`include "dac.v"
`include "button_number.v"

module top( 
	input clk, 
	input [7:0] btn, 
	output [5:0] led, 
	output [5:0] sao1,
	output pwmout
);
/* Button and audio workout */

dac mydac (
	.clk (clk),
	.pcm (mix),
	.out (pwmout)
);

/* 16 bit DAC, 12 bits tuning */
reg [28:0] accumulator ;  // plus sub-octave
reg [17:0] increment ;
reg [15:0] pulsewidth = 2**13; 
reg [15:0] mix; 
reg [23:0] lfo_counter;

wire [15:0] saw;
wire [15:0] pulse;
wire [15:0] triangle;
wire [15:0] suboctave;


wire [3:0] button;
button_number my_button_number(
	.clk (clk), 
	.btn (btn), 
	.button (button)
);


// [8779, 9301, 9854, 10440, 11060, 11718, 12415, 13153, 13935, 14764, 15642, 16572]
always @(posedge clk) begin
	case (button)
		0: begin increment <= 8779; end
		1: begin increment <= 9854; end
		2: begin increment <= 11060; end
		3: begin increment <= 11718; end
		4: begin increment <= 13153; end
		5: begin increment <= 14764; end
		6: begin increment <= 16572; end
		7: begin increment <= 8779*2; end
		default: begin increment <= 0; end
	endcase
end

/* Set up divider counter */
always @(posedge clk) begin 
	accumulator <= accumulator + increment;
	lfo_counter <= lfo_counter + 1;
	pulsewidth <=  2**13 + (lfo_counter[23] ? ~lfo_counter[22:10] : lfo_counter[22:10]) ;
end


// just the upper 16 bits
assign saw = accumulator[27:12]; 
assign pulse = ( accumulator[27:12] < pulsewidth ) ? 16'hffff : 16'h0000 ;
assign suboctave = {16{accumulator[28]}};
assign triangle = accumulator[27] ? ~accumulator[26:11] : accumulator[26:11];

assign mix = triangle / 8; 
assign led[3:0] = button;
endmodule

