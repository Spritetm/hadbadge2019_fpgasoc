module top( input clk, input [7:0] btn, output [5:0] led, output pwmout, output [5:0] sao1 );
/* Button and audio workout */

reg [23:0] counter;
reg audio;

// Chromatic divisors of 8 MHz, starting with C3
// 15289, 14431, 13621, 12856, 12135, 11454, 10811, 10204, 9631, 9091, 8581, 8099

always@(posedge clk) begin 

	if (btn[0] == 0) begin
		counter <= counter + 1;
		if (counter > 15289) begin
			counter <= 0;
		end
	end
	else if (btn[1] == 0) begin
		counter <= counter + 1;
		if (counter > 13621) begin
			counter <= 0;
		end
	end
	else if (btn[2] == 0) begin
		counter <= counter + 1;
		if (counter > 12135) begin
			counter <= 0;
		end
	end
	else if (btn[3] == 0) begin
		counter <= counter + 1;
		if (counter > 11454) begin
			counter <= 0;
		end
	end
	else if (btn[4] == 0) begin
		counter <= counter + 1;
		if (counter > 10204) begin
			counter <= 0;
		end
	end
	else if (btn[5] == 0) begin
		counter <= counter + 1;
		if (counter > 9091) begin
			counter <= 0;
		end
	end
	else if (btn[6] == 0) begin
		counter <= counter + 1;
		if (counter > 8099) begin
			counter <= 0;
		end
	end
	else if (btn[7] == 0) begin
		counter <= counter + 1;
		if (counter > 15289/2) begin
			counter <= 0;
		end
	end
	audio <= counter[12];
end

assign pwmout = audio;
assign led[5:0] = ~btn[5:0];

endmodule
