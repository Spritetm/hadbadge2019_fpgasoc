// License and description
// Reg: one for each instrument.  Maybe 12?  Let's say up to 16.
// Currently thinking that PCM should be out on its own.  Still will need to
// interface with mixer peripheral, though.
// 1 bit Config Flag, 7 tuning bits, 8 attack, 8 decay, 7 note, 1 bit gate.
// If config flag is not set, ignores tuning, attack, decay bits.  
// Allows 8-bit state?

module synth_interface(
	//CPU interface
	input clk,
	input rst,
	input [3:0] addr, // 16 instruments?  should be enough.
	input [31:0] data_in,
	input wen,
	input ren,
	output ready,
	// Audio/mixer i/o
	output pwmout
);

localparam BITDEPTH    = 14;
localparam BITFRACTION = 6;
localparam SAMPLECLOCK_DIV = 8;
localparam SAMPLEFREQ  = 8000000 / 2**SAMPLECLOCK_DIV;  // 31,250 Hz or 32 us

reg gate1;
reg sample_clock       = 0;
reg [SAMPLECLOCK_DIV-1:0] sample_count = 0;
/* reg [31:0] mydata; */
reg ready_n;

always @(posedge clk) begin
        if (rst) begin
                sample_clock <= 0;
                sample_count <= 0;
		/* slow_counter <= 0; */
		gate1 <= 0;
		ready_n <= 0;
        end
        else begin
                sample_count <= sample_count + 1;
                sample_clock <= sample_count[SAMPLECLOCK_DIV-1];
		if (wen) begin
			gate1 <= data_in[0];
			/* mydata <= data_in; */
			ready_n <= 1; // handled data
		end
        end
end
assign ready = ready_n && wen ; // speedup, drops line as soon as wen falls

/* reg [18:0] slow_counter; */
/* always @(posedge sample_clock) begin */
/* 	if (!rst) begin */
/* 	slow_counter <= slow_counter + 1; */
/* end */
/* end */

wire [BITDEPTH-1:0] osc1_out;
voice #(.VOICE(0)) osc1 (
	.sample_clock(sample_clock),
	.rst(rst),
	.note(60),
	.envelope_attack(8'hf0),
	.envelope_decay(8'h40),
	.gate(gate1),
	.out(osc1_out)
);

dac #(.BITDEPTH(BITDEPTH)) mydac (
	.clk (clk),
	.rst(rst),
	/* .sample_clock (sample_clock), */
	.pcm (osc1_out), // input to DAC
	.out (pwmout) // connect to PWM pin
);

endmodule

