/*
Top module for SoC.
*/

module soc(
		input clk48m, 
		input [7:0] btn, 
		output [5:0] led,
		output [27:0] genio,
		output uart_tx,
		input uart_rx,
		output pwmout,
		output [17:0] lcd_db,
		output lcd_rd,
		output lcd_wr,
		output lcd_rs,
		output lcd_cs,
		input lcd_id,
		output lcd_rst,
		input lcd_fmark,
		output lcd_blen,
		output psrama_nce,
		output psrama_sclk,
		input [3:0] psrama_sin,
		output [3:0] psrama_sout,
		output psrama_oe,
		output psramb_nce,
		output psramb_sclk,
		input [3:0] psramb_sin,
		output [3:0] psramb_sout,
		output psramb_oe
	);

	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;
	wire rst = !resetn;
	always @(posedge clk48m) begin
		if (btn[7]) begin
			if (!resetn) reset_cnt <= reset_cnt + 1;
		end else begin
			reset_cnt <= 0;
		end
	end

	wire mem_ready;
	wire mem_ren;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	reg [31:0] mem_rdata;
	wire mem_valid;
	reg [31:0] irq;
	reg [5:0] led;
	reg [7:0] psrama_ovr;
	reg [7:0] psramb_ovr;


/* verilator lint_off PINMISSING */

	`define SLICE_32(v, i) v[32*i+:32]
	`define SLICE_4(v, i) v[4*i+:4]

	parameter integer MASTERCNT = 1;
	wire [32*MASTERCNT-1:0] arb_addr;
	wire [32*MASTERCNT-1:0] arb_wdata;
	wire [32*MASTERCNT-1:0] arb_rdata;
	wire [MASTERCNT-1:0] arb_valid;
	wire [4*MASTERCNT-1:0] arb_wstrb;
	wire [MASTERCNT-1:0] arb_ready;
	wire [MASTERCNT-1:0] cpu_resetn_gated;
	reg [MASTERCNT-1:0] cpu_resetn;
	wire[31:0] arb_currcpu;
	assign cpu_resetn_gated = (rst ? 'h0 : cpu_resetn);

	wire [MASTERCNT-1:0] pcpi_valid;
	wire [MASTERCNT-1:0] pcpi_wait;
	wire [MASTERCNT-1:0] pcpi_wr;
	wire [MASTERCNT-1:0] pcpi_ready;
	wire [31:0] pcpi_insn [0:MASTERCNT-1] ;
	wire [31:0] pcpi_rs1 [0:MASTERCNT-1] ;
	wire [31:0] pcpi_rs2 [0:MASTERCNT-1] ;
	wire [31:0] pcpi_rd [0:MASTERCNT-1] ;

	genvar i;
	for (i=0; i<MASTERCNT; i=i+1) begin : gencpus
		picorv32 #(
			.STACKADDR('h407ffffc-'h100*i), /* top of 8MByte PSRAM */
			.PROGADDR_RESET('h40000000),
			.PROGADDR_IRQ ('h40000010),
			.TWO_STAGE_SHIFT(0),
			.BARREL_SHIFTER(1),
			.ENABLE_COUNTERS(0),
			.ENABLE_COUNTERS64(0),
			.ENABLE_REGS_16_31(1),
			.ENABLE_REGS_DUALPORT(1),
			.ENABLE_MUL(0),
			.ENABLE_FAST_MUL(0),
			.ENABLE_DIV(1),
			.ENABLE_IRQ(1),
			.ENABLE_IRQ_QREGS(1),
			.TWO_CYCLE_COMPARE(0),
			.TWO_CYCLE_ALU(0),
			.COMPRESSED_ISA(1),
			.CATCH_MISALIGN(1),
			.CATCH_ILLINSN(1),
			.ENABLE_PCPI(1),
			.ENABLE_IRQ_TIMER(1),
			.ENABLE_TRACE(0),
			.REGS_INIT_ZERO(0),
			.MASKED_IRQ(0),
			.LATCHED_IRQ('b11111111)
		) cpu (
			.clk         (clk48m     ),
//			.resetn      (cpu_resetn[i] ),
			.resetn      (resetn ),
			.mem_valid   (arb_valid[i]  ),
			.mem_ready   (arb_ready[i]  ),
			.mem_addr    (`SLICE_32(arb_addr, i)   ),
			.mem_wdata   (`SLICE_32(arb_wdata, i)  ),
			.mem_wstrb   (`SLICE_4(arb_wstrb, i)  ),
			.mem_rdata   (`SLICE_32(arb_rdata, i)  ),
			.irq         (irq        ),

                       .pcpi_wait(0),
                       .pcpi_wr(0),
                       .pcpi_ready(0),
                       .pcpi_rd(0)

/*
			.pcpi_valid(pcpi_valid[i]),
			.pcpi_insn(pcpi_insn[i]),
			.pcpi_rs1(pcpi_rs1[i]),
			.pcpi_rs2(pcpi_rs2[i]),
			.pcpi_wr(pcpi_wr[i]),
			.pcpi_rd(pcpi_rd[i]),
			.pcpi_wait(pcpi_wait[i]),
			.pcpi_ready(pcpi_ready[i])
*/
		);

		pcpi_fastmul_dsp fastmul(
			.clk(clk48m),
			.reset(!cpu_resetn[i]),
			.pcpi_valid(pcpi_valid[i]),
			.pcpi_insn(pcpi_insn[i]),
			.pcpi_rs1(pcpi_rs1[i]),
			.pcpi_rs2(pcpi_rs2[i]),
			.pcpi_wr(pcpi_wr[i]),
			.pcpi_rd(pcpi_rd[i]),
			.pcpi_wait(pcpi_wait[i]),
			.pcpi_ready(pcpi_ready[i])
		);
	end

/* verilator lint_on PINMISSING */


	arbiter #(
		.MASTER_IFACE_CNT(2)
	) arb (
		.clk(clk48m),
		.reset(rst),
		.s_addr(mem_addr),
		.s_wdata(mem_wdata),
		.s_rdata(mem_rdata),
		.s_valid(mem_valid),
		.s_wen(mem_wstrb),
		.s_ready(mem_ready),

		.addr(arb_addr),
		.wdata(arb_wdata),
		.rdata(arb_rdata),
		.valid(arb_valid),
		.wen(arb_wstrb),
		.ready(arb_ready),
		.currmaster(arb_currcpu)
	);

	reg mem_select;
	reg uart_div_select;
	reg uart_dat_select;
	reg led_select;
	wire[31:0] ram_rdata;
	wire[31:0] uart_reg_div_do;
	wire[31:0] uart_reg_dat_do;
	wire uart_reg_dat_wait;
	reg ram_ready;
	wire [31:0] lcd_rdata;
	reg lcd_select;
	wire lcd_ready;
	reg bus_error;

	wire [31:0] soc_version;
`ifdef verilator
	assign soc_version = 'h8000;
`else
	assign soc_version = 'h0000;
`endif

	always @(*) begin
		mem_select = 0;
		uart_div_select = 0;
		uart_dat_select = 0;
		led_select = 0;
		lcd_select = 0;
		bus_error = 0;
		mem_rdata = 'hx;
		if (mem_addr[31:28]=='h4) begin
			mem_select = mem_valid;
			mem_rdata = ram_rdata;
		end else if (mem_addr[31:28]=='h1) begin
			if (mem_addr[2]==0) begin
				uart_dat_select = mem_valid;
				mem_rdata = uart_reg_dat_do;
			end else begin
				uart_div_select = mem_valid;
				mem_rdata = uart_reg_div_do;
			end
		end else if (mem_addr[31:28]=='h2) begin
			led_select = mem_valid;
			if (mem_addr[3:2]==0) begin
				mem_rdata = soc_version;
			end else if (mem_addr[3:2]==1) begin
				mem_rdata=arb_currcpu;
			end
			//todo: led/psram/... readback
		end else if (mem_addr[31:28]=='h3) begin
			lcd_select = mem_valid;
			mem_rdata = lcd_rdata;
		end else begin
			//Bus error. Raise IRQ if memory is accessed.
			mem_rdata = 'hDEADBEEF;
			bus_error = mem_valid;
		end
	end

`ifdef verilator
	//Catch stray ready signals when dev is not selected
	always @(posedge clk48m) begin
		assert(mem_select || !ram_ready) else $error("Ram is ready when not selected!");
		assert(lcd_select || !lcd_ready) else $error("LCD peri is ready when not selected!");
	end
`endif

	assign mem_ready = ram_ready || uart_div_select || led_select || (uart_dat_select && !uart_reg_dat_wait) || lcd_ready || bus_error;

	lcdiface lcdiface(
		.clk(clk48m),
		.nrst(resetn),
		.addr(mem_addr[4:2]),
		.wen(lcd_select && mem_wstrb==4'b1111),
		.ren(lcd_select && mem_wstrb==4'b0000),
		.rdata(lcd_rdata),
		.wdata(mem_wdata),
		.ready(lcd_ready),

		.lcd_db(lcd_db),
		.lcd_rd(lcd_rd),
		.lcd_wr(lcd_wr),
		.lcd_rs(lcd_rs),
		.lcd_cs(lcd_cs),
		.lcd_id(lcd_id),
		.lcd_rst(lcd_rst),
		.lcd_fmark(lcd_fmark),
		.lcd_blen(lcd_blen)
	);


	simpleuart simpleuart (
		.clk         (clk48m      ),
		.resetn      (resetn      ),

		.ser_tx      (uart_tx    ),
		.ser_rx      (uart_rx      ),

		.reg_div_we  (uart_div_select ? mem_wstrb : 4'b 0000),
		.reg_div_di  (mem_wdata),
		.reg_div_do  (uart_reg_div_do),

		.reg_dat_we  (uart_dat_select ? mem_wstrb[0] : 1'b 0),
		.reg_dat_re  (uart_dat_select && mem_wstrb==0),
		.reg_dat_di  (mem_wdata),
		.reg_dat_do  (uart_reg_dat_do),
		.reg_dat_wait(uart_reg_dat_wait)
	);

	wire qpi_do_read, qpi_do_write;
	reg qpi_next_byte;
	wire [23:0] qpi_addr;
	reg [31:0] qpi_rdata;
	wire [31:0] qpi_wdata;
	reg qpi_is_idle;

	//16 words * 256 lines = 4K words = 16K bytes. Each way can contain 8KByte.
	//NOTE: Psram needs to have /CE low for at max 5 uS.
	//At 48MHz, this is 240 clock cycles... given 14 cycles setup time (for qpi read),
	//that is a max cache line of 113 bytes or 28 words.
	qpimem_cache #(
		.CACHELINE_WORDS(16),
		.CACHELINE_CT(256),
		.ADDR_WIDTH(22) //addresses words
	) qpimem_cache (
		.clk(clk48m),
		.rst(rst),
		
		.qpi_do_read(qpi_do_read),
		.qpi_do_write(qpi_do_write),
		.qpi_next_byte(qpi_next_byte),
		.qpi_addr(qpi_addr),
		.qpi_wdata(qpi_wdata),
		.qpi_rdata(qpi_rdata),
		.qpi_is_idle(qpi_is_idle),
	
		.wen((mem_valid && !mem_ready && mem_select) ? mem_wstrb : 4'b0),
		.ren(mem_valid && !mem_ready && mem_select && mem_wstrb==0),
		.addr(mem_addr[23:2]),
		.wdata(mem_wdata),
		.rdata(ram_rdata),
		.ready(ram_ready)
	);

	wire qpsrama_sclk;
	wire qpsrama_nce;
	wire [3:0] qpsrama_sout;
	wire qpsrama_oe;

	qpimem_iface qpimem_iface(
		.clk(clk48m),
		.rst(rst),
		
		.do_read(qpi_do_read),
		.do_write(qpi_do_write),
		.next_byte(qpi_next_byte),
		.addr(qpi_addr),
		.wdata(qpi_wdata),
		.rdata(qpi_rdata),
		.is_idle(qpi_is_idle),

		.spi_clk(qpsrama_sclk),
		.spi_ncs(qpsrama_nce),
		.spi_sout(qpsrama_sout),
		.spi_sin(psrama_sin),
		.spi_oe(qpsrama_oe)
	);

	wire psrama_override;
	assign psrama_override=psrama_ovr[7];
	assign psrama_oe = psrama_override ? psrama_ovr[6] : qpsrama_oe;
	assign psrama_sclk = psrama_override ? psrama_ovr[5] : qpsrama_sclk;
	assign psrama_nce = psrama_override ? psrama_ovr[4] : qpsrama_nce;
	assign psrama_sout = psrama_override ? psrama_ovr[3:0] : qpsrama_sout;

	always @(posedge clk48m) begin
		if (rst) begin
			led <= 0;
			psrama_ovr <= 0;
			psramb_ovr <= 0;
			cpu_resetn <= 1;
		end else if (led_select && mem_wstrb[0]) begin
			if (mem_addr[4:2]==0) begin
				led <= mem_wdata[5:0];
			end else if (mem_addr[4:2]==1) begin
				psrama_ovr <= mem_wdata;
			end else if (mem_addr[4:2]==2) begin
				psramb_ovr <= mem_wdata;
			end else if (mem_addr[4:2]==3) begin
				cpu_resetn[1] <= mem_wdata[1];
			end
		end
	end

/*
IRQs used:
0 - Timer interrupt (internal to PicoRV32)
1 - EBREAK, ECALL, illegal inst (internal to PicoRV32)
2 - Unaligned memory access (internal to PicoRV32)
3 - Bus error - not decoded (e.g. dereferenced NULL)
*/

	//Interrupt logic
	always @(posedge clk48m) begin
		irq <= 'h0;
		if (bus_error) begin
			irq[3] <= 1;
		end
	end

	reg [7:0] dbgval;
	reg [15:0] my_dbgdata;
	always @(posedge clk48m) begin
		if (rst) begin
			dbgval<=0;
		end else begin
			if (mem_addr == 'h40000010) begin
				dbgval<='hff;
			end else begin
				if (dbgval!=0) begin
					dbgval <= dbgval - 1;
				end
			end
//			my_dbgdata <= ram_rdata[15:0];
			my_dbgdata <= mem_addr[31:16];
		end
	end
	
//	assign genio[15:0]={mem_addr[31:17], bus_error};//my_dbgdata;
	assign genio[15:0]={mem_addr[15:1], bus_error};//my_dbgdata;
	assign genio[16]=(dbgval!=0);
	assign genio[17]=bus_error;
	assign genio[27:18]='h0;
	
	//Unused pins
	assign pwmout = 0;
	assign psramb_sclk = 0;
	assign psramb_nce = 0;
	assign psramb_sclk = 0;
	assign psramb_oe = 0;
	assign psramb_sout = 0;
endmodule
