/*
 * synth_core.v
 *
 * vim: ts=4 sw=4
 *
 * Audio synthesizer
 *
 * Copyright (C) 2019  Elliot Williams <elliot@pre.postero.us>
 * Copyright (C) 2019  Sylvain Munaut <tnt@246tNt.com>
 * All rights reserved.
 *
 * BSD 3-clause, see LICENSE.bsd
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

`default_nettype none

module synth_core #(
	parameter integer DIV_WIDTH  = 11,
	parameter integer PHASE_INT  = 14,
	parameter integer PHASE_FRAC =  5,
	parameter integer PHASE_INC  = 16
)(
	// Output
	output wire [15:0] audio_out_l,
	output wire [15:0] audio_out_r,
	output wire [11:0] audio_out_dc,

	// WaveTable lookup
	output wire [11:0] wt_addr,
	input  wire [ 7:0] wt_data,

	// Config bus for voice settings
	input  wire [31:0] cb_data,
	input  wire [ 3:0] cb_voice,
	input  wire [ 2:0] cb_reg,
	input  wire cb_stb_v,			// Per-voice setting
	input  wire cb_stb_g,			// Global settings

	// Config read-back for global regs
	input  wire [ 2:0] crb_reg,
	output reg  [31:0] crb_data,

	// Status output
	output reg stb_sample,			// 1 every sample
	output reg stb_tick_fast,		// 1 every 16 samples
	output reg stb_tick_slow,		// 1 every 256 samples

	output reg [4:0] active_voices,	// 0-16

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	localparam PHASE_WIDTH = PHASE_INT + PHASE_FRAC;


	// Signals
	// -------

	// Global config
	reg [DIV_WIDTH-1:0] cfg_div;
	reg [ 7:0] cfg_vol;
	reg [15:0] cfg_voice_force;
	reg [15:0] cfg_voice_start;

	// Voice config registers
	wire [ 8:0] cr_ctrl_1;
	reg  [ 8:0] cr_ctrl_2;
	wire [PHASE_INC-1:0] cr_phase_inc_1;
	wire [PHASE_INT-1:0] cr_phase_cmp_1;
	wire [ 7:0] cr_volume_l_2;
	wire [ 7:0] cr_volume_r_2;
	wire [10:0] cr_duration_1;
	wire [ 7:0] cr_attack_d_1;
	wire [ 7:0] cr_attack_k_1;
	wire [ 7:0] cr_decay_d_1;
	wire [ 7:0] cr_decay_k_1;

	// Misc
	wire [15:0] rng;
	reg  rst_local_1;

	// Sequencer
	reg [DIV_WIDTH:0] div_cnt;

	reg active_0, active_1, active_2;
	reg [3:0] ctx_0, ctx_1, ctx_2;
	reg ctx_first_0, ctx_first_1;
	reg ctx_last_0, ctx_last_1, ctx_last_2;

	reg  [4:0] fast_cnt_1;
	wire fast_tick_1;
	reg  [8:0] slow_cnt_1;
	wire slow_tick_1;

	// Oscillator
	wire [PHASE_WIDTH:0] phase_acc_1;
	reg  [PHASE_WIDTH:0] phase_acc_2;

	// Gating
	reg  [15:0] gate_start_1;
	reg  [15:0] gate_force_1;
	wire gate_1;

	wire [11:0] dur_cnt_1;
	reg  [11:0] dur_cnt_2;

	// Envelope
	localparam
		ES_OFF = 0,
		ES_ATTACK = 1,
		ES_SUSTAIN = 2,
		ES_DECAY = 3;

	wire [1:0] env_state_1;
	reg  [1:0] env_state_2;

	wire [7:0] env_vol_1;
	wire [7:0] env_vol_2;
	wire env_vol_min_1;
	wire env_vol_max_1;

	wire [7:0] env_tick_1;
	reg  [7:0] env_tick_2;
	wire env_tick_rst_1;
	reg  env_tick_now_2;

	// Wave table address gen
	wire [11:0] wt_addr_base;
	wire [11:0] wt_addr_offset;
	wire [11:0] wt_addr_os1;
	wire [11:0] wt_addr_os2;

	// Oscillator output function
	wire [PHASE_INT:0] oo_cmp_diff;
	wire oo_cmp;

	reg  [PHASE_INT-1:0] oo_out_direct_2;
	wire [PHASE_INT-1:0] oo_out_wt_2;
	reg  [PHASE_INT-1:0] oo_out_3;

	// Status
	reg  [4:0] active_voices_cnt;


	// Configuration register
	// ----------------------

	// Globals
	always @(posedge clk)
		if (rst)
			cfg_div <= 998;
		else if (cb_stb_g && (cb_reg == 3'h0))
			cfg_div <= cb_data[DIV_WIDTH-1:0];

	always @(posedge clk)
		if (rst)
			cfg_vol <= 8'hc0;
		else if (cb_stb_g && (cb_reg == 3'h1))
			cfg_vol <= cb_data[7:0];

	always @(posedge clk)
		if (rst)
			cfg_voice_force <= 16'h0000;
		else if (cb_stb_g && (cb_reg == 3'h2))
			cfg_voice_force <= cb_data[15:0];

	always @(posedge clk)
		if (rst)
			cfg_voice_start <= 16'h0000;
		else
			cfg_voice_start <=
				((cb_stb_g && (cb_reg == 3'h3)) ? cb_data[15:0] : 16'h0000) |
				(ctx_first_0 ? 16'h0000 : cfg_voice_start);

	always @(*)
		case (crb_reg)
			3'h0:    crb_data = { {(32-DIV_WIDTH){1'b0}}, cfg_div };
			3'h1:    crb_data = { 24'h000000, cfg_vol };
			3'h2:    crb_data = { 16'h0000, cfg_voice_force };
			3'h3:    crb_data = { 16'h0000, cfg_voice_start };
			default: crb_data = 32'hxxxxxxxx;
		endcase

	// Per-voice
	synth_cfg_reg #(
		.ADDR(0),
		.WIDTH(9)
	) cr_ctrl_I (
		.ctx_0(ctx_0),
		.out_1(cr_ctrl_1),
		.cb_data(cb_data),
		.cb_voice(cb_voice),
		.cb_reg(cb_reg),
		.cb_stb(cb_stb_v),
		.clk(clk)
	);

	always @(posedge clk)
		cr_ctrl_2 <= cr_ctrl_1;

	synth_cfg_reg #(
		.ADDR(2),
		.WIDTH(PHASE_INC)
	) cr_phase_inc_I (
		.ctx_0(ctx_0),
		.out_1(cr_phase_inc_1),
		.cb_data(cb_data),
		.cb_voice(cb_voice),
		.cb_reg(cb_reg),
		.cb_stb(cb_stb_v),
		.clk(clk)
	);

	synth_cfg_reg #(
		.ADDR(3),
		.WIDTH(PHASE_INT)
	) cr_phase_cmp_I (
		.ctx_0(ctx_0),
		.out_1(cr_phase_cmp_1),
		.cb_data(cb_data),
		.cb_voice(cb_voice),
		.cb_reg(cb_reg),
		.cb_stb(cb_stb_v),
		.clk(clk)
	);

	synth_cfg_reg #(
		.ADDR(4),
		.WIDTH(16)
	) cr_volume_I (
		.ctx_0(ctx_1),
		.out_1({cr_volume_l_2, cr_volume_r_2}),
		.cb_data(cb_data),
		.cb_voice(cb_voice),
		.cb_reg(cb_reg),
		.cb_stb(cb_stb_v),
		.clk(clk)
	);

	synth_cfg_reg #(
		.ADDR(5),
		.WIDTH(11)
	) cr_duration_I (
		.ctx_0(ctx_0),
		.out_1(cr_duration_1),
		.cb_data(cb_data),
		.cb_voice(cb_voice),
		.cb_reg(cb_reg),
		.cb_stb(cb_stb_v),
		.clk(clk)
	);

	synth_cfg_reg #(
		.ADDR(6),
		.WIDTH(16)
	) cr_envelope_attack_I (
		.ctx_0(ctx_0),
		.out_1({cr_attack_d_1, cr_attack_k_1}),
		.cb_data(cb_data),
		.cb_voice(cb_voice),
		.cb_reg(cb_reg),
		.cb_stb(cb_stb_v),
		.clk(clk)
	);

	synth_cfg_reg #(
		.ADDR(7),
		.WIDTH(16)
	) cr_envelope_decay_I (
		.ctx_0(ctx_0),
		.out_1({cr_decay_d_1, cr_decay_k_1}),
		.cb_data(cb_data),
		.cb_voice(cb_voice),
		.cb_reg(cb_reg),
		.cb_stb(cb_stb_v),
		.clk(clk)
	);


	// Misc
	// ----

	// RNG
	synth_rng rng_I (
		.out(rng),
		.clk(clk),
		.rst(rst)
	);

	// Local state reset
	always @(posedge clk)
		if (rst)
			rst_local_1 <= 1'b1;
		else if (ctx_last_1)
			rst_local_1 <= 1'b0;


	// Sequencer
	// ---------

	// Divider
	always @(posedge clk)
		if (rst)
			div_cnt <= 0;
		else
			div_cnt <= div_cnt[DIV_WIDTH] ? { 1'b0, cfg_div } : (div_cnt - 1);

	// Context & Active
	always @(posedge clk)
		if (rst) begin
			ctx_0       <= 4'h0;
			ctx_first_0 <= 1'b0;
			ctx_last_0  <= 1'b0;
			active_0    <= 1'b0;
		end else begin
			ctx_0       <= ctx_0 + active_0;
			ctx_first_0 <= div_cnt[DIV_WIDTH];
			ctx_last_0  <= ctx_0 == 4'he;
			active_0    <= (active_0 | div_cnt[DIV_WIDTH]) & ~ctx_last_0;
		end

	// Delay for write back
	always @(posedge clk)
		if (rst) begin
			{ ctx_2,      ctx_1      } <= 2'b00;
			{ active_2,   active_1   } <= 2'b00;
			{ ctx_last_2, ctx_last_1 } <= 2'b00;
			ctx_first_1 <= 1'b0;
		end else begin
			{ ctx_2,      ctx_1      } <= { ctx_1,      ctx_0      };
			{ active_2,   active_1   } <= { active_1,   active_0   };
			{ ctx_last_2, ctx_last_1 } <= { ctx_last_1, ctx_last_0 };
			ctx_first_1 <= ctx_first_0;
		end

	// 1/16th sub divider to generate a fast strobe
	always @(posedge clk)
		if (rst)
			fast_cnt_1 <= 5'h00;
		else if (ctx_first_0)
			fast_cnt_1 <= fast_tick_1 ? 5'h0e : (fast_cnt_1 - 1);

	assign fast_tick_1 = fast_cnt_1[4];

	// 1/256th sub divider to generate a slow strobe
	always @(posedge clk)
		if (rst)
			slow_cnt_1 <= 9'h000;
		else if (ctx_first_0)
			slow_cnt_1 <= slow_tick_1 ? 9'h0fe : (slow_cnt_1 - 1);

	assign slow_tick_1 = slow_cnt_1[8];


	// Oscillator
	// ----------

	// Phase accumulator register
	synth_reg #(
		.WIDTH(PHASE_WIDTH+1)
	) phase_acc_reg_I (
		.rd_data_1(phase_acc_1),
		.rd_ctx_0(ctx_0),
		.wr_data(phase_acc_2),
		.wr_ctx(ctx_2),
		.wr_ena(active_2),
		.clk(clk)
	);

	// Update
	always @(posedge clk)
		if (rst_local_1 | cr_ctrl_1[1])
			phase_acc_2 <= 0;
		else
			phase_acc_2 <= phase_acc_1 + cr_phase_inc_1;


	// Gating
	// ------

	// Shift registers
	always @(posedge clk)
	begin
		gate_start_1 <= ctx_first_0 ? cfg_voice_start : { 1'b0, gate_start_1[15:1] };
		gate_force_1 <= ctx_first_0 ? cfg_voice_force : { 1'b0, gate_force_1[15:1] };
	end

	// Duration counter
	synth_reg #(
		.WIDTH(12)
	) dur_cnt_reg_I (
		.rd_data_1(dur_cnt_1),
		.rd_ctx_0(ctx_0),
		.wr_data(dur_cnt_2),
		.wr_ctx(ctx_2),
		.wr_ena(active_2),
		.clk(clk)
	);

	always @(posedge clk)
		if (rst_local_1)
			dur_cnt_2 <= 12'h000;
		else
			dur_cnt_2 <= gate_start_1[0] ?
				{ 1'b1, cr_duration_1 } :
				(dur_cnt_1 - ((dur_cnt_1[11] & slow_tick_1) ? 1 : 0));

	// Final decision
	assign gate_1 = cr_ctrl_1[0] & (gate_force_1[0] | dur_cnt_1[11]);


	// Envelope
	// --------

	// Registers
	synth_reg #(
		.WIDTH(2)
	) env_state_reg_I (
		.rd_data_1(env_state_1),
		.rd_ctx_0(ctx_0),
		.wr_data(env_state_2),
		.wr_ctx(ctx_2),
		.wr_ena(active_2),
		.clk(clk)
	);

	synth_reg #(
		.WIDTH(8)
	) env_tick_reg_I (
		.rd_data_1(env_tick_1),
		.rd_ctx_0(ctx_0),
		.wr_data(env_tick_2),
		.wr_ctx(ctx_2),
		.wr_ena(active_2),
		.clk(clk)
	);

	synth_reg #(
		.WIDTH(8)
	) env_vol_reg_I (
		.rd_data_1(env_vol_1),
		.rd_ctx_0(ctx_0),
		.wr_data(env_vol_2),
		.wr_ctx(ctx_2),
		.wr_ena(active_2 & env_tick_now_2),
		.clk(clk)
	);

	// Volume status
	assign env_vol_min_1 = (env_vol_1 == 8'h00);
	assign env_vol_max_1 = (env_vol_1 == 8'hff);

	// State update
	always @(posedge clk)
	begin
		if (rst_local_1) begin
			env_state_2 <= ES_OFF;
		end else begin
			// Default
			env_state_2 <= env_state_1;

			// Select next state
			case (env_state_1)
				ES_OFF:
					if (gate_1)
						env_state_2 <= ES_ATTACK;

				ES_ATTACK:
					if (!gate_1)
						env_state_2 <= ES_DECAY;
					else if (env_vol_max_1)
						env_state_2 <= ES_SUSTAIN;

				ES_SUSTAIN:
					if (!gate_1)
						env_state_2 <= ES_DECAY;

				ES_DECAY:
					if (gate_1)
						env_state_2 <= ES_ATTACK;
					else if (env_vol_min_1)
						env_state_2 <= ES_OFF;

				default: env_state_2 <= ES_OFF;
			endcase
		end
	end

	// Envelope 'tick' counter
	assign env_tick_rst_1 = env_tick_1[7] | (env_state_1 == ES_OFF) | (env_state_1 == ES_SUSTAIN);

	always @(posedge clk)
		if (env_tick_rst_1) begin
			if (env_state_1 == ES_DECAY)
				env_tick_2 <= cr_decay_d_1;
			else if (env_state_1 == ES_ATTACK)
				env_tick_2 <= cr_attack_d_1;
			else
				env_tick_2 <= 8'h00;
		end else
			env_tick_2 <= env_tick_1 - (fast_tick_1 ? 1 : 0);

		// We 'tick' all the time in 'OFF' because the attack/delay block will
		// tend to bring volume to 0 so it's fine and performs a 'reset'
	always @(posedge clk)
		if (rst_local_1)
			env_tick_now_2 <= 1'b1;
		else
			env_tick_now_2 <= active_1 & (
				(env_state_1 == ES_OFF) |
				((env_state_1 != ES_SUSTAIN) & env_tick_1[7])
			);

	// Volume update
	synth_attack_decay #(
		.WIDTH(8)
	) env_rd_I (
		.vol_in_0(env_vol_1),
		.k_attack_0(cr_attack_k_1),
		.k_decay_0(cr_decay_k_1),
		.mode_0(env_state_1 != ES_ATTACK),
		.vol_out_1(env_vol_2),
		.rng(rng),
		.clk(clk),
		.rst(rst_local_1)
	);


	// Oscillator output function
	// --------------------------

	// Compare phase to reference point
	assign oo_cmp_diff = { 1'b0, cr_phase_cmp_1 } - { 1'b0, phase_acc_1[PHASE_WIDTH-1:PHASE_FRAC] };
	assign oo_cmp = oo_cmp_diff[PHASE_INT];

	// Select direct output
	always @(posedge clk)
	begin
		case (cr_ctrl_1[3:2])
			// Sawtooth
			2'b00: oo_out_direct_2 <= phase_acc_1[PHASE_WIDTH-1:PHASE_FRAC] ;

			// Triangle
			2'b01: oo_out_direct_2 <= phase_acc_1[PHASE_WIDTH-2:PHASE_FRAC-1] ^ {PHASE_INT{phase_acc_1[PHASE_WIDTH-1]}};

			// Pulse
			2'b10: oo_out_direct_2 <= {PHASE_INT{oo_cmp}};

			// Sub-harmonic
			2'b11: oo_out_direct_2 <= {phase_acc_1[PHASE_WIDTH], {(PHASE_INT-1){oo_cmp}}};
		endcase
	end

	// Execute Wavetable lookup
	assign wt_addr_base   = { cr_ctrl_1[6:4], 9'h000 };
	assign wt_addr_offset = phase_acc_1[PHASE_WIDTH-1:PHASE_WIDTH-12] ^ ((cr_ctrl_1[8] & phase_acc_1[PHASE_WIDTH]) ? 12'hfff : 12'h000);
	assign wt_addr_os1    = cr_ctrl_1[3] ? { 2'b00, wt_addr_offset[11:2] } : wt_addr_offset;
	assign wt_addr_os2    = cr_ctrl_1[2] ? {  1'b0, wt_addr_os1[11:1]    } : wt_addr_os1;
	assign wt_addr        = wt_addr_base + wt_addr_os2;

	assign oo_out_wt_2 = { wt_data, 1'b1, {(PHASE_INT-9){1'b0}} };

	// Final selection (and convert to signed)
	always @(posedge clk)
		oo_out_3 <= (cr_ctrl_2[7] ? oo_out_wt_2 : oo_out_direct_2) ^ {1'b1, {(PHASE_INT-1){1'b0}}};


	// Amplifier and mixer
	// -------------------

	synth_mix #(
		.IN_WIDTH(PHASE_INT)
	) mix_I (
		.vol_global_1(cfg_vol),
		.vol_envelope_1(env_vol_1),
		.vol_voice_l_2(cr_volume_l_2),
		.vol_voice_r_2(cr_volume_r_2),
		.first_0(ctx_first_0),
		.last_0(ctx_last_0),
		.in_data_3(oo_out_3),
		.out_l(audio_out_l),
		.out_r(audio_out_r),
		.out_dc(audio_out_dc),
		.clk(clk),
		.rst(rst)
	);


	// External status reporting
	// -------------------------

	// Strobes
	always @(posedge clk)
		if (rst) begin
			stb_sample    <= 1'b0;
			stb_tick_fast <= 1'b0;
			stb_tick_slow <= 1'b0;
		end else begin
			stb_sample    <= active_1 & ctx_last_1;
			stb_tick_fast <= active_1 & ctx_last_1 & fast_tick_1;
			stb_tick_slow <= active_1 & ctx_last_1 & slow_tick_1;
		end

	// Active voices
	always @(posedge clk)
		active_voices_cnt <= (ctx_first_1 ? 5'h00 : active_voices_cnt) + (env_state_1 != ES_OFF ? 1 : 0);

	always @(posedge clk)
		if (ctx_last_2)
			active_voices <= active_voices_cnt;

endmodule // synth_core
