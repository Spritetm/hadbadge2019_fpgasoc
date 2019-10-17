module top( 
	input clk, 
	input [7:0] btn, 
	output [5:0] led, 
	output pwmout, 
	output [5:0] sao1 
);
/* Button and audio workout */


reg [23:0] counter;
reg audio;
reg [15:0] overflow;
wire [3:0] button;

button_number button_number_1(
	.clk (clk), 
	.btn (btn), 
	.button (button)
);


// Chromatic divisors of 8 MHz, starting with C3
// 15289, 14431, 13621, 12856, 12135, 11454, 10811, 10204, 9631, 9091, 8581, 8099

always @(posedge clk) begin 
	counter <= counter + 1;
	case(button)
		0: overflow <= 15289;
		1: overflow <= 13621;
		2: overflow <= 12135;
		3: overflow <= 11454;
		4: overflow <= 10204;
		5: overflow <= 9091;
		6: overflow <= 8099;
		7: overflow <= 15289/2;
		default: overflow <= 0;
	endcase

	if (counter > overflow)
		counter <= 0;
	audio <= counter[12];
end

assign led[6:0] = overflow[6:0];
assign pwmout = audio;

endmodule
