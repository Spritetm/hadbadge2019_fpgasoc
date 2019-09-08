`timescale 1us/1ns

module stimulus();

reg clk, rst;
reg do_read, do_write;
wire next_word;
reg [23:0] addr;
wire [31:0] rdata;
reg [31:0] wdata;

wire is_idle;

wire spi_clk_a, spi_ncs_a;
wire [3:0] spi_sout_a;
wire [3:0] spi_sin_a;
wire spi_oe_a, spi_bus_qpi_a;

wire spi_clk_b, spi_ncs_b;
wire [3:0] spi_sout_b;
wire [3:0] spi_sin_b;
wire spi_oe_b, spi_bus_qpi_b;

qpimem_iface_intl qpimem_iface_intl(
	.clk(clk),
	.rst(rst),
	
	.do_read(do_read),
	.do_write(do_write),
	.next_word(next_word),
	.addr(addr),
	.wdata(wdata),
	.rdata(rdata),
	.is_idle(is_idle),

	.spi_clk(spi_clk),
	.spi_ncs(spi_ncs),
	.spi_sout_a(spi_sout_a),
	.spi_sin_a(spi_sin_a),
	.spi_sout_b(spi_sout_b),
	.spi_sin_b(spi_sin_b),
	.spi_bus_qpi(spi_bus_qpi),
	.spi_oe(spi_oe)

);

spiram spiram_a (
	.spi_clk(spi_clk),
	.spi_ncs(spi_ncs),
	.spi_sin(spi_sout_a),
	.spi_sout(spi_sin_a),
	.spi_oe(spi_oe)
);

spiram spiram_b (
	.spi_clk(spi_clk),
	.spi_ncs(spi_ncs),
	.spi_sin(spi_sout_b),
	.spi_sout(spi_sin_b),
	.spi_oe(spi_oe)
);


//clock toggle
always #0.5 clk = !clk;

integer i;
initial begin
	$dumpfile("qpimem_interleave_testbench.vcd");
	$dumpvars(0, stimulus);
	do_read <= 0;
	do_write <= 0;
	addr <= 0;
	wdata <= 0;
	clk <= 0;

	rst = 1;
	#5 rst = 0;
	#5 addr <= 'h1000;
	do_write <= 1;
	wdata <= 'h01020304;
	#1 while (!next_word) #1;
	wdata <= 'h05060708;
	#1 while (!next_word) #1;
	wdata <= 'h090A0B0C;
	#1 while (!next_word) #1;
	wdata <= 'h0D0E0F10;
	#1 do_write <= 0;
	while (!is_idle) #1;

	#5 addr <= 'h1010;
	do_write <= 1;
	wdata <= 'h11121314;
	#1 while (!next_word) #1;
	wdata <= 'h15161718;
	#1 while (!next_word) #1;
	#1 do_write <= 0;
	while (!is_idle) #1;

	addr <= 'h1000;
	do_read <= 1;
	#1 while (!next_word) #1;
	$display("%h", rdata);
	#1 while (!next_word) #1;
	$display("%h", rdata);
	#1 while (!next_word) #1;
	$display("%h", rdata);
	#1 while (!next_word) #1;
	$display("%h", rdata);
	#1 while (!next_word) #1;
	$display("%h", rdata);
	#1 while (!next_word) #1;
	$display("%h", rdata);
	#1 while (!next_word) #1;
	$display("%h", rdata);
	#1 while (!next_word) #1;
	$display("%h", rdata);
	do_read <= 0;
	while (!is_idle) #1;

	#10 $finish;
end


endmodule