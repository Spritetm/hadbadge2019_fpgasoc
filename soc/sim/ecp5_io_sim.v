module TRELLIS_IO #(
	parameter DIR = "BIDIR"
) (
	input I,
	input T,
	inout B,
	output O
);

assign B = T ? 'hZ : I;
assign O = T ? B : I;

endmodule


module OFS1P3DX (
	input D,
	input SP,
	input SCLK,
	input CD,
	output reg Q
);

	always @(posedge SCLK, posedge CD) begin
		if (CD) begin
			Q<=0;
		end else if (SP) begin
			Q<=D;
		end
	end

endmodule


module ODDRX1F (
	input  wire D0,
	input  wire D1,
	input  wire RST,
	input  wire SCLK,
	output wire Q
);

	reg Q0_r, Q0_rr, Q_pe;
	reg Q1_r, Q1_rr, Q_ne;

	// First layer of register
	always @(posedge SCLK, posedge RST)
	begin
		if (RST) begin
			Q0_r <= 1'b0;
			Q1_r <= 1'b0;
		end else begin
			Q0_r <= D0;
			Q1_r <= D1;
		end
	end

	// Second layer
	always @(posedge SCLK, posedge RST)
	begin
		if (RST) begin
			Q0_rr <= 1'b0;
			Q1_rr <= 1'b0;
		end else begin
			Q0_rr <= Q0_r;
			Q1_rr <= Q1_r;
		end
	end

	// Final layer
	always @(negedge SCLK, posedge RST)
		if (RST)
			Q_pe <= 1'b0;
		else
			Q_pe <= Q0_rr;

	always @(posedge SCLK, posedge RST)
		if (RST)
			Q_ne <= 1'b0;
		else
			Q_ne <= Q1_rr;

	// Output mux
	assign Q = SCLK ? Q_pe : Q_ne;

endmodule


module IFS1P3DX (
	input D,
	input SP,
	input SCLK,
	input CD,
	output reg Q
);

	always @(posedge SCLK, posedge CD) begin
		if (CD) begin
			Q<=0;
		end else if (SP) begin
			Q<=D;
		end
	end

endmodule


module IDDRX1F (
	input  wire D,
	output reg  Q0,
	output reg  Q1,
	input  wire SCLK,
	input  wire RST
);

	reg D_pe;
	reg D_ne;

	always @(posedge SCLK, posedge RST)
		if (RST)
			D_pe <= 1'b0;
		else
			D_pe <= D;

	always @(negedge SCLK, posedge RST)
		if (RST)
			D_ne <= 1'b0;
		else
			D_ne <= D;

	always @(posedge SCLK, posedge RST)
	begin
		if (RST) begin
			Q0 <= 1'b0;
			Q1 <= 1'b0;
		end else begin
			Q0 <= D_pe;
			Q1 <= D_ne;
		end
	end

endmodule;
