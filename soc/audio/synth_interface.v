// License and description
// Reg: one for each instrument.  Maybe 12?  Let's say up to 16.
// Currently thinking that PCM should be out on its own.  Still will need to
// interface with mixer peripheral, though.
// 1 bit Config Flag, 7 tuning bits, 8 attack, 8 decay, 7 note, 1 bit gate.
// If config flag is not set, ignores tuning, attack, decay bits.  
// Allows 8-bit state?

module synth_interface(
	/* CPU interface */
	input clk,
	input rst,
	input [7:0] addr, 
	/* 16 sets of 4x 32-bit registers */
	input [31:0] data_in,
	input wen,
	input ren,
	output ready,
	/* Audio/mixer i/o */
	output pwmout
);

localparam BITDEPTH    = 14;
localparam BITFRACTION = 6;
localparam SAMPLECLOCK_DIV = 10;
localparam SAMPLEFREQ  = 48000000 / 2**SAMPLECLOCK_DIV;  // 46,875 Hz
localparam INCREMENTBITS = 16;
localparam ARBITS = 8;
localparam NUMVOICES = 8;

reg sample_clock;
reg slow_clock; // approx milliseconds
reg [15:0] slow_counter;
reg [16:0] counter;
reg [31:0] mydata;
reg ready_n;
reg newdata;
integer i;

// Control lines
reg voice_gate [NUMVOICES-1:0];
wire [BITDEPTH-1:0] voice_out [NUMVOICES-1:0];
reg [INCREMENTBITS-1:0] voice_increment [NUMVOICES-1:0];
reg [ARBITS-1:0] voice_attack [NUMVOICES-1:0];
reg [ARBITS-1:0] voice_release [NUMVOICES-1:0];
reg [15:0] voice_off_time [NUMVOICES-1:0];
reg [15:0] master_volume;
/* reg [16:0] filter_cutoff; */

reg [15:0] pcm;

always @(posedge clk) begin
	if (rst) begin
		mydata        <= 0;
		ready_n       <= 0;
		counter       <= 0;
		sample_clock  <= 0;
		slow_clock    <= 0;
		slow_counter  <= 0;
		pcm           <= 0;
		master_volume <= 'h0080;
		/* filter_cutoff <= 'hFFFF; */

		for (i=0; i<8; i=i+1) begin
			voice_gate[i]      <= 0; // all off
			voice_increment[i] <= 'hC00; // 137 Hz
			voice_attack[i]    <= 'hf0; // snappy
			voice_release[i]   <= 'hf0; // snappy
			voice_off_time[i]  <= 0; // all off
		end
	end
	else begin
		// Update counters
		counter <= counter[15:0] + 1;
		sample_clock <= counter[SAMPLECLOCK_DIV-1];
		slow_clock <= counter[15];
		slow_counter <= slow_counter + counter[16];
		// Bus handling, read data into mydata
		if (wen) begin
			mydata  <= data_in;
			ready_n <= 1; // signal handled data to memory bus -- but shortened below in combo
			newdata <= 1; // signal new data to handle internally
		end
		else begin
			ready_n <= 0; // reset.
		end
		// If have data, act on it. 
		if (newdata) begin
			newdata <= 0;
		case (addr[3:0])	
			'h0: begin
				if (addr[7:4] < 'h8) begin
					/* $display("Synth voice play data register."); */
					voice_increment[addr[7:4]] <= mydata[15:0];
					if (mydata[31:16]) begin
						voice_gate[addr[7:4]] <= 1;
						voice_off_time[addr[7:4]] <= slow_counter + mydata[31:16];
					end 
				end 
				else if (addr[7:4] == 'hC ) begin 
					pcm[15:0] <= mydata[15:0];
				end
				else if (addr[7:4] == 'hD ) begin 
					/* $display("Drum play register."); */
				end
				else if (addr[7:4] == 'hF ) begin 
					master_volume <= mydata[15:0];
				end
				else begin
					/* $display("Not a valid 0 register."); */
				end
			end
			'h4: begin
				if (addr[7:4] < 'h8) begin
					/* $display("Synth voice A/R register."); */
					voice_attack[addr[7:4]]  <= mydata[7:0];
					voice_release[addr[7:4]] <= mydata[15:8];
				end 
				else begin
					/* $display("Not a valid config register."); */
				end
			end
			'h8: begin
				/* $display("2 register not implemented yet."); */
			end
			'hC: begin
				/* $display("3 register not implemented yet."); */
			end
			default: begin 
				/* $display("Fallen between the cracks."); */
			end
		endcase
		end
		// Check for gates expiring
			for (i=0; i<8; i=i+1) begin
				if ( (voice_gate[i] == 1) && (voice_off_time[i] == slow_counter) ) begin
					voice_gate[i] <= 0;
				end
			end

	end // end not reset
end  // end always @(posedge clk)

// speedup, drops line as soon as wen falls (also ren if writing data out)
assign ready = ready_n && wen ; 

// Begin synthesizer
genvar synth_num;
// Sawtooths
generate
	for (synth_num=0 ; synth_num < 2; synth_num=synth_num+1) begin 
		voice #(.VOICE(0)) myvoice (
			.sample_clock(sample_clock),
			.rst(rst),
			.pitch_increment(voice_increment[synth_num]),
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
			.pitch_increment(voice_increment[synth_num]),
			.envelope_attack(voice_attack[synth_num]),
			.envelope_decay(voice_release[synth_num]),
			.gate(voice_gate[synth_num]),
			.out(voice_out[synth_num])
		);
	end
endgenerate
// Square
//
// Triangles
generate
	for (synth_num=4 ; synth_num < 8; synth_num=synth_num+1) begin 
		voice #(.VOICE(1)) myvoice (
			.sample_clock(sample_clock),
			.rst(rst),
			.pitch_increment(voice_increment[synth_num]),
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
/* wire [BITDEPTH-1:0] mixdrums; */
/* mixer4 drummixer ( */
/*        .in1(), */
/*        .in2(), */
/*        .in3(), */
/*        .in4(), */
/*        .mix(mixdrums) */
/* ); */


// Multiply up to a max level of 24 bits, then take the top 14
wire [23:0] summer;
assign summer = (mix1 + mix2 + pcm) * master_volume ;
wire [BITDEPTH-1:0] to_dac;
assign to_dac = summer[23:10];

// And out.
dac #(.BITDEPTH(BITDEPTH)) mydac (
	.clk (clk),
	.rst(rst),
	.pcm (to_dac), // input to DAC
	.out (pwmout) // connect to PWM pin
);

endmodule

