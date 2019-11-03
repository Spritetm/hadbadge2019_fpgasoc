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

reg sample_clock       = 0;
reg [SAMPLECLOCK_DIV-1:0] sample_count = 0;
/* reg [31:0] mydata; */
reg ready_n;
integer i;


// Control lines
reg voice_gate [7:0];
wire [BITDEPTH-1:0] voice_out [7:0];
reg [6:0] voice_note [7:0];
reg [7:0] voice_attack [7:0];
reg [7:0] voice_release [7:0];

always @(posedge clk) begin
        if (rst) begin
                sample_clock <= 0;
                sample_count <= 0;
		/* slow_counter <= 0; */
		ready_n <= 0;
		for (i=0; i<8; i=i+1) begin
			voice_gate[i]   <= 0; // all off
			voice_note[i]    <= 7'd60; // middle c
			voice_attack[i]  <= 8'hf0; // snappy
			voice_release[i] <= 8'hf0; // snappy
		end

        end
        else begin
                sample_count <= sample_count + 1;
                sample_clock <= sample_count[SAMPLECLOCK_DIV-1];
		if (wen) begin
			voice_gate[addr] <= data_in[0];
			voice_note[addr] <= 7'd60 + addr;
			/* mydata <= data_in; */
			ready_n <= 1; // handled data
		end
        end
end
assign ready = ready_n && wen ; // speedup, drops line as soon as wen falls

// Handle incoming data
/* always (mydata) begin */
/*     case (addr) */
/* 	    4'h0: */ 
/* 	    4'h1: */
/* 	    4'h2: */
/* 	    4'h3: */
/* 	    4'h4: */
/* 	    4'h5: */
/* 	    4'h6: */
/* 	    4'h7: */
/* 	    4'h8: */
/* 	    4'hC: */
/* 	    4'hD: */
/* 	    default: #0; // this is an error */
/*     endcase */
/*     end */

// Begin synthesizer
genvar synth_num;
// Sawtooths
generate
	for (synth_num=0 ; synth_num < 2; synth_num=synth_num+1) begin 
		voice #(.VOICE(0)) osc (
			.sample_clock(sample_clock),
			.rst(rst),
			.note(voice_note[synth_num]),
			.envelope_attack(voice_attack[synth_num]),
			.envelope_decay(voice_release[synth_num]),
			.gate(voice_gate[synth_num]),
			.out(voice_out[synth_num])
		);
	end
endgenerate
// Pulses
generate
	for (synth_num=2 ; synth_num < 4; synth_num=synth_num+1) begin 
		voice #(.VOICE(3)) osc (
			.sample_clock(sample_clock),
			.rst(rst),
			.note(voice_note[synth_num]),
			.envelope_attack(voice_attack[synth_num]),
			.envelope_decay(voice_release[synth_num]),
			.gate(voice_gate[synth_num]),
			.out(voice_out[synth_num])
		);
	end
endgenerate
// Triangles
generate
	for (synth_num=4 ; synth_num < 8; synth_num=synth_num+1) begin 
		voice #(.VOICE(1)) osc (
			.sample_clock(sample_clock),
			.rst(rst),
			.note(voice_note[synth_num]),
			.envelope_attack(voice_attack[synth_num]),
			.envelope_decay(voice_release[synth_num]),
			.gate(voice_gate[synth_num]),
			.out(voice_out[synth_num])
		);
	end
endgenerate

// Mixers: two 4-way mixers for the two voice groups
// Note the horrible off-by one!
wire [BITDEPTH-1:0] mix1;
mixer4 mixer (
	.in1(voice_out[0]),
	.in2(voice_out[1]),
	.in3(voice_out[2]),
	.in4(voice_out[3]),
	.mix(mix1)
);

wire [BITDEPTH-1:0] mix2;
mixer4 othermixer (
	.in1(voice_out[4]),
	.in2(voice_out[5]),
	.in3(voice_out[6]),
	.in4(voice_out[7]),
	.mix(mix2)
);

// Then mix them together
wire [BITDEPTH-1:0] bigmix;
assign bigmix = (mix1 >> 1) + (mix2 >> 1);

// And out.
dac #(.BITDEPTH(BITDEPTH)) mydac (
	.clk (clk),
	.rst(rst),
	.pcm (bigmix), // input to DAC
	.out (pwmout) // connect to PWM pin
);

endmodule

