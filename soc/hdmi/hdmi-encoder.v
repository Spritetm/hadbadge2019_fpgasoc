module hdmi_encoder (
	input clk_8m,
	output [3:0] gpdi_dp, gpdi_dn,
	
	output pixelclk,
	output fetch_next,
	input [7:0] red,
	input [7:0] green,
	input [7:0] blue,
	output next_line,
	output next_field
);

	parameter C_ddr = 1'b1; // 0:SDR 1:DDR
	
	// clock generator
	wire clk_250MHz, clk_125MHz, clk_25MHz, clk_locked;
	clk_8_250_125_25
	clock_instance (
		.clki(clk_8m),
		.clko(clk_250MHz),
		.clks1(clk_125MHz),
		.clks2(clk_25MHz),
		.locked(clk_locked)
	);
	
	// shift clock choice SDR/DDR
	wire clk_pixel, clk_shift;
	assign clk_pixel = clk_25MHz;
	assign pixelclk = clk_25MHz;
	generate
	  if(C_ddr == 1'b1)
		assign clk_shift = clk_125MHz;
	  else
		assign clk_shift = clk_250MHz;
	endgenerate

	// VGA signal generator
	wire [7:0] vga_r, vga_g, vga_b;
	wire vga_hsync, vga_vsync, vga_blank;
	assign hsync = vga_hsync;
	assign vsync = vga_vsync;
	vga vga_instance (
		.clk_pixel(clk_pixel),
		.test_picture(1'b0), // enable test picture generation
		.vga_r(vga_r),
		.vga_g(vga_g),
		.vga_b(vga_b),
		.fetch_next(fetch_next),
		.red_byte(red),
		.green_byte(green),
		.blue_byte(blue),
		.next_line(next_line),
		.next_field(next_field),
		.vga_hsync(vga_hsync),
		.vga_vsync(vga_vsync),
		.vga_blank(vga_blank)
	);

	// VGA to digital video converter
	wire [1:0] tmds[3:0];
	vga2dvid #(
		.C_ddr(C_ddr)
	) vga2dvid_instance (
		.clk_pixel(clk_pixel),
		.clk_shift(clk_shift),
		.in_red(vga_r),
		.in_green(vga_g),
		.in_blue(vga_b),
		.in_hsync(vga_hsync),
		.in_vsync(vga_vsync),
		.in_blank(vga_blank),
		.out_clock(tmds[3]),
		.out_red(tmds[2]),
		.out_green(tmds[1]),
		.out_blue(tmds[0])
	);

	// output TMDS SDR/DDR data to fake differential lanes
	fake_differential #(
		.C_ddr(C_ddr)
	) fake_differential_instance (
		.clk_shift(clk_shift),
		.in_clock(tmds[3]),
		.in_red(tmds[2]),
		.in_green(tmds[1]),
		.in_blue(tmds[0]),
		.out_p(gpdi_dp),
		.out_n(gpdi_dn)
	);

endmodule
