`timescale 1ns/1ns
module test();
/* localparam SAMPLEFREQ = 8000000 / 2**8; */
/* localparam BD=12; */

initial begin
	$dumpvars(0,test);
	$display("Go!");
	$monitor(midi, out);
end
/* Clocks */
reg clk = 0;
reg rst = 0;
always 
	#62.5 clk = !clk; // 8 MHz = 125 ns. Awkward.


/* Wires, registers, and module here */

reg [6:0] midi;
wire [15:0] out;

midi_note_to_accumulator DUT(
	.clk(clk),
	.reset(rst),
	.midi_note(midi),
	.increment(out)
);



initial begin
	#1000 midi=0;
	#1000 midi=60;
	#1000 midi=69 ;
	#1000 midi=127 ;
	#1000 $finish;
	
end

endmodule // test
