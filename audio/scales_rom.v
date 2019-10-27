module midi_note_to_accumulator (
	input clk,
	input reset,
	input [6:0] midi_note,
	output [15:0] increment
);

reg [15:0] lut[0:127];

initial begin
	$readmemh("scales.hex", lut);
end

reg [6:0] note_latch;
assign increment = lut[note_latch];

always @(posedge clk) begin
	if (reset) begin
		note_latch <= 0;
	end else begin
		note_latch <= midi_note;
	end
end

endmodule

