`include "dac.v"
`include "button_number.v"
`include "oscillator.v"

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

wire [3:0] button;
button_number my_button_number(
	.clk (clk), 
	.btn (btn), 
	.button (button)
);

oscillator osc1(
	.clk (clk), 
	.increment (increment),
	.saw_vol (14),
	.pulse_vol (0),
	.triangle_vol (0),
	.suboctave_vol (12),
	.mix(submix1)
);

oscillator osc2(
	.clk (clk), 
	.increment (increment2),
	.saw_vol (0),
	.pulse_vol (0),
	.triangle_vol (14),
	.suboctave_vol (0),
	.mix(submix2)
);

wire [15:0] submix1;
wire [15:0] submix2;
wire [15:0] submix11;
wire [15:0] submix22;
wire [15:0] mix;


reg [18:0] increment ;  // determines pitch = f*2**28/maxclock
reg [18:0] increment2 ;  // determines pitch = f*2**28/maxclock
// note: check the max value here.  is this reasonable?

// [8779, 9301, 9854, 10440, 11060, 11718, 12415, 13153, 13935, 14764, 15642, 16572]
always @(posedge clk) begin
	// note: make sensitive to button?  why not? if routing trouble, clock
	// is fine
	case (button)
		0: begin increment <= 8779/2; end
		1: begin increment <= 9854/2; end
		2: begin increment <= 11060/2; end
		3: begin increment <= 11718/2; end
		4: begin increment <= 13153/2; end
		5: begin increment <= 14764/2; end
		6: begin increment <= 16572/2; end
		7: begin increment <= 8779*2/2; end
		default: begin increment <= 0; end
	endcase
	increment2 <= increment + increment/2; // fifth up
end

assign submix11 = submix1 / 2;
assign submix22 = submix2 / 2;
assign mix = submix11 + submix22;

assign led[3:0] = button;
endmodule

