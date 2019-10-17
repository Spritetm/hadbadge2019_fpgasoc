module top(input clk, output [5:0] led);
/* Not really audio yet.  Super quick test. */

reg [23:0] counter;

always@(posedge clk) begin
	counter <= counter + 1;
end

assign led[5:0] = counter[23:18];

endmodule
