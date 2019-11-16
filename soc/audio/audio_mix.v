/*
 * audio_mix.v
 *
 * vim: ts=4 sw=4
 *
 * Audio: Final mixing combining PCM and synthesizer and dealing with PDM DC
 *        level auto-adjust.
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

module audio_mix (
	// Synth input
	input  wire [15:0] synth_l,
	input  wire [15:0] synth_r,
	input  wire [11:0] synth_dc,
	input  wire [ 4:0] synth_voices,

	// PCM input
	input  wire [15:0] pcm,

	input  wire [ 7:0] pcm_vol_l,
	input  wire [ 7:0] pcm_vol_r,

	input  wire pcm_ena,

	// Outputs
	output wire [15:0] out_l,
	output wire [15:0] out_r,
	output reg  [15:0] out_pdm,

	input  wire force_pdm_offset,

	// Clock / Reset
	input  wire clk,
	input  wire rst
);

	// Signals
	reg  [35:0] m_l;
	reg  [35:0] m_r;

	reg  [35:0] pa_l;
	reg  [35:0] pa_r;

	reg  pcm_ena_1, pcm_ena_2;
	reg  [15:0] pdm_offset;

	// PCM volume
	always @(posedge clk)
		if (~pcm_ena) begin
			m_l <= 36'h000000000;
			m_r <= 36'h000000000;
		end else begin
			m_l <= $signed({pcm[15], pcm[15], pcm}) * { 10'd0, pcm_vol_l };
			m_r <= $signed({pcm[15], pcm[15], pcm}) * { 10'd0, pcm_vol_l };
		end

	// Post adder
	always @(posedge clk)
	begin
		pa_l <= { {(12){synth_l[15]}}, synth_l, 8'h00 } + m_l;
		pa_r <= { {(12){synth_r[15]}}, synth_r, 8'h00 } + m_r;
	end

	// Done for the 'normal' outputs
	assign out_l = pa_l[23:8];
	assign out_r = pa_r[23:8];

	// Align PCM enable
	always @(posedge clk)
	begin
		pcm_ena_1 <= pcm_ena;
		pcm_ena_2 <= pcm_ena_1;
	end

	// Apply variable DC offset for PDM output
	always @(*)
		if (pcm_ena_2 | force_pdm_offset)
			pdm_offset = 16'h8000;
		else if (synth_dc[11:10] != 2'b00)
			pdm_offset = 16'h8000;
		else
			pdm_offset = { 1'b0, synth_dc[9:0], 5'b0 };

	always @(posedge clk)
		out_pdm <= out_l + pdm_offset;

endmodule // audio_mix
