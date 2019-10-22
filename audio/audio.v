`include "dac.v"
`include "button_number.v"
`include "oscillator.v"
`include "lfsr.v"

module top( 
	input clk, 
	input [7:0] btn, 
	output [5:0] led, 
	output [5:0] sao1,
	output pwmout
);
/* Button and audio workout */

localparam BITDEPTH    = 14;
localparam BITFRACTION = 6;
localparam SAMPLEFREQ  = 8000000 / 2**8;

reg sample_clock       = 0;
reg [8:0] sample_count = 0;
always @(posedge clk) begin
	sample_count <= sample_count + 1;
	sample_clock <= sample_count[8];
end

wire [BITDEPTH-1:0] mix;
dac #(.BITDEPTH(BITDEPTH)) mydac (
	.clk (clk),
	.sample_clock (sample_clock),
	.pcm (mix), // input to DAC
	.out (pwmout) // connect to PWM pin
);

`define CALC_INCREMENT(hz) $rtoi(hz * 2**(BITDEPTH+BITFRACTION)/SAMPLEFREQ*2)
 wire [3:0] button; 
 button_number my_button_number( 
 	.clk (clk), 
 	.btn (btn),  
 	.button (button) 
 ); 
//frequencies = [261.6256, 293.6648, 329.6276, 349.2282, 391.9954, 440.0000, 493.8833]
 always @(posedge clk) begin 
 	case (button) 
 		0: begin increment <= `CALC_INCREMENT(261.6256); end 
 		1: begin increment <= `CALC_INCREMENT(293.6648); end 
 		2: begin increment <= `CALC_INCREMENT(329.6276); end 
 		3: begin increment <= `CALC_INCREMENT(349.2282); end 
 		4: begin increment <= `CALC_INCREMENT(391.9954); end 
 		5: begin increment <= `CALC_INCREMENT(440.0000); end 
 		6: begin increment <= `CALC_INCREMENT(493.8833); end 
 		7: begin increment <= `CALC_INCREMENT(261.6256*2); end 
 		default: begin increment <= 0; end 
 	endcase 
 end 


 assign led[3:0] = button; 


reg [20:0] increment = 0 ;  // determines pitch = 
oscillator #( .BITDEPTH(BITDEPTH), .BITFRACTION(BITFRACTION)) mysaw 
(
	.sample_clock(sample_clock),
	.increment(`CALC_INCREMENT(261.6256)) ,  
	.voice_select(button+1),
	.out (mix)
);

endmodule

