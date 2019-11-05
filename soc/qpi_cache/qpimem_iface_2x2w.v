/*
 * qpimem_iface_2x2w.v
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

module qpimem_iface_2x2w #(
	parameter [7:0] CMD_READ  = 8'hEB,
	parameter [7:0] CMD_WRITE = 8'h38,
	parameter integer DUMMY_BYTES = 3
)(
	// SPI PHY interface
	input  wire [15:0] spi_io_i,	// [15:8] chip 1 / [7:0] chip 0
	output wire [15:0] spi_io_o,	// [15:8] chip 1 / [7:0] chip 0
	output wire [ 7:0] spi_io_t,	//  [7:4] chip 1 / [3:0] chip 0

	output wire [1:0] spi_sck_o,
	output reg  spi_cs_o,

	// QPI memory interface
    input  wire qpi_do_read,
    input  wire qpi_do_write,
    input  wire [23:0] qpi_addr,
    output wire qpi_is_idle,

    input  wire [31:0] qpi_wdata,
    output wire [31:0] qpi_rdata,
    output wire qpi_next_word,

	// Wishbone interface
	input  wire [ 3:0] bus_addr,
	input  wire [31:0] bus_wdata,
	output reg  [31:0] bus_rdata,
	input  wire bus_cyc,
	output wire bus_ack,
	input  wire bus_we,

	// Clock
	input  wire clk,
	input  wire rst
);

	// [0]    CSR
	//		[7] Response FIFO Empty
	//		[6] Response FIFO Full
	//		[5] Response FIFO Overflow (Write '1' to clear)
	//		[4] Command FIFO Empty
	//		[3] Command FIFO Full
	//		[2] Granted control (R) / Release control (W)
	//		[1] Requested control (R) / Request control (W)
	//		[0] IDLE
	//
	// [2]    Response read (non-blocking)
	// [3]    Response read (blocking)
	//
	// [2-7]  Reserved
	//
	// [8-15] Command Submit
	//		For writes, the 3 LSB of the addresses indicate which type
	//		of command is submitted :
	//
	//		[0] 16b   (0)  /  32b  (1)
	//		[1] Write (0)  /  Read (1)
	//		[2] SPI   (0)  /  QPI  (1)

	// Helpers
	// -------

	function [7:0] il8 (input [7:0] data);
		il8 = {
			data[1], data[3], data[5], data[7],
			data[0], data[2], data[4], data[6]
		};
	endfunction


	// Signals
	// -------

	// Bus interface
	reg  ack_nxt;
	reg  ack;

	wire we_csr;
	wire [31:0] rd_csr;

	reg  rf_rden_arm;

	wire rd_rst;

	// Command & Reponse FIFOs
	wire [34:0] cf_di;
	reg  cf_wren;
	wire cf_full;
	wire [34:0] cf_do;
	wire cf_rden;
	wire cf_empty;

	wire [31:0] rf_di;
	wire rf_wren_safe;
	wire rf_wren;
	wire rf_full;
	wire [31:0] rf_do;
	wire rf_rden;
	wire rf_empty;

	reg  rf_overflow;
	reg  rf_overflow_clr;

	// Main Control FSM
	reg  [ 3:0] state;
	reg  [ 3:0] state_nxt;

	// Command interface
	wire [ 2:0] cmd_type;
	wire [31:0] cmd_data;
	wire cmd_valid;

	// External control state
	reg  ectl_req;
	wire ectl_grant;
	wire ectl_idle;

	// QPI interface
	reg qpi_rw;			// Write (0) / Read (1)

	reg  [3:0] qpi_dummy;
	wire qpi_dummy_last;

	// Shifting units
		// Possible next states
	wire [31:0] so_ld_cmd_data;
	wire [ 3:0] so_ld_cmd_tris;
	wire [ 3:0] sc_ld_cmd_cnt;

	wire [31:0] so_ld_qpi_data;
	wire [ 3:0] so_ld_qpi_tris;
	wire [ 3:0] sc_ld_qpi_cnt;

	reg  [31:0] so_ld_fix_data;
	wire [ 3:0] so_ld_fix_tris;
	wire [ 3:0] sc_ld_fix_cnt;

	wire [31:0] so_sh1x_data;
	wire [31:0] so_sh4x_data;

		// Shift control
	reg  sc_valid_nxt;
	reg  sc_valid;

	reg  [1:0] sc_sel;
	reg  [1:0] sc_ld_fix_sel;

	reg  sc_mode;			// 1x (0) / 4x (1)
	reg  sc_rw;				// Write (0) / Read (1)
	reg  sc_qpi;			// Is it a QPI transaction ?
	wire sc_last;
	reg [ 3:0] sc_cnt;

		// Shift out
	reg [31:0] so_data;
	reg [ 3:0] so_tris;

		// Shift in
	reg  si_to_qpi_1;
	reg  si_to_cmd_1;

	wire si_mode_5;
	wire si_to_qpi_6;
	wire si_to_cmd_6;

	reg [15:0] spi_io_i_r;

	wire si_mode;
	reg [31:0] si_data_6;


	// Bus interface
	// -------------

	// Ack
	always @(*)
	begin
		ack_nxt = bus_cyc & ~ack;

		// Block on write to full command fifo
		if (bus_we & bus_addr[2] & cf_full)
			ack_nxt = 1'b0;

		// Block on read from empty response fifo if in blocking mode
		if (~bus_we & (bus_addr == 4'h3) & rf_empty)
			ack_nxt = 1'b0;
	end

	always @(posedge clk)
		ack <= ack_nxt;

	assign bus_ack = ack;

	// CSR
	assign we_csr = ack & bus_we & (bus_addr == 4'h0);

	always @(posedge clk)
		if (rst) begin
			ectl_req <= 1'b0;
		end else if (we_csr) begin
			ectl_req <= (ectl_req & ~bus_wdata[2]) | bus_wdata[1];
		end

	always @(posedge clk)
		rf_overflow_clr <= bus_cyc & bus_we & ~ack & (bus_addr == 4'h0);

	assign rd_csr = {
		24'h000000,
		rf_empty, rf_full, rf_overflow,
		cf_empty, cf_full,
		ectl_grant, ectl_req, ectl_idle
	};

	// Command FIFO write
	assign cf_di = { bus_addr[2:0], bus_wdata };

	always @(posedge clk)
		cf_wren <= bus_cyc & bus_we & ~ack & bus_addr[3] & ~cf_full;

	// Response FIFO read
	always @(posedge clk)
		rf_rden_arm <= ~rf_empty & (bus_addr[3:1] == 3'b001) & ~bus_we;

	assign rf_rden = ack & rf_rden_arm;

	// Read mux
	assign rd_rst = ~bus_cyc | ack;

	always @(posedge clk)
		if (rd_rst)
			bus_rdata <= 32'h0000000;
		else
			bus_rdata <= bus_addr[1] ? rf_do : rd_csr;


	// Commands
	// --------

	// Command FIFO
	fifo_sync_ram #(
		.DEPTH(16),
		.WIDTH(35)
	) cmd_fifo_I (
		.wr_data(cf_di),
		.wr_ena(cf_wren),
		.wr_full(cf_full),
		.rd_data(cf_do),
		.rd_ena(cf_rden),
		.rd_empty(cf_empty),
		.clk(clk),
		.rst(rst)
	);

	// Response FIFO
	fifo_sync_ram #(
		.DEPTH(16),
		.WIDTH(32)
	) rsp_fifo_I (
		.wr_data(rf_di),
		.wr_ena(rf_wren_safe),
		.wr_full(rf_full),
		.rd_data(rf_do),
		.rd_ena(rf_rden),
		.rd_empty(rf_empty),
		.clk(clk),
		.rst(rst)
	);

	// Response overflow tracking
	assign rf_wren_safe = rf_wren & ~rf_full;

	always @(posedge clk)
		rf_overflow <= (rf_overflow & ~rf_overflow_clr) | (rf_wren & rf_full);

	// Capture responses
	assign rf_di = { si_data_6[23:16], si_data_6[7:0], si_data_6[31:24], si_data_6[15:8] };
	assign rf_wren = si_to_cmd_6;


	// Main control
	// ------------

	localparam
		ST_IDLE = 0,
		ST_CMD_IDLE = 1,
		ST_CMD_ACTIVE = 2,
		ST_CMD_FLUSH = 3,
		ST_CMD_WAIT = 4,
		ST_QPI_CMD_1 = 5,
		ST_QPI_CMD_2 = 6,
		ST_QPI_WR_DATA = 7,
		ST_QPI_WR_FLUSH = 8,
		ST_QPI_RD_DUMMY = 9,
		ST_QPI_RD_DATA = 10,
		ST_QPI_RD_FLUSH = 11;


	// State register
	always @(posedge clk)
		if (rst)
			state <= ST_IDLE;
		else
			state <= state_nxt;

	// Next-State logic
	always @(*)
	begin
		// Default is to stay put
		state_nxt = state;

		// Transistion ?
		case (state)
			ST_IDLE:
				if (qpi_do_read | qpi_do_write)
					state_nxt = ST_QPI_CMD_1;
				else if (ectl_req)
					state_nxt = ST_CMD_IDLE;

			ST_CMD_IDLE:
				if (~cf_empty)
					state_nxt = ST_CMD_ACTIVE;
				else if (~ectl_req)
					state_nxt = ST_IDLE;

			ST_CMD_ACTIVE:
				if (~ectl_req & cf_empty)
					state_nxt = ST_CMD_FLUSH;

			ST_CMD_FLUSH:
				if (~sc_valid)
					state_nxt = ST_CMD_WAIT;

			ST_CMD_WAIT:
				// Need one dummy cycle to ensure > 50us CE high pulse
				state_nxt = ST_IDLE;

			ST_QPI_CMD_1:
				if (sc_last)
					state_nxt = ST_QPI_CMD_2;

			ST_QPI_CMD_2:
				if (sc_last)
					state_nxt = qpi_rw ? ST_QPI_RD_DUMMY : ST_QPI_WR_DATA;

			ST_QPI_WR_DATA:
				if (sc_last & ~qpi_do_write)
					state_nxt = ST_QPI_WR_FLUSH;

			ST_QPI_WR_FLUSH:
				if (~sc_valid)
					state_nxt = ST_IDLE;

			ST_QPI_RD_DUMMY:
				if (sc_last & qpi_dummy_last)
					state_nxt = ST_QPI_RD_DATA;

			ST_QPI_RD_DATA:
				if (sc_last & ~qpi_do_read)
					state_nxt = ST_QPI_RD_FLUSH;

			ST_QPI_RD_FLUSH:
				if (~sc_valid)
					state_nxt = ST_IDLE;
		endcase
	end

	// Chip select
	always @(*)
		spi_cs_o = (state == ST_IDLE) || (state == ST_CMD_IDLE) || (state == ST_CMD_WAIT) || (state == ST_QPI_CMD_1);

	// Command interface
	assign cmd_type  = cf_do[34:32];
	assign cmd_data  = cf_do[31:0];
	assign cmd_valid = ~cf_empty;

	assign cf_rden = ~cf_empty & (sc_sel == 2'b11);

	// External control
	assign ectl_idle  = (state == ST_IDLE);
	assign ectl_grant = (state == ST_CMD_IDLE) || (state == ST_CMD_ACTIVE);

	// QPI interface
	always @(posedge clk)
		if (state == ST_IDLE)
			qpi_rw <= qpi_do_read;

	assign qpi_next_word = (
		((state == ST_QPI_RD_DATA) & si_to_qpi_6) |
		((state == ST_QPI_WR_DATA) & sc_last)
	);

	assign qpi_is_idle = (state == ST_IDLE);

	always @(posedge clk)
		if (state != ST_QPI_RD_DUMMY)
			qpi_dummy <= DUMMY_BYTES - 2;
		else if (sc_last)
			qpi_dummy <= qpi_dummy - 1;

	assign qpi_dummy_last = qpi_dummy[3];

	assign qpi_rdata = { si_data_6[23:16], si_data_6[7:0], si_data_6[31:24], si_data_6[15:8] };


	// Shifting unit
	// -------------

	// Control
	always @(*)
	begin
		// Defaults
		sc_valid_nxt  = 1'b0;
		sc_sel        = 2'b01;
		sc_ld_fix_sel = 2'b00;

		// Do we need a load ?
		if (sc_valid & ~sc_last) begin
			// We're in a command and it's not the end, so just shift
			sc_valid_nxt = 1'b1;
			sc_sel       = 2'b00;
		end else begin
			// Either this is the last of active command or we're not active
			// in either case, we need to load something
			case (state)
				// If we're in command mode, just read from FIFO
				ST_CMD_IDLE, ST_CMD_ACTIVE: begin
					sc_valid_nxt = cmd_valid;
					sc_sel = 2'b11;
				end

				// Send command and 8 MSBs of address
				ST_QPI_CMD_1: begin
					sc_valid_nxt = 1'b1;
					sc_sel = 2'b01;
					sc_ld_fix_sel = qpi_rw ? 2'b10 : 2'b11;
				end

				// Send the 16 LSBs of address
				ST_QPI_CMD_2: begin
					sc_valid_nxt = 1'b1;
					sc_sel = 2'b01;
					sc_ld_fix_sel = 2'b01;
				end

				// For Writes, send data
				ST_QPI_WR_DATA: begin
					sc_valid_nxt = 1'b1;
					sc_sel = 2'b10;
				end

				// For Dummy cycles just output with IO tristated (8b)
				ST_QPI_RD_DUMMY: begin
					sc_valid_nxt = 1'b1;
					sc_sel = 2'b01;
					sc_ld_fix_sel = 2'b00;
				end

				// For reads, just output with IO tristated (16b)
				ST_QPI_RD_DATA: begin
					sc_valid_nxt = 1'b1;
					sc_sel = 2'b10;
				end

				// Default is to load a fixed tristate
				default: begin
					sc_sel = 2'b01;
					sc_ld_fix_sel = 2'b00;
				end
			endcase
		end
	end

	// Validity tracking
	always @(posedge clk)
		if (rst)
			sc_valid <= 1'b0;
		else
			sc_valid <= sc_valid_nxt;

	// Possible next states signals

		// Load from command
	assign so_ld_cmd_data = cmd_type[2] ?
		{     cmd_data[15:8],      cmd_data[31:24],      cmd_data[7:0],      cmd_data[23:16]  } :
		{ il8(cmd_data[15:8]), il8(cmd_data[31:24]), il8(cmd_data[7:0]), il8(cmd_data[23:16]) };

	assign so_ld_cmd_tris = cmd_type[2] ?
		{ 4{cmd_type[1]} } :
		4'b1110;

	assign sc_ld_cmd_cnt  = cmd_type[2] ?
		(cmd_type[0] ? 4'h0 : 4'hf) :
		(cmd_type[0] ? 4'h6 : 4'h2);

		// Load from QPI if
	assign so_ld_qpi_data = { qpi_wdata[15:8], qpi_wdata[31:24], qpi_wdata[7:0], qpi_wdata[23:16] };
	assign so_ld_qpi_tris = { 4{qpi_rw} };
	assign sc_ld_qpi_cnt  = 4'h0;

		// Load "fixed" value
			// 00 - 0xzz (dummy)
			// 01 - qpi_addr[15:0]
			// 10 - { WRITE_COMMAND, qpi_addr[23:16] }
			// 11 - { READ_COMMAND, qpi_addr[23:16] }
	always @(*)
		case (sc_ld_fix_sel)
			2'b00:   so_ld_fix_data = 32'h00000000;
			2'b01:   so_ld_fix_data = { qpi_addr[15:0], qpi_addr[15:0] };
			2'b10:   so_ld_fix_data = { CMD_READ,  qpi_addr[23:16], CMD_READ,  qpi_addr[23:16] };
			2'b11:   so_ld_fix_data = { CMD_WRITE, qpi_addr[23:16], CMD_WRITE, qpi_addr[23:16] };
			default: so_ld_fix_data = 32'hxxxxxxxx;
		endcase

	assign so_ld_fix_tris = (sc_ld_fix_sel == 2'b00) ? 4'hf : 4'b0;
	assign sc_ld_fix_cnt  = (sc_ld_fix_sel == 2'b00) ? 4'hf : 4'h0;

		// Shift-1x (SPI)
	assign so_sh1x_data = {
		so_data[20], so_data[31:29], so_data[16], so_data[27:25], 1'b0, so_data[23:21], 1'b0, so_data[19:17],
		so_data[ 4], so_data[15:13], so_data[ 0], so_data[11: 9], 1'b0, so_data[ 7: 5], 1'b0, so_data[ 3: 1]
	};

		// Shift-4x (QPI)
	assign so_sh4x_data = { so_data[23:16], 8'h00, so_data[7:0], 8'h00 };

	// Shift Out register & Shift counter
	always @(posedge clk)
		if (rst) begin
			so_data <= 32'h00000000;
			so_tris <= 4'hf;
			sc_cnt  <= 4'hf;
			sc_mode <= 1'b0;
			sc_rw   <= 1'b0;
			sc_qpi  <= 1'b0;
		end else begin
			// Main MUX
			case (sc_sel)
				2'b00: begin	// Shift
					so_data <= sc_mode ? so_sh4x_data : so_sh1x_data;
					so_tris <= so_tris;
					sc_cnt  <= sc_cnt - 1;
					sc_mode <= sc_mode;
					sc_rw   <= sc_rw;
					sc_qpi  <= sc_qpi;
				end

				2'b01: begin	// Load Fix
					so_data <= so_ld_fix_data;
					so_tris <= so_ld_fix_tris;
					sc_cnt  <= sc_ld_fix_cnt;
					sc_mode <= 1'b1;
					sc_rw   <= 1'b0;
					sc_qpi  <= 1'b0;
				end

				2'b10: begin	// Load QPI
					so_data <= so_ld_qpi_data;
					so_tris <= so_ld_qpi_tris;
					sc_cnt  <= sc_ld_qpi_cnt;
					sc_mode <= 1'b1;
					sc_rw   <= qpi_rw;
					sc_qpi  <= 1'b1;
				end

				2'b11: begin	// Load Command
					so_data <= so_ld_cmd_data;
					so_tris <= so_ld_cmd_tris;
					sc_cnt  <= sc_ld_cmd_cnt;
					sc_mode <= cmd_type[2];
					sc_rw   <= cmd_type[1];
					sc_qpi  <= 1'b0;
				end

				default: begin
					so_data <= 32'hxxxxxxxx;
					so_tris <= 4'hx;
					sc_cnt  <= 4'hx;
					sc_mode <= 1'bx;
					sc_rw   <= 1'bx;
					sc_qpi  <= 1'bx;
				end
			endcase

			// If the next is not valid, we force tristate
			if (~sc_valid_nxt)
				so_tris <= 4'hf;
		end

	assign sc_last = sc_cnt[3];

	// IO control
	assign spi_io_o  = { so_data[31:24], so_data[15:8] };
	assign spi_io_t  = { so_tris, so_tris };
	assign spi_sck_o = { sc_valid, 1'b0 };

	// Shift in control and delay lines
	always @(posedge clk)
	begin
		si_to_cmd_1 <= sc_valid & sc_last & sc_rw & ~sc_qpi;;
		si_to_qpi_1 <= sc_valid & sc_last & sc_rw &  sc_qpi;
	end

	delay_bit #(5) dly_si_mode   (sc_mode,     si_mode_5,   clk);
	delay_bit #(5) dly_si_to_cmd (si_to_cmd_1, si_to_cmd_6, clk);
	delay_bit #(5) dly_si_to_qpi (si_to_qpi_1, si_to_qpi_6, clk);

	// Shift in data
	always @(posedge clk)
		spi_io_i_r <= spi_io_i;

	always @(posedge clk)
	begin
		si_data_6 <= si_mode_5 ?
			{ si_data_6[23:16], spi_io_i_r[11:8], spi_io_i[15:12], si_data_6[7:0], spi_io_i_r[3:0], spi_io_i[7:4] } :
			{ si_data_6[29:16], spi_io_i_r[9], spi_io_i[13], si_data_6[13:0], spi_io_i_r[1], spi_io_i[5] };
	end

endmodule // qpimem_iface_2x2w
