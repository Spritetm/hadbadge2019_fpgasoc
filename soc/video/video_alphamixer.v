module video_alphamixer(
	input [31:0] in_a,
	input [31:0] in_b,
	input [7:0] rate,
	output [31:0] out
);

wire [35:0] mulr_out_a[0:3];
wire [35:0] mulr_out_b[0:3];
reg [8:0] alpha_a;
reg [8:0] alpha_b;

always @(*) begin
	if (rate=='hff) begin
		//Hack because otherwise we can never get 100% dst
		alpha_a = 'h100;
		alpha_b = 0;
	end else begin
		alpha_a = rate;
		alpha_b = ('h100 - rate);
	end
end

genvar i;
for (i=0; i<4; i++) begin
	mul_18x18 mult_s (
		.a({10'h0, in_a[i*8+:8]}),
		.b({10'h0, alpha_a}),
		.dout(mulr_out_a[i])
	);
	mul_18x18 mult_d (
		.a({10'h0, in_b[i*8+:8]}),
		.b({10'h0, alpha_b}),
		.dout(mulr_out_b[i])
	);
	assign out[i*8+:8] = mulr_out_a[i][15:8]+mulr_out_b[i][15:8];
end

endmodule