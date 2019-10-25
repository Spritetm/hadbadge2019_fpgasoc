`include "dac.v"
`include "button_number.v"
`include "oscillator.v"
`include "lfsr.v"
`include "amplifier.v"
`include "envelope.v"

module top( 
	input clk, 
	input rst,
	input [7:0] btn, 
	output [5:0] led, 
	output [5:0] sao1,
	output pwmout
);
/* Button and audio workout */

localparam BITDEPTH    = 14;
localparam BITFRACTION = 6;
localparam SAMPLEFREQ  = 8000000 / 2**8;  // 31,250 Hz or 32 us

reg sample_clock       = 0;
reg [7:0] sample_count = 0;
always @(posedge clk) begin
	sample_count <= sample_count + 1;
	sample_clock <= sample_count[7];
end

/* reg ms_clock = 0; */
/* reg [4:0] ms_count = 0; */
/* always @(posedge clk) begin */
/* 	ms_count <= ms_count + 1; */
/* 	ms_clock <= ms_count[4]; */
/* end */



wire [BITDEPTH-1:0] mix;
dac #(.BITDEPTH(BITDEPTH)) mydac (
	.clk (clk),
	.rst(rst),
	.sample_clock (sample_clock),
	.pcm (mix), // input to DAC
	.out (pwmout) // connect to PWM pin
);

`define CALC_INCREMENT(hz) $rtoi(hz * 2**(BITDEPTH+BITFRACTION)/SAMPLEFREQ*2)
wire [3:0] button; 
button_number my_button_number( 
	.clk (clk), 
	.rst(rst),
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


wire [BITDEPTH-1:0] preamp;
reg [15:0] increment = 0 ;  // determines pitch = 
oscillator #( .BITDEPTH(BITDEPTH), .BITFRACTION(BITFRACTION)) mysaw 
(
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(increment) ,  
	.voice_select(button[3:0]),
	.out (preamp)
);

wire gate;
assign gate = ~(button == 15);
wire [7:0] volume;

envelope myenv
(
	.clk(clk),
	.rst(rst),
	.gate(~btn[1]),
	.a(220),
	.r(60),
	.volume(volume)
);

amplifier #( .BITDEPTH(BITDEPTH), .VOLBITS(8) ) myamp
(
	.clk(clk),
	.rst(rst),
	.unsigned_audio(preamp),
	.volume(volume),
	.unsigned_out(mix)
);

endmodule

