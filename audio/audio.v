module top(input clk, input [7:0] btn, output [5:0] led, output pwmout);
/* Button and audio workout */

reg [23:0] counter;
reg audio;

always@(posedge clk) begin
	counter <= counter + 1;
	if (btn[0] == 0)
		audio = counter[9];
	if (btn[1] == 0)
		audio = counter[10];
	if (btn[2] == 0)
		audio = counter[11];
	if (btn[3] == 0)
		audio = counter[12];
	if (btn[4] == 0)
		audio = counter[13];
	if (btn[5] == 0)
		audio = counter[14];
	if (btn[6] == 0)
		audio = counter[15];
	if (btn[7] == 0)
		audio = counter[16];
end

assign pwmout = audio;
assign led[5:0] = ~btn[5:0];

endmodule
