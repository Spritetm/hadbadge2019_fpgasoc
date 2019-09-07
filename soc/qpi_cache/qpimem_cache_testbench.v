`timescale 1us/1ns

module stimulus();

reg clk, rst;
wire qpi_do_read, qpi_do_write;
reg qpi_next_word;
wire [23:0] qpi_addr;
reg [31:0] qpi_rdata;
wire [31:0] qpi_wdata;
reg qpi_is_idle;

reg [21:0] addr;
reg [3:0] wen;
reg ren;
reg [31:0] wdata;
wire [31:0] rdata;
wire ready;

qpimem_cache #(
		.CACHELINE_WORDS(4),
		.CACHELINE_CT(256),
		.ADDR_WIDTH(22) //addresses words
) qpimem_cache (
	.clk(clk),
	.rst(rst),
	
	.qpi_do_read(qpi_do_read),
	.qpi_do_write(qpi_do_write),
	.qpi_next_word(qpi_next_word),
	.qpi_addr(qpi_addr),
	.qpi_wdata(qpi_wdata),
	.qpi_rdata(qpi_rdata),
	.qpi_is_idle(qpi_is_idle),

	.addr(addr),
	.wen(wen),
	.ren(ren),
	.wdata(wdata),
	.rdata(rdata),
	.ready(ready)
);

//clock toggle
always #0.5 clk = !clk;

always @(posedge clk) begin
	if (qpi_do_read || qpi_do_write) begin
		qpi_is_idle <= 0;
		#4 qpi_rdata <= qpi_addr;
		qpi_next_word <= 1;
		#1 qpi_next_word <= 0;
	end else begin
		qpi_is_idle <= 1;
	end
end

integer i;
initial begin
	$dumpfile("qpimem_cache_testbench.vcd");
	$dumpvars(0, stimulus);

	qpi_is_idle <= 1;
	qpi_next_word <= 0;
	qpi_rdata <= 0;
	addr <= 0;
	wen <= 0;
	ren <= 0;
	wdata <= 0;
	rst <= 1;
	clk <= 1;
	
	#2 rst <= 0;
	
	//Load cache line 0, way 0, and dirty
	#1 wdata <= 'h12345678;
	#1 addr <= 'h0000;
	wen <= 'hf;
	#1 while (!ready) #1;
	wen <= 0;

	//Load cache line 0, way 1
	#1 addr <= 'h1000;
	ren <= 1;
	#1 while (!ready) #1;
	ren <= 0;

	//Load cache line 0 way 0; cause a writeback of address 0
	#1 addr <= 'h2000;
	ren <= 1;
	#1 while (!ready) #1;
	ren <= 0;

	//Load cache line 0 way 1 with the previously written-back data at addr 0
	#1 addr <= 'h0000;
	ren <= 1;
	#1 while (!ready) #1;
	ren <= 0;

	#200 $finish;
end



endmodule