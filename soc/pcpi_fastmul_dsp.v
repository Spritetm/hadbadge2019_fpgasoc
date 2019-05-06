
module pcpi_fastmul_dsp (
	input clk, reset,
	input             pcpi_valid,
	input      [31:0] pcpi_insn,
	input      [31:0] pcpi_rs1,
	input      [31:0] pcpi_rs2,
	output            pcpi_wr,
	output     [31:0] pcpi_rd,
	output            pcpi_wait,
	output            pcpi_ready
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


`ifdef verilator
	//simple and stupid multiply model
	reg [63:0] rd;
	reg [32:0] s_rs1;
	reg [32:0] s_rs2;
	always @(*) begin
		if (instr_mulh || instr_mulhsu) begin
			s_rs1 <= $signed(pcpi_rs1);
		end else begin
			s_rs1 <= $unsigned(pcpi_rs1);
		end
		if (instr_mulh) begin
			s_rs2 <= $signed(pcpi_rs2);
		end else begin
			s_rs2 <= $unsigned(pcpi_rs2);
		end
	end
	always @(posedge clk) begin
		if (reset) begin
			rd<=0;
		end else begin
			rd <= $signed(s_rs1) * $signed(s_rs2);
		end
	end
`else
	//use DSP slices for fast multiply
	wire [63:0] rd;
	ecp5_dspmul32x32 mul(
		.CLK0(clk), 
		.CE0(active!=0),
		.RST0(reset),
		.SignA(instr_mul|instr_mulh|instr_mulhsu),
		.SignB(instr_mul|instr_mulh), 
		.A(pcpi_rs1),
		.B(pcpi_rs2),
		.P(rd)
	);
`endif

	reg [3:0] active;

	always @(posedge clk) begin
		if (reset) begin
			active <= 'h0;
		end else begin
			active[0] <= 0;
			if (active==0 && any_mul_ins) begin
				active[0] <= 1;
			end
			active[3:1] <= active[2:0];
		end
	end

	assign pcpi_ready = active[3];
	assign pcpi_wait = 0; //we can handle this within 16 cycles
	assign pcpi_wr = pcpi_ready;
	assign pcpi_rd = shift_out ?  rd[63:32] : rd[31:0];
endmodule
