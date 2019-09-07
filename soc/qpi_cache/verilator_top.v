`timescale 1us/1ns

module qpitest(
	input clk,
	input rst,
	
	input [21:0] addr,
	input [31:0] wdata,
	output [31:0] rdata,
	input [3:0] wen,
	input ren,
	input flush,
	output ready,

	output spi_clk,
	output spi_ncs,
	output [3:0] spi_sout,
	input [3:0] spi_sin,
	output spi_oe,
	output spi_bus_qpi
);

wire qpi_do_read, qpi_do_write;
reg qpi_next_word;
wire [23:0] qpi_addr;
reg [31:0] qpi_rdata;
wire [31:0] qpi_wdata;
reg qpi_is_idle;


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
	.flush(flush),
	.wdata(wdata),
	.rdata(rdata),
	.ready(ready)
);

qpimem_iface qpimem_iface(
	.clk(clk),
	.rst(rst),
	
	.do_read(qpi_do_read),
	.do_write(qpi_do_write),
	.next_word(qpi_next_word),
	.addr(qpi_addr),
	.wdata(qpi_wdata),
	.rdata(qpi_rdata),
	.is_idle(qpi_is_idle),

	.spi_xfer_wdata(spi_xfer_wdata),
	.spi_xfer_rdata(spi_xfer_rdata),
	.do_spi_xfer(do_spi_xfer),
	.spi_xfer_claim(spi_xfer_claim),
	.spi_xfer_idle(spi_xfer_idle),

	.spi_clk(spi_clk),
	.spi_ncs(spi_ncs),
	.spi_sout(spi_sout),
	.spi_sin(spi_sin),
	.spi_bus_qpi(spi_bus_qpi),
	.spi_oe(spi_oe)
);


endmodule