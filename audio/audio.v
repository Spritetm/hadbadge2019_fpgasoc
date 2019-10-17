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

reg [23:0] counter;
reg [23:0] freq ;
reg [15:0] mix; 

wire [3:0] button;

button_number my_button_number(
	.clk (clk), 
	.btn (btn), 
	.button (button)
);

/* Set up divider counter */
always @(posedge clk) begin 
	counter <= counter + 1;
	case (button)
		0: begin freq <= 30578; end
		1: begin freq <= 27242; end
		2: begin freq <= 24270; end
		3: begin freq <= 22908; end
		4: begin freq <= 20408; end
		5: begin freq <= 18182; end
		6: begin freq <= 16198; end
		7: begin freq <= 30578/2; end
		default: begin freq <= 30578; end
	endcase

	if (counter > freq) begin // this value controls the frequency
		counter <= 0;
	end
end

// [30578.0, 28862.0, 27242.0, 25713.0, 24270.0, 22908.0, 21622.0, 20408.0, 19263.0, 18182.0, 17161.0, 16198.0]

assign mix = counter;
assign led[3:0] = button;
endmodule

