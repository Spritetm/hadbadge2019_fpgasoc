/*
 * audio_wb.v
 *
 * vim: ts=4 sw=4
 *
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

module audio_wb (
	// Audio output
	output wire [15:0] audio_out_l,
	output wire [15:0] audio_out_r,
	output wire [15:0] audio_out_pdm,

	// Bus interface
	input  wire [15:0] bus_addr,
	input  wire [31:0] bus_wdata,
	output reg  [31:0] bus_rdata,
	input  wire bus_cyc,
	output wire bus_ack,
	input  wire bus_we,

	// IRQ
	output reg  irq,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	// Signals
	// -------

	// Audio
	wire [15:0] audio_synth_l;
	wire [15:0] audio_synth_r;
	wire [11:0] audio_synth_dc;

	// Strobes
	wire stb_pcm;
	wire stb_synth;
	wire stb_tick_fast;
	wire stb_tick_slow;

	// Synth Status
	wire [ 4:0] active_voices;

	// Config bus
		// From wishbone
	wire [31:0] cb0_data;
	wire [ 3:0] cb0_voice;
	wire [ 2:0] cb0_reg;
	reg         cb0_stb_v;
	reg         cb0_stb_g;

		// From commands
	wire [31:0] cb1_data;
	wire [ 3:0] cb1_voice;
	wire [ 2:0] cb1_reg;
	wire        cb1_stb_v;
	wire        cb1_stb_g;
	wire        cb1_ready;

		// Final
	reg  [31:0] cb_data;
	reg  [ 3:0] cb_voice;
	reg  [ 2:0] cb_reg;
	reg         cb_stb_v;
	reg         cb_stb_g;

	// Config read-back
	wire [ 2:0] crb_reg;
	wire [31:0] crb_data;

	// Wave Table
	wire [11:0] wtw_addr;
	wire [31:0] wtw_data;
	reg         wtw_ena;

	wire [11:0] wtr_addr_0;
	reg  [ 1:0] wtr_bytesel_1;
	wire [31:0] wtr_data32_1;
	reg  [ 7:0] wtr_data8_1;

	// Command FIFO
	reg  [24:0] cf_wdata;
	wire cf_wen;
	wire cf_full;
	wire cf_afull;
	wire [24:0] cf_rdata;
	reg  cf_ren;
	wire cf_empty;
	wire cf_aempty;

	reg  cf_wen_i;
	reg  cf_overflow;
	wire cf_overflow_clr;

	// Event FIFO
	wire [ 7:0] ef_wdata;
	wire ef_wen;
	wire ef_full;
	wire [ 7:0] ef_rdata;
	reg  ef_ren;
	wire ef_empty;

	wire ef_wen_i;
	reg  ef_overflow;
	wire ef_overflow_clr;

	// Sample FIFO
	wire [23:0] sf_wdata;
	wire sf_wen;
	wire sf_full;
	wire sf_afull;
	wire [23:0] sf_rdata;
	wire sf_ren;
	wire sf_empty;
	wire sf_aempty;

	wire sf_wen_i;
	reg  sf_overflow;
	wire sf_overflow_clr;

	wire sf_ren_i;
	reg  sf_underflow;
	wire sf_underflow_clr;

	// Delay (commands)
	reg  delay_ld;
	reg  [16:0] delay_cnt;

	// PCM
	reg        cfg_pcm_enable;
	reg [13:0] cfg_pcm_divider;
	reg [ 7:0] cfg_pcm_volume_l;
	reg [ 7:0] cfg_pcm_volume_r;

	reg [14:0] pcm_div_cnt;

	// IRQ
	reg  irq_msk_sf_afull_n;
	reg  irq_msk_sf_aempty;
	reg  irq_msk_cf_afull_n;
	reg  irq_msk_cf_aempty;
	reg  irq_msk_ef_empty_n;

	// Misc
	reg  force_pdm_offset;

	// Bus Interface
	wire ack_nxt;
	reg  ack;

	wire wr_rst;
	wire rd_rst;

	reg  bwe_audio_csr;
	reg  bwe_pcm_cfg;
	reg  bwe_pcm_data;

	wire [31:0] rd_csr;
	wire [31:0] rd_evt;
	wire [31:0] rd_pcm_cfg;


	// Synthesizer
	// -----------

	// Core
	synth_core core_I (
		.audio_out_l(audio_synth_l),
		.audio_out_r(audio_synth_r),
		.audio_out_dc(audio_synth_dc),
		.wt_addr(wtr_addr_0),
		.wt_data(wtr_data8_1),
		.cb_data(cb_data),
		.cb_voice(cb_voice),
		.cb_reg(cb_reg),
		.cb_stb_v(cb_stb_v),
		.cb_stb_g(cb_stb_g),
		.crb_reg(crb_reg),
		.crb_data(crb_data),
		.stb_sample(stb_synth),
		.stb_tick_fast(stb_tick_fast),
		.stb_tick_slow(stb_tick_slow),
		.active_voices(active_voices),
		.clk(clk),
		.rst(rst)
	);

	// Config bus arbiter
	always @(posedge clk)
	begin
		cb_data   <= cb1_ready ? cb1_data   : cb0_data;
		cb_voice  <= cb1_ready ? cb1_voice  : cb0_voice;
		cb_reg    <= cb1_ready ? cb1_reg    : cb0_reg;
		cb_stb_v  <= cb1_ready ? cb1_stb_v  : cb0_stb_v;
		cb_stb_g  <= cb1_ready ? cb1_stb_g  : cb0_stb_g;
	end

	assign cb1_ready = ~(cb0_stb_v || cb0_stb_g);


	// Wave Table
	// ----------

	// FPGA could handle width adaptation ... but not with inferrence and
	// I don't want to bother with instantiation here

	ram_sdp #(
		.AWIDTH(10),
		.DWIDTH(32)
	) wt_I (
		.wr_addr(wtw_addr),
		.wr_data(wtw_data),
		.wr_ena(wtw_ena),
		.rd_addr(wtr_addr_0[11:2]),
		.rd_data(wtr_data32_1),
		.rd_ena(1'b1),
		.clk(clk)
	);

	always @(posedge clk)
		wtr_bytesel_1 <= wtr_addr_0[1:0];

	always @(*)
		case (wtr_bytesel_1)
			2'b00:   wtr_data8_1 = wtr_data32_1[ 7: 0];
			2'b01:   wtr_data8_1 = wtr_data32_1[15: 8];
			2'b10:   wtr_data8_1 = wtr_data32_1[23:16];
			2'b11:   wtr_data8_1 = wtr_data32_1[31:24];
			default: wtr_data8_1 = 8'hxx;
		endcase


	// Command Queue
	// -------------

	// Command FIFO
	fifo_sync_ram #(
		.DEPTH(512),
		.WIDTH(25)	/* 9b address/cmd + 16b data */
	) fifo_cmd_I (
		.wr_data(cf_wdata),
		.wr_ena(cf_wen),
		.wr_full(cf_full),
		.wr_afull(cf_afull),
		.rd_data(cf_rdata),
		.rd_ena(cf_ren),
		.rd_empty(cf_empty),
		.rd_aempty(cf_aempty),
		.clk(clk),
		.rst(rst)
	);

	assign cf_wen = cf_wen_i & ~cf_full;

	always @(posedge clk)
		if (rst)
			cf_overflow <= 1'b0;
		else
			cf_overflow <= (cf_overflow & ~cf_overflow_clr) | (cf_wen_i & cf_full);

	// Event FIFO
	fifo_sync_ram #(
		.DEPTH(16),
		.WIDTH(8)
	) fifo_evt_I (
		.wr_data(ef_wdata),
		.wr_ena(ef_wen),
		.wr_full(ef_full),
		.rd_data(ef_rdata),
		.rd_ena(ef_ren),
		.rd_empty(ef_empty),
		.clk(clk),
		.rst(rst)
	);

	assign ef_wen = ef_wen_i & ~ef_full;

	always @(posedge clk)
		if (rst)
			ef_overflow <= 1'b0;
		else
			ef_overflow <= (ef_overflow & ~ef_overflow_clr) | (ef_wen_i & ef_full);

	// FIFO control
	always @(*)
		if (cf_empty)
			cf_ren = 1'b0;
		else
			casez (cf_rdata[24:23])
				2'b0z:   cf_ren = cb1_ready;
				2'b10:   cf_ren = ~delay_ld & delay_cnt[16];
				2'b11:   cf_ren = 1'b1;
				default: cf_ren = 1'b0;
			endcase

	// Config bus
	assign cb1_data  = { 16'h0000, cf_rdata[15:0] };
	assign cb1_voice = cf_rdata[22:19];
	assign cb1_reg   = cf_rdata[18:16];
	assign cb1_stb_v = ~cf_empty & (cf_rdata[24:23] == 2'b00);
	assign cb1_stb_g = ~cf_empty & (cf_rdata[24:23] == 2'b01);

	// Event push
	assign ef_wdata = cf_rdata[7:0];
	assign ef_wen_i = ~cf_empty & (cf_rdata[24:23] == 2'b11);

	// Delay counter
	always @(posedge clk)
		delay_ld <= cf_ren | cf_empty;

	always @(posedge clk)
		delay_cnt <= delay_ld ? { 1'b0, cf_rdata[15:0] } : (delay_cnt - (stb_synth ? 1 : 0));


	// PCM
	// ---

	// Sample FIFO
	fifo_sync_ram #(
		.DEPTH(2048),
		.WIDTH(16)
	) fifo_pcm_I (
		.wr_data(sf_wdata),
		.wr_ena(sf_wen),
		.wr_full(sf_full),
		.wr_afull(sf_afull),
		.rd_data(sf_rdata),
		.rd_ena(sf_ren),
		.rd_empty(sf_empty),
		.rd_aempty(sf_aempty),
		.clk(clk),
		.rst(rst)
	);

	assign sf_wen = sf_wen_i & ~sf_full;
	assign sf_ren = sf_ren_i & ~sf_empty;

	always @(posedge clk)
		if (rst) begin
			sf_overflow  <= 1'b0;
			sf_underflow <= 1'b0;
		end else begin
			sf_overflow  <= (sf_overflow  & ~sf_overflow_clr)  | (sf_wen_i & sf_full);
			sf_underflow <= (sf_underflow & ~sf_underflow_clr) | (sf_ren_i & sf_empty);
		end

	// Sample divider
	always @(posedge clk)
		if (~cfg_pcm_enable)
			pcm_div_cnt <= 15'h0000;
		else
			pcm_div_cnt <= stb_pcm ? { 1'b0, cfg_pcm_divider } : (pcm_div_cnt - 1);

	assign stb_pcm = pcm_div_cnt[14];

	// FIFO read
	assign sf_ren_i = stb_pcm;


	// Final Audio Mixer
	// -----------------

	audio_mix mix_I (
		.synth_l(audio_synth_l),
		.synth_r(audio_synth_r),
		.synth_dc(audio_synth_dc),
		.synth_voices(active_voices),
		.pcm(sf_rdata),
		.pcm_vol_l(cfg_pcm_volume_l),
		.pcm_vol_r(cfg_pcm_volume_r),
		.pcm_ena(~sf_empty & cfg_pcm_enable),
		.out_l(audio_out_l),
		.out_r(audio_out_r),
		.out_pdm(audio_out_pdm),
		.force_pdm_offset(force_pdm_offset),
		.clk(clk),
		.rst(rst)
	);


	// Interrupt logic
	// ---------------

	always @(posedge clk)
		irq <= (
			(irq_msk_sf_afull_n & ~sf_afull ) |
			(irq_msk_sf_aempty  &  sf_aempty) |
			(irq_msk_cf_afull_n & ~cf_afull ) |
			(irq_msk_cf_aempty  &  cf_aempty) |
			(irq_msk_ef_empty_n & ~ef_empty )
		);


	// Bus Interface
	// -------------

	// Ack
	assign ack_nxt = bus_cyc & ~ack;

	always @(posedge clk)
		ack <= ack_nxt;

	assign bus_ack = ack;

	// Write
	assign wr_rst = ack | ~(bus_cyc & bus_we);

	always @(posedge clk)
		if (wr_rst) begin
			bwe_audio_csr <= 1'b0;
			bwe_pcm_cfg   <= 1'b0;
			bwe_pcm_data  <= 1'b0;
		end else begin
			bwe_audio_csr <= (bus_addr[15:14] == 2'b00) & (bus_addr[1:0] == 2'b00);
			bwe_pcm_cfg   <= (bus_addr[15:14] == 2'b00) & (bus_addr[1:0] == 2'b10);
			bwe_pcm_data  <= (bus_addr[15:14] == 2'b00) & (bus_addr[1:0] == 2'b11);
		end

	assign cf_overflow_clr  = bwe_audio_csr & bus_wdata[19];
	assign ef_overflow_clr  = bwe_audio_csr & bus_wdata[18];
	assign sf_overflow_clr  = bwe_audio_csr & bus_wdata[27];
	assign sf_underflow_clr = bwe_audio_csr & bus_wdata[26];

	always @(posedge clk)
		if (rst)
			force_pdm_offset <= 1'b0;
		else
			if (bwe_audio_csr & bus_wdata[0])
				force_pdm_offset <= 1'b1;
			else if (bwe_audio_csr & bus_wdata[1])
				force_pdm_offset <= 1'b0;

	always @(posedge clk)
		if (rst) begin
			irq_msk_sf_afull_n  <= 1'b0;
			irq_msk_sf_aempty   <= 1'b0;
			irq_msk_cf_afull_n  <= 1'b0;
			irq_msk_cf_aempty   <= 1'b0;
			irq_msk_ef_empty_n  <= 1'b0;
		end else if (bwe_audio_csr) begin
			irq_msk_sf_afull_n  <= bus_wdata[15];
			irq_msk_sf_aempty   <= bus_wdata[14];
			irq_msk_cf_afull_n  <= bus_wdata[13];
			irq_msk_cf_aempty   <= bus_wdata[12];
			irq_msk_ef_empty_n  <= bus_wdata[11];
		end

	always @(posedge clk)
		if (rst) begin
			cfg_pcm_enable   <= 1'b0;
			cfg_pcm_divider  <= 14'h0000;
			cfg_pcm_volume_l <= 8'h00;
			cfg_pcm_volume_r <= 8'h00;
		end else if (bwe_pcm_cfg) begin
			cfg_pcm_enable   <= bus_wdata[31];
			cfg_pcm_divider  <= bus_wdata[29:16];
			cfg_pcm_volume_l <= bus_wdata[15: 8];
			cfg_pcm_volume_r <= bus_wdata[ 7: 0];
		end

	// PCM FIFO write
	assign sf_wdata = bus_wdata[15:0];
	assign sf_wen_i = bwe_pcm_data;

	// Wave Table write
	assign wtw_addr = bus_addr[11:0];
	assign wtw_data = bus_wdata;

	always @(posedge clk)
		if (wr_rst)
			wtw_ena <= 1'b0;
		else
			wtw_ena <= (bus_addr[15:14] == 2'b01);

	// Config Bus write
	assign cb0_data  = bus_wdata;
	assign cb0_voice = bus_addr[6:3];
	assign cb0_reg   = bus_addr[2:0];

	always @(posedge clk)
		if (wr_rst) begin
			cb0_stb_v <= 1'b0;
			cb0_stb_g <= 1'b0;
		end else begin
			cb0_stb_v <= (bus_addr[15:14] == 2'b10) & ~bus_addr[7];
			cb0_stb_g <= (bus_addr[15:14] == 2'b10) &  bus_addr[7];
		end

	// Command queue write
	always @(posedge clk)
		if (wr_rst)
			cf_wen_i <= 1'b0;
		else
			cf_wen_i <= (bus_addr[15:14] == 2'b11);

	always @(*)
	begin
		/* Type */
		casez ({bus_addr[7], bus_addr[3]})
			2'b0z:   cf_wdata[24:23] = 2'b00; // Voice register write
			2'b10:   cf_wdata[24:23] = 2'b01; // Global register write
			2'b11:   cf_wdata[24:23] = { 1'b1, bus_addr[0] };	// Command write
			default: cf_wdata[24:23] = 2'bxx;
		endcase

		/* Address */
		cf_wdata[22:16] = bus_addr[6:0];

		/* Data Payload */
		cf_wdata[15:0] = bus_wdata[15:0];
	end

	// Read Mux
	assign rd_rst = ~bus_cyc | ack;

	always @(posedge clk)
		if (rd_rst)
			bus_rdata <= 32'h00000000;
		else
			casez ({bus_addr[15], bus_addr[1:0]})
				3'b000:  bus_rdata <= rd_csr;
				3'b001:  bus_rdata <= rd_evt;
				3'b010:  bus_rdata <= rd_pcm_cfg;
				3'b011:  bus_rdata <= 32'h00000000;
				3'b1zz:  bus_rdata <= crb_data;
				default: bus_rdata <= 32'h00000000;
			endcase

	assign crb_reg = bus_addr[2:0];

	assign rd_csr = {
		sf_full, sf_afull, sf_aempty, sf_empty,
		sf_overflow, sf_underflow, 2'b00,
		cf_full, cf_afull, cf_aempty, cf_empty,
		cf_overflow, ef_overflow, ef_full, ef_empty,
		irq_msk_sf_afull_n, irq_msk_sf_aempty, irq_msk_cf_afull_n, irq_msk_cf_aempty,
		irq_msk_ef_empty_n,
		11'h000
	};

	assign rd_evt = {
		ef_empty,
		23'h000000,
		ef_rdata
	};

	assign rd_pcm_cfg = {
		cfg_pcm_enable,
		1'b0,
		cfg_pcm_divider,
		cfg_pcm_volume_l,
		cfg_pcm_volume_r
	};

	// Event Read
	always @(posedge clk)
		ef_ren <= ack & ~bus_we & ~bus_rdata[31] & ~bus_addr[15] & (bus_addr[1:0] == 2'b01);

endmodule // audio_wb
