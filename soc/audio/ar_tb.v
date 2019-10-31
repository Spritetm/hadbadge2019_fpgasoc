`timescale 1ns/1ns
/* `include "sample_clock.v" */
/* `include "oscillator.v" */

module test();
localparam BITDEPTH    = 14;
localparam BITFRACTION = 6;
localparam SAMPLECLOCK_DIV = 8;
localparam SAMPLEFREQ  = 8000000 / 2**SAMPLECLOCK_DIV;  // 31,250 Hz or 32 us

initial begin
	$dumpvars(0,test);
	$display("Go!");
	/* $monitor(); */
end
/* Clocks */
reg clk = 0;
reg rst = 0;
always 
	#62 clk = !clk; // 8 MHz = 125 ns. Awkward.

// import in sample clock module
wire sample_clock;
sample_clock #( .SAMPLECLOCK_DIV(SAMPLECLOCK_DIV) ) mysampleclock ( 
	.clk(clk), .sample_clock(sample_clock) 
);

// import oscillator for sound source
`define CALC_INCREMENT(hz) $rtoi(hz * 2**(BITDEPTH+BITFRACTION)/SAMPLEFREQ*2)
reg [15:0] increment = `CALC_INCREMENT(262) ; 

wire [BITDEPTH-1:0] osc_out;
oscillator #( .BITDEPTH(BITDEPTH), .BITFRACTION(BITFRACTION)) mysaw 
(
	.sample_clock(sample_clock),
	.rst(rst),
	.increment(increment) ,  
	.voice_select(4'b0010), 
	.out (osc_out)
);

/* Wires, registers, and module here */
reg gate=0;
wire [BITDEPTH-1:0] out;

ar #(
) myar (
	.sample_clock(sample_clock),
	.rst(rst),
	.in(osc_out),
	.envelope_attack(8'hf0),
	.envelope_decay(8'h30),
	.gate(gate),
	.out(out)
);


initial begin

	#10000000 gate = 1;
	#20000000 gate = 0;
	#50000000 $finish;
end

endmodule // test
