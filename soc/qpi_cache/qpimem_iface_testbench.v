/*
 * Copyright (C) 2019  Jeroen Domburg <jeroen@spritesmods.com>
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
`timescale 1us/1ns

module stimulus();

reg clk, rst;
reg do_read, do_write;
wire next_word;
reg [24:0] addr;
wire [31:0] rdata;
reg [31:0] wdata;

wire spi_clk, spi_ncs, is_idle;
wire [3:0] spi_sout;
wire [3:0] spi_sin;
wire spi_oe, spi_bus_qpi;

reg [7:0] spi_xfer_wdata;
wire [7:0] spi_xfer_rdata;
reg do_spi_xfer;
wire spi_xfer_idle;
reg spi_xfer_claim;

qpimem_iface qpimem_iface(
	.clk(clk),
	.rst(rst),
	
	.do_read(do_read),
	.do_write(do_write),
	.next_word(next_word),
	.addr(addr),
	.wdata(wdata),
	.rdata(rdata),
	.is_idle(is_idle),

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

spiram spiram (
	.spi_clk(spi_clk),
	.spi_ncs(spi_ncs),
	.spi_sin(spi_sout),
	.spi_sout(spi_sin),
	.spi_oe(spi_oe)
);

//clock toggle
always #0.5 clk = !clk;

integer i;
initial begin
	$dumpfile("qpimem_iface_testbench.vcd");
	$dumpvars(0, stimulus);
	do_read <= 0;
	do_write <= 0;
	addr <= 0;
	wdata <= 0;
	clk <= 0;
	spi_xfer_wdata <= 'hfa;
	do_spi_xfer <= 0;
	spi_xfer_claim <= 0;

	rst = 1;
	#5 rst = 0;
	#5 addr <= 'h123456;
	wdata <= 'h89ABCDEF;
	do_write <= 1;
	while (!next_word) #1;
	wdata <= 'h11223344;
	while (!next_word) #1;
	wdata <= 'hF5667788;
	while (!next_word) #1;
	#1 do_write <= 0;
	while (!is_idle) #1;

	addr <= 'h123456;
	do_read <= 1;
	while (!next_word) #1;
	while (!next_word) #1;
	while (!next_word) #1;
	do_read <= 0;
	while (!is_idle) #1;

	spi_xfer_claim <= 1;
	while (!spi_xfer_idle) #1;
	do_spi_xfer <= 1;
	#1 do_spi_xfer <= 0;
	while (!spi_xfer_idle) #1;
	spi_xfer_wdata <= 'h55;
	do_spi_xfer <= 1;
	#1 do_spi_xfer <= 0;
	spi_xfer_claim <= 0;

	#10 $finish;
end



endmodule