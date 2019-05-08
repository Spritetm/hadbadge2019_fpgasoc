
module pcpi_fastmul_dsp (
	input clk, reset,
	input             pcpi_valid,
	input      [31:0] pcpi_insn,
	input      [31:0] pcpi_rs1,
	input      [31:0] pcpi_rs2,
	output            pcpi_wr,
	output reg     [31:0] pcpi_rd,
	output            pcpi_wait,
	output reg            pcpi_ready
);
	reg instr_mul, instr_mulh, instr_mulhsu, instr_mulhu;
	wire shift_out = |{instr_mulh, instr_mulhsu, instr_mulhu};
	wire any_mul_ins= |{instr_mul, instr_mulh, instr_mulhsu, instr_mulhu};

	//Decode instruction. First, pcpi_insn_valid is 1 if the instruction is in the mul* instruction group.
	wire pcpi_insn_valid = pcpi_valid && pcpi_insn[6:0] == 7'b0110011 && pcpi_insn[31:25] == 7'b0000001;
	always @* begin
		instr_mul = 0;
		instr_mulh = 0;
		instr_mulhsu = 0;
		instr_mulhu = 0;

		if (!reset && pcpi_insn_valid) begin
			case (pcpi_insn[14:12])
				3'b000: instr_mul = 1;
				3'b001: instr_mulh = 1;
				3'b010: instr_mulhsu = 1;
				3'b011: instr_mulhu = 1;
			endcase
		end
	end

	//this is a mess... but a working mess, according to the testbench.
	wire [17:0] rs1_hi;
	wire [17:0] rs1_lo;
	wire [17:0] rs2_hi;
	wire [17:0] rs2_lo;
	wire rs1_sign = (instr_mulh||instr_mulhsu)?pcpi_rs1[31]:0;
	assign rs1_hi[15:0]=pcpi_rs1[31:16];
	assign rs1_hi[16]=rs1_sign;
	assign rs1_hi[17]=rs1_sign;

	wire rs2_sign = (instr_mulh)?pcpi_rs2[31]:0;
	assign rs2_hi[15:0]=pcpi_rs2[31:16];
	assign rs2_hi[16]=rs2_sign;
	assign rs2_hi[17]=rs2_sign;

	assign rs1_lo[15:0]=pcpi_rs1[15:0];
	assign rs1_lo[16]=0;
	assign rs1_lo[17]=0;

	assign rs2_lo[15:0]=pcpi_rs2[15:0];
	assign rs2_lo[16]=0;
	assign rs2_lo[17]=0;

	wire [35:0] res_hh, res_hl, res_lh, res_ll;
	wire [63:0] res_hh_ex, res_hl_ex, res_lh_ex, res_ll_ex;
	assign res_hh_ex={res_hh[31:0], 32'h0};
	assign res_hl_ex={{16{res_hl[32]}}, res_hl[31:0], 16'h0};
	assign res_lh_ex={{16{res_lh[32]}}, res_lh[31:0], 16'h0};
	assign res_ll_ex={{32{res_ll[32]}}, res_ll[31:0]};

	wire [63:0] res_tot;
	assign res_tot=res_hh_ex+res_hl_ex+res_lh_ex+res_ll_ex;

	mul_18x18 mulhh (
		.clock(clk),
		.reset(reset),
		.a(rs1_hi),
		.b(rs2_hi),
		.dout(res_hh)
	);
	mul_18x18 mulhl (
		.clock(clk),
		.reset(reset),
		.a(rs1_hi),
		.b(rs2_lo),
		.dout(res_hl)
	);
	mul_18x18 mullh (
		.clock(clk),
		.reset(reset),
		.a(rs1_lo),
		.b(rs2_hi),
		.dout(res_lh)
	);
	mul_18x18 mulll (
		.clock(clk),
		.reset(reset),
		.a(rs1_lo),
		.b(rs2_lo),
		.dout(res_ll)
	);

	reg [3:0] wait_stage;
	always @(posedge clk) begin
		if (reset) begin
			pcpi_ready <= 0;
			wait_stage <= 0;
		end else begin
			if (any_mul_ins && (wait_stage < 4)) begin
				wait_stage <= wait_stage + 1;
			end else if (any_mul_ins) begin
				pcpi_ready <= 1;
				if (instr_mul) begin
					pcpi_rd <= res_tot[31:0];
				end else begin
					pcpi_rd <= res_tot[63:32];
				end
			end else begin
				pcpi_ready <= 0;
				pcpi_rd <= 'hx;
				wait_stage <= 0;
			end;
		end
	end

	assign pcpi_wait = 0; //we can handle this within 16 cycles
	assign pcpi_wr = pcpi_ready;
endmodule
