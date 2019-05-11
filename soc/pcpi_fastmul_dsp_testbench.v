`timescale 1us/1ns

module stimulus();

reg clk, rst;

reg pcpi_valid;
reg [31:0] pcpi_insn;
reg [31:0] pcpi_rs1;
reg [31:0] pcpi_rs2;
wire [31:0] pcpi_rd_fastmul;
wire [31:0] pcpi_rd_orig;
wire pcpi_ready_fastmul;
wire pcpi_ready_orig;

pcpi_fastmul_dsp fastmul (
	.clk(clk),
	.reset(rst),
	.pcpi_valid(pcpi_valid),
	.pcpi_insn(pcpi_insn),
	.pcpi_rs1(pcpi_rs1),
	.pcpi_rs2(pcpi_rs2),
	.pcpi_rd(pcpi_rd_fastmul),
	.pcpi_ready(pcpi_ready_fastmul)
);

picorv32_pcpi_fast_mul rv32fastmul (
	.clk(clk),
	.resetn(!rst),
	.pcpi_valid(pcpi_valid),
	.pcpi_insn(pcpi_insn),
	.pcpi_rs1(pcpi_rs1),
	.pcpi_rs2(pcpi_rs2),
	.pcpi_rd(pcpi_rd_orig),
	.pcpi_ready(pcpi_ready_orig)
);

//clock toggle
always #0.5 clk = !clk;

reg [31:0] stimuli [0:10240]; 

integer i;
integer j;
integer k;
reg [31:0] res_a;
reg [31:0] res_b;
initial begin
	$dumpfile("pcpi_fastmul_dsp_testbench.vcd");
	$dumpvars(0, stimulus);
	$readmemh("pcpi_fastmul_dsp_stimuli.hex", stimuli);

	clk <= 0;
	rst<=1;
	pcpi_valid<=0;
	pcpi_insn<=0;
	pcpi_insn[6:0]<=7'b0110011;
	pcpi_insn[31:25]<=7'b0000001;
	#4 rst<=0;
	

	for (i=0; i<10240; i=i+2) begin
		for (k=0; k<4; k=k+1) begin
			pcpi_insn[14:12]<=k;
			pcpi_rs1=stimuli[i];
			pcpi_rs2=stimuli[i+1];
			pcpi_valid <= 1;
			#3;
			if (pcpi_rd_fastmul != pcpi_rd_orig) begin
				$display("Result mismatch! %d Insn %d %X x %X fast %X good %X", i, k, pcpi_rs1, pcpi_rs2, pcpi_rd_fastmul, pcpi_rd_orig);
			end
			pcpi_valid <= 0;
			#1;
		end
	end
	$finish;
end



endmodule