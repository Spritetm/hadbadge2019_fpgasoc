/*
Top module for SoC.
*/

module soc(
		input clk48m,
		input clkint, //internal clock of ecp5, <24MHz, used for rng
		input [7:0] btn, 
		output [8:0] led,
		output uart_tx,
		input uart_rx,
		output irda_tx,
		input irda_rx,
		output reg irda_sd,
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
		output psramb_oe,
		
		output flash_nce,
		output flash_sclk,
		input [3:0] flash_sin,
		output [3:0] flash_sout,
		output flash_oe,
		output flash_bus_qpi,
		output fsel_c,
		output reg fsel_d,
		output programn,
		
		input vid_pixelclk,
		input vid_fetch_next,
		input vid_next_line,
		input vid_next_field,
		output [7:0] vid_red,
		output [7:0] vid_green,
		output [7:0] vid_blue,
		
		output [31:0] dbgreg_out,
		input [31:0] dbgreg_in,
		input dbgreg_strobe,
		input dbgreg_sel,

		inout usb_dp,
		inout usb_dn,
		output usb_pu,
		input usb_vdet,

		output adcrefout,
		input adc4,

		input [29:0] genio_in,
		output reg [29:0] genio_out,
		output reg [29:0] genio_oe,
		input [5:0] sao1_in,
		output reg [5:0] sao1_out,
		output reg [5:0] sao1_oe,
		input [5:0] sao2_in,
		output reg [5:0] sao2_out,
		output reg [5:0] sao2_oe,
		input [7:0] pmod_in,
		output reg [7:0] pmod_out,
		output reg [7:0] pmod_oe,
		
		output reg trace_en
	);


	reg fpga_reload=0;
	assign programn = ~fpga_reload;
	reg [5:0] reset_cnt = 0;
	reg resetn=0;
	wire rst = !resetn;
	always @(posedge clk48m) begin
		if (!resetn) reset_cnt <= reset_cnt + 1;
		resetn <= reset_cnt[5];
	end

	wire mem_ready;
	wire mem_ren;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	reg [31:0] mem_rdata;
	wire mem_valid;
	reg [31:0] irq;
	reg [7:0] psrama_ovr;
	reg [7:0] psramb_ovr;


/* verilator lint_off PINMISSING */

	`define SLICE_32(v, i) v[32*i+:32]
	`define SLICE_4(v, i) v[4*i+:4]

	parameter integer MASTERCNT = 3;
	parameter integer CPUCNT = 2;
	wire [32*MASTERCNT-1:0] arb_addr;
	wire [32*MASTERCNT-1:0] arb_wdata;
	wire [32*MASTERCNT-1:0] arb_rdata;
	wire [MASTERCNT-1:0] arb_valid;
	wire [4*MASTERCNT-1:0] arb_wstrb;
	wire [MASTERCNT-1:0] arb_ready;
	wire [CPUCNT-1:0] cpu_resetn_gated;
	reg [CPUCNT-1:0] cpu_resetn;
	wire[31:0] arb_currcpu;
	assign cpu_resetn_gated = (rst ? 'h0 : cpu_resetn);

	wire [CPUCNT-1:0] pcpi_valid;
	wire [CPUCNT-1:0] pcpi_wait;
	wire [CPUCNT-1:0] pcpi_wr;
	wire [CPUCNT-1:0] pcpi_ready;
	wire [31:0] pcpi_insn [0:CPUCNT-1] ;
	wire [31:0] pcpi_rs1 [0:CPUCNT-1] ;
	wire [31:0] pcpi_rs2 [0:CPUCNT-1] ;
	wire [31:0] pcpi_rd [0:CPUCNT-1] ;

	genvar i;
	for (i=0; i<CPUCNT; i=i+1) begin : gencpus
		picorv32 #(
			.STACKADDR('h407ffefc-'h100*i), /* top of 8MByte PSRAM */
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
			.LATCHED_IRQ('b11111111111111111111111111101111) //0 for level sensitive, 1 for latched
		) cpu (
			.clk         (clk48m     ),
			.resetn      (cpu_resetn_gated[i] ),
			.mem_valid   (arb_valid[i]  ),
			.mem_ready   (arb_ready[i]  ),
			.mem_addr    (`SLICE_32(arb_addr, i)   ),
			.mem_wdata   (`SLICE_32(arb_wdata, i)  ),
			.mem_wstrb   (`SLICE_4(arb_wstrb, i)  ),
			.mem_rdata   (`SLICE_32(arb_rdata, i)  ),
			.irq         (irq        ),

			.pcpi_valid(pcpi_valid[i]),
			.pcpi_insn(pcpi_insn[i]),
			.pcpi_rs1(pcpi_rs1[i]),
			.pcpi_rs2(pcpi_rs2[i]),
			.pcpi_wr(pcpi_wr[i]),
			.pcpi_rd(pcpi_rd[i]),
			.pcpi_wait(pcpi_wait[i]),
			.pcpi_ready(pcpi_ready[i])
		);

		pcpi_fastmul_dsp fastmul(
			.clk(clk48m),
			.reset(!cpu_resetn_gated[i]),
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

	//Final master is to write memory over the JTAG port. It's kinda janky, as JTAG at this point
	//does not have the option to feed back the fact that RAM may be busy. We work around that for
	//now by assuming JTAG is slow enough not to overflow.

	//0x38 = address, 0x32 is data

	parameter integer JTAG_ARB_PRT = CPUCNT;
	reg [31:0] jtag_addr;
	reg jtag_mem_valid;
	assign `SLICE_32(arb_addr, JTAG_ARB_PRT) = jtag_addr;
	assign arb_valid[JTAG_ARB_PRT] = jtag_mem_valid;
	assign `SLICE_4(arb_wstrb, JTAG_ARB_PRT) = 'hf; //write only for now
	reg [32:0] dbgfifo [32:0];
	reg [4:0] dbgfifo_w;
	reg [4:0] dbgfifo_r;
	reg [32:0] dbg_write_data;
	assign `SLICE_32(arb_wdata, JTAG_ARB_PRT) = dbg_write_data;

	always @(posedge clk48m) begin
		if (rst) begin
			jtag_addr <= 0;
			jtag_mem_valid <= 0;
			dbgfifo_r <= 0;
			dbgfifo_w <= 0;
		end else begin
			if (dbgreg_strobe) begin
				dbgfifo[dbgfifo_w] <= {dbgreg_sel, dbgreg_in};
				dbgfifo_w <= dbgfifo_w + 1;
			end else if (jtag_mem_valid) begin
				//Transaction in progress. Wait till it finishes.
				if (arb_ready[JTAG_ARB_PRT]) begin
					jtag_mem_valid <= 0;
					jtag_addr <= jtag_addr + 4;
				end
			end else if (dbgfifo_r != dbgfifo_w) begin
				if (dbgfifo[dbgfifo_r][32]) begin
					jtag_addr <= dbgfifo[dbgfifo_r][31:0];
				end else begin
					dbg_write_data <= dbgfifo[dbgfifo_r][31:0];
					jtag_mem_valid <= 1;
				end
				dbgfifo_r <= dbgfifo_r + 1;
			end
		end
	end

	arbiter #(
		.MASTER_IFACE_CNT(MASTERCNT)
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
	reg irda_div_select;
	reg irda_dat_select;
	reg misc_select;
	wire[31:0] ram_rdata;
	wire[31:0] uart_reg_div_do;
	wire[31:0] uart_reg_dat_do;
	wire[31:0] irda_reg_div_do;
	wire[31:0] irda_reg_dat_do;
	wire uart_reg_dat_wait;
	wire irda_reg_dat_wait;
	reg ram_ready;
	wire [31:0] lcd_rdata;
	reg lcd_select;
	wire lcd_ready;
	reg bus_error;
	reg linerenderer_select;
	wire [31:0] linerenderer_rdata;
	wire linerenderer_ready;
	wire [31:0] usb_rdata;
	wire usb_ready;
	reg usb_select;
	wire [31:0] pic_rdata;
	wire pic_ready;
	reg pic_select;

	wire [31:0] soc_version;
`ifdef verilator
	assign soc_version = 'h8000;
`else
	assign soc_version = 'h0000;
`endif


	reg flash_claim, flash_xfer;
	wire [7:0] flash_rdata;
	wire flash_idle;
	reg adc_enabled;
	reg [4:0] adc_divider;
	wire adc_valid;
	wire [15:0] adc_value;

	parameter MISC_REG_LED = 0;
	parameter MISC_REG_BTN = 1;
	parameter MISC_REG_SOC_VER = 2;
	parameter MISC_REG_CPU_NO = 3;
	parameter MISC_REG_PSRAMOVR_A = 4; //read will give current CPU ID... ToDo: make that more logical
	parameter MISC_REG_PSRAMOVR_B = 5;
	parameter MISC_REG_RESETN = 6;
	parameter MISC_REG_FLASH_CTL = 7;
	parameter MISC_REG_FLASH_WDATA = 8;
	parameter MISC_REG_FLASH_RDATA = 9;
	parameter MISC_REG_RNG = 10;
	parameter MISC_REG_FLASH_SEL = 11;
	parameter MISC_REG_ADC_CTL = 12;
	parameter MISC_REG_ADC_VAL = 13;
	parameter MISC_REG_GENIO_IN = 14;
	parameter MISC_REG_GENIO_OUT = 15;
	parameter MISC_REG_GENIO_OE = 16;
	parameter MISC_REG_GENIO_W2S = 17;
	parameter MISC_REG_GENIO_W2C = 18;
	parameter MISC_REG_GPEXT_IN = 19;
	parameter MISC_REG_GPEXT_OUT = 20;
	parameter MISC_REG_GPEXT_OE = 21;
	parameter MISC_REG_GPEXT_W2S = 22;
	parameter MISC_REG_GPEXT_W2C = 23;

	wire [31:0] rngno;
	rng rng(
		.clk1(clk48m),
		.clk2(clkint),
		.rst(rst),
		.rngno(rngno)
	);


	always @(*) begin
		mem_select = 0;
		uart_div_select = 0;
		uart_dat_select = 0;
		irda_div_select = 0;
		irda_dat_select = 0;
		misc_select = 0;
		lcd_select = 0;
		usb_select = 0;
		pic_select = 0;
		linerenderer_select=0;
		bus_error = 0;
		mem_rdata = 'hx;
		if (mem_addr[31:28]=='h1) begin
			if (mem_addr[3:2]=='h0) begin
				uart_dat_select = mem_valid;
				mem_rdata = uart_reg_dat_do;
			end else if (mem_addr[3:2]=='h1) begin
				uart_div_select = mem_valid;
				mem_rdata = uart_reg_div_do;
			end else if (mem_addr[3:2]=='h2) begin
				irda_dat_select = mem_valid;
				mem_rdata = irda_reg_dat_do;
			end else if (mem_addr[3:2]=='h3) begin
				irda_div_select = mem_valid;
				mem_rdata = irda_reg_div_do;
			end
		end else if (mem_addr[31:28]=='h2) begin
			misc_select = mem_valid;
			if (mem_addr[6:2]==MISC_REG_LED) begin
				mem_rdata = { 16'h0, pic_led };
			end else if (mem_addr[6:2]==MISC_REG_BTN) begin
				mem_rdata = { 24'h0, ~btn};
			end else if (mem_addr[6:2]==MISC_REG_SOC_VER) begin
				mem_rdata = soc_version;
			end else if (mem_addr[6:2]==MISC_REG_CPU_NO) begin
				mem_rdata = arb_currcpu;
			end else if (mem_addr[6:2]==MISC_REG_PSRAMOVR_A) begin
				mem_rdata = psrama_ovr;
			end else if (mem_addr[6:2]==MISC_REG_PSRAMOVR_B) begin
				mem_rdata = psramb_ovr;
			end else if (mem_addr[6:2]==MISC_REG_FLASH_CTL) begin
				mem_rdata = {30'h0, flash_idle, flash_claim};
			end else if (mem_addr[6:2]==MISC_REG_FLASH_RDATA) begin
				mem_rdata = {24'h0, flash_rdata};
			end else if (mem_addr[6:2]==MISC_REG_RNG) begin
				mem_rdata = rngno;
			end else if (mem_addr[6:2]==MISC_REG_FLASH_SEL) begin
				mem_rdata = {31'h0, fsel_d};
			end else if (mem_addr[6:2]==MISC_REG_ADC_CTL) begin
				mem_rdata = {11'h0, adc_divider, 14'h0, adc_valid, adc_enabled};
			end else if (mem_addr[6:2]==MISC_REG_ADC_VAL) begin
				mem_rdata = adc_value;
			end else if (mem_addr[6:2]==MISC_REG_GENIO_IN) begin
				mem_rdata = {2'h0, genio_in};
			end else if (mem_addr[6:2]==MISC_REG_GENIO_OUT) begin
				mem_rdata = {2'h0, genio_out};
			end else if (mem_addr[6:2]==MISC_REG_GENIO_OE) begin
				mem_rdata = {2'h0, genio_oe};
			end else if (mem_addr[6:2]==MISC_REG_GPEXT_IN) begin
				mem_rdata = {usb_vdet, 7'h0, pmod_in, 2'h0, sao2_in, 2'h0, sao1_in};
			end else if (mem_addr[6:2]==MISC_REG_GPEXT_OUT) begin
				mem_rdata = {1'h0, irda_sd, 6'h0, pmod_out, 2'h0, sao2_out, 2'h0, sao1_out};
			end else if (mem_addr[6:2]==MISC_REG_GPEXT_OE) begin
				mem_rdata = {8'h0, pmod_oe, 2'h0, sao2_oe, 2'h0, sao1_oe};
			end else begin
				mem_rdata = 0;
			end
			//todo: improve misc/psram/... readback
		end else if (mem_addr[31:28]=='h3) begin
			lcd_select = mem_valid;
			mem_rdata = lcd_rdata;
		end else if (mem_addr[31:28]=='h4) begin
			mem_select = mem_valid;
			mem_rdata = ram_rdata;
		end else if (mem_addr[31:28]=='h5) begin
			linerenderer_select = mem_valid;
			mem_rdata = linerenderer_rdata;
		end else if (mem_addr[31:28]=='h6) begin
			usb_select = mem_valid;
			mem_rdata = usb_rdata;
		end else if (mem_addr[31:28]=='h7) begin
			pic_select = mem_valid;
			mem_rdata = pic_rdata;
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

	assign mem_ready = ram_ready || uart_div_select || irda_div_select || misc_select || 
			(uart_dat_select && !uart_reg_dat_wait) || (irda_dat_select && !irda_reg_dat_wait) ||
			lcd_ready || linerenderer_ready || usb_ready || pic_ready || bus_error;

	dsadc dsadc (
		.clk(clk48m),
		.rst(rst || !adc_enabled),
		.difpin(adc4),
		.divider(adc_divider),
		.refout(adcrefout),
		.adcval(adc_value),
		.valid(adc_valid)
	);

	wire [19:0] vidmem_addr;
	wire [23:0] vidmem_data_out;
	wire vidmem_wen, vidmem_ren;
	wire [23:0] vidmem_data_in;
	wire [19:0] curr_vid_addr;

	wire lcdvm_next_pixel;
	wire lcdvm_newfield;
	wire lcdvm_wait;
	wire [7:0] lcdvm_red;
	wire [7:0] lcdvm_green;
	wire [7:0] lcdvm_blue;

	lcdiface lcdiface(
		.clk(clk48m),
		.nrst(resetn),
		.addr(mem_addr[4:2]),
		.wen(lcd_select && mem_wstrb==4'b1111),
		.ren(lcd_select && mem_wstrb==4'b0000),
		.rdata(lcd_rdata),
		.wdata(mem_wdata),
		.ready(lcd_ready),

		.lcdvm_next_pixel(lcdvm_next_pixel),
		.lcdvm_newfield(lcdvm_newfield),
		.lcdvm_wait(lcdvm_wait),
		.lcdvm_red(lcdvm_red),
		.lcdvm_green(lcdvm_green),
		.lcdvm_blue(lcdvm_blue),

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

	wire next_field;
	wire vid_preload;

	video_mem video_mem (
		.clk(clk48m),
		.reset(rst),
		.addr(vidmem_addr),
		.data_in(vidmem_data_in),
		.wen(vidmem_wen),
		.ren(vidmem_ren),
		.data_out(vidmem_data_out),
		.curr_vid_addr(curr_vid_addr),
		.preload(vid_preload),
		.next_field_out(next_field),

		.lcd_next_pixel(lcdvm_next_pixel),
		.lcd_newfield(lcdvm_newfield),
		.lcd_wait(lcdvm_wait),
		.lcd_red(lcdvm_red),
		.lcd_green(lcdvm_green),
		.lcd_blue(lcdvm_blue),

		.pixel_clk(vid_pixelclk),
		.fetch_next(vid_fetch_next),
		.next_line(vid_next_line),
		.next_field(vid_next_field),
		.red(vid_red),
		.green(vid_green),
		.blue(vid_blue)
	);

	wire usb_irq, usb_sof;

	usb_soc usb (
		.clk48m(clk48m),
		.rst(rst),
		.addr(mem_addr),
		.wen(usb_select && mem_wstrb==4'b1111),
		.ren(usb_select && mem_wstrb==4'b0000),
		.dout(usb_rdata),
		.din(mem_wdata),
		.ready(usb_ready),
		.irq(usb_irq),
		.sof(usb_sof),
		.pad_dp(usb_dp),
		.pad_dn(usb_dn),
		.pad_pu(usb_pu)
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

	simpleuart_irda simpleuart_irda (
		.clk         (clk48m      ),
		.resetn      (resetn      ),

		.ser_tx      (irda_tx    ),
		.ser_rx      (irda_rx      ),

		.reg_div_we  (irda_div_select ? mem_wstrb : 4'b 0000),
		.reg_div_di  (mem_wdata),
		.reg_div_do  (irda_reg_div_do),

		.reg_dat_we  (irda_dat_select ? mem_wstrb[0] : 1'b 0),
		.reg_dat_re  (irda_dat_select && mem_wstrb==0),
		.reg_dat_di  (mem_wdata),
		.reg_dat_do  (irda_reg_dat_do),
		.reg_dat_wait(irda_reg_dat_wait)
	);

	reg [15:0] pic_led;
	wire [15:0] pic_led_out;
//	assign led = {pic_led_out[10:8], pic_led_out[5:0]};
	assign led = pic_led;

	pic_wrapper #(
		.ROM_HEX("pic/rom_initial.hex")
	) pic (
		.clk(clk48m),
		.reset(rst),
		.gpio_in(pic_led),
		.gpio_out(pic_led_out),
		.rng(rngno[7:0]),
		.address(mem_addr),
		.data_in(mem_wdata),
		.data_out(pic_rdata),
		.wen(pic_select && mem_wstrb==4'b1111),
		.ren(pic_select && mem_wstrb==4'b0000),
		.ready(pic_ready)
	);

	wire qpi_do_read;
	wire qpi_do_write;
	reg qpi_next_word;
	wire [23:0] qpi_addr;
	reg [31:0] qpi_rdata;
	wire [31:0] qpi_wdata;
	reg qpi_is_idle;

	parameter integer QPI_MASTERCNT = 2;

	wire [32*QPI_MASTERCNT-1:0] qpimem_arb_addr;
	wire [32*QPI_MASTERCNT-1:0] qpimem_arb_wdata;
	wire [32*QPI_MASTERCNT-1:0] qpimem_arb_rdata;
	wire [QPI_MASTERCNT-1:0] qpimem_arb_do_read;
	wire [QPI_MASTERCNT-1:0] qpimem_arb_do_write;
	wire [QPI_MASTERCNT-1:0] qpimem_arb_next_word;
	wire [QPI_MASTERCNT-1:0] qpimem_arb_is_idle;

	qpimem_arbiter #(
		.MASTER_IFACE_CNT(QPI_MASTERCNT)
	) qpi_arb (
		.clk(clk48m),
		.reset(rst),
		
		.addr(qpimem_arb_addr),
		.wdata(qpimem_arb_wdata),
		.rdata(qpimem_arb_rdata),
		.do_read(qpimem_arb_do_read),
		.do_write(qpimem_arb_do_write),
		.next_word(qpimem_arb_next_word),
		.is_idle(qpimem_arb_is_idle),

		.s_addr(qpi_addr),
		.s_wdata(qpi_wdata),
		.s_rdata(qpi_rdata),
		.s_do_write(qpi_do_write),
		.s_do_read(qpi_do_read),
		.s_is_idle(qpi_is_idle),
		.s_next_word(qpi_next_word)
	);

	wire [4:0] mem_wen;
	assign mem_wen = (mem_valid && !mem_ready && mem_select) ? mem_wstrb : 4'b0;

	//16 words * 512 lines = 8K words = 32K bytes. Each way can contain 16KByte.
	//NOTE: Psram needs to have /CE low for at max 5 uS.
	//At 48MHz, this is 240 clock cycles... given 14 cycles setup time (for qpi read),
	//that is a max cache line of 113 bytes or 28 words.
	qpimem_cache #(
		.CACHELINE_WORDS(16),
		.CACHELINE_CT(512),
		.ADDR_WIDTH(22) //addresses words
	) qpimem_cache (
		.clk(clk48m),
		.rst(rst),
		
		.qpi_do_read(qpimem_arb_do_read[0]),
		.qpi_do_write(qpimem_arb_do_write[0]),
		.qpi_next_word(qpimem_arb_next_word[0]),
		.qpi_addr(`SLICE_32(qpimem_arb_addr, 0)),
		.qpi_wdata(`SLICE_32(qpimem_arb_wdata, 0)),
		.qpi_rdata(`SLICE_32(qpimem_arb_rdata, 0)),
		.qpi_is_idle(qpimem_arb_is_idle[0]),
	
		.wen(mem_addr[24]==0 ? mem_wen : 4'b0),
		.ren(mem_valid && !mem_ready && mem_select && mem_wstrb==0),
		.addr(mem_addr[23:2]),
		.flush(mem_addr[24]==1 ? (mem_wen==4'hF) : 1'b0), //some ad-hoc muxing: writing anywhere above 16m does a flush instead.
		.wdata(mem_wdata),
		.rdata(ram_rdata),
		.ready(ram_ready)
	);


	vid_linerenderer linerenderer (
		.clk(clk48m),
		.reset(rst),
		.addr(mem_addr),
		.din(mem_wdata),
		.wstrb(linerenderer_select?mem_wstrb:4'b0000),
		.ren(linerenderer_select && mem_wstrb==4'b0000),
		.dout(linerenderer_rdata),
		.ready(linerenderer_ready),

		.vid_addr(vidmem_addr),
		.preload(vid_preload),
		.vid_data_out(vidmem_data_in),
		.vid_wen(vidmem_wen),
		.vid_ren(vidmem_ren),
		.vid_data_in(vidmem_data_out),
		.curr_vid_addr(curr_vid_addr),
		.next_field(next_field),

		.m_do_read(qpimem_arb_do_read[1]),
		.m_next_word(qpimem_arb_next_word[1]),
		.m_addr(`SLICE_32(qpimem_arb_addr, 1)),
		.m_rdata(`SLICE_32(qpimem_arb_rdata, 1)),
		.m_is_idle(qpimem_arb_is_idle[1])
	);

	//video renderer does not write
	assign qpimem_arb_do_write[1] = 0;
	assign `SLICE_32(qpimem_arb_wdata, 1) = 0;

	wire qpsram_sclk;
	wire qpsram_nce;
	wire [3:0] qpsrama_sout;
	wire [3:0] qpsramb_sout;
	wire qpsram_oe;

	qpimem_iface_intl qpimem_iface_intl(
		.clk(clk48m),
		.rst(rst),
		
		.do_read(qpi_do_read),
		.do_write(qpi_do_write),
		.next_word(qpi_next_word),
		.addr(qpi_addr),
		.wdata(qpi_wdata),
		.rdata(qpi_rdata),
		.is_idle(qpi_is_idle),

		.spi_clk(qpsram_sclk),
		.spi_ncs(qpsram_nce),
		.spi_sout_b(qpsrama_sout),
		.spi_sin_b(psrama_sin),
		.spi_sout_a(qpsramb_sout),
		.spi_sin_a(psramb_sin),
		.spi_oe(qpsram_oe)
	);

	wire psrama_override;
	assign psrama_override=psrama_ovr[7];
	assign psrama_oe = psrama_override ? psrama_ovr[6] : qpsram_oe;
	assign psrama_sclk = psrama_override ? psrama_ovr[5] : qpsram_sclk;
	assign psrama_nce = psrama_override ? psrama_ovr[4] : qpsram_nce;
	assign psrama_sout = psrama_override ? psrama_ovr[3:0] : qpsrama_sout;

	wire psramb_override;
	assign psramb_override=psramb_ovr[7];
	assign psramb_oe = psrama_override ? psramb_ovr[6] : qpsram_oe;
	assign psramb_sclk = psrama_override ? psramb_ovr[5] : qpsram_sclk;
	assign psramb_nce = psrama_override ? psramb_ovr[4] : qpsram_nce;
	assign psramb_sout = psrama_override ? psramb_ovr[3:0] : qpsramb_sout;

	//This is abused as a simple SPI flash interface. We can add qpi reading later.
	qpimem_iface flash_iface(
		.clk(clk48m),
		.rst(rst),
		
		//qpi is not supported yet
		.do_read(0),
		.do_write(0),
		.addr('hX),
		.wdata('hX),

		//no spi transfers supported, we do setup using bitbanging
		.spi_xfer_wdata(mem_wdata[7:0]),
		.spi_xfer_rdata(flash_rdata),
		.do_spi_xfer(flash_xfer),
		.spi_xfer_claim(flash_claim),
		.spi_xfer_idle(flash_idle),

		.spi_clk(flash_sclk),
		.spi_ncs(flash_nce),
		.spi_sout(flash_sout),
		.spi_sin(flash_sin),
		.spi_oe(flash_oe),
		.spi_bus_qpi(flash_bus_qpi)
	);

	reg fsel_strobe;
	reg programn_queue;


	//misc write ops to periphs that have internal register
	always @(*) begin
		flash_xfer <= 0;
		if (misc_select && mem_wstrb[0]) begin
			if (mem_addr[5:2]==MISC_REG_FLASH_WDATA) begin
				flash_xfer <= 1; //also latches spi_wdata of flash
			end
		end
	end


	//misc reg write ops, registered
	always @(posedge clk48m) begin
		if (rst) begin
			pic_led <= 0;
			psrama_ovr <= 0;
			psramb_ovr <= 0;
			cpu_resetn <= 1;
			flash_claim <= 0;
			fsel_strobe <= 0;
			fsel_d <= 0;
			programn_queue <= 0;
			adc_enabled <= 0;
			adc_divider <= 0;
			irda_sd <= 1;
			trace_en <= 0;
		end else begin
			fsel_strobe <= 0;
			if (misc_select && mem_wstrb[0]) begin
				if (mem_addr[6:2]==MISC_REG_LED) begin
					pic_led <= mem_wdata[16:0];
				end else if (mem_addr[6:2]==MISC_REG_SOC_VER) begin
					trace_en <= mem_wdata[0];
				end else if (mem_addr[6:2]==MISC_REG_PSRAMOVR_A) begin
					psrama_ovr <= mem_wdata;
				end else if (mem_addr[6:2]==MISC_REG_PSRAMOVR_B) begin
					psramb_ovr <= mem_wdata;
				end else if (mem_addr[6:2]==MISC_REG_RESETN) begin
					cpu_resetn[1] <= mem_wdata[1];
				end else if (mem_addr[6:2]==MISC_REG_FLASH_CTL) begin
					flash_claim <= mem_wdata[0];
				end else if (mem_addr[6:2]==MISC_REG_FLASH_WDATA) begin
					//handled in combinatorial block above
				end else if (mem_addr[6:2]==MISC_REG_FLASH_SEL) begin
					fsel_d <= mem_wdata[0];
					fsel_strobe <= 1;
					if (mem_wdata[31:8]==24'hD0F1A5) begin
						//D0F1A50x is written. Pull PROGRAMN.
						programn_queue <= 1;
					end
				end else if (mem_addr[6:2]==MISC_REG_ADC_CTL) begin
					adc_divider <= mem_wdata[23:16];
					adc_enabled <= mem_wdata[0];
				end else if (mem_addr[6:2]==MISC_REG_GENIO_OUT) begin
					genio_out <= mem_wdata[29:0];
				end else if (mem_addr[6:2]==MISC_REG_GENIO_OE) begin
					genio_oe <= mem_wdata[29:0];
				end else if (mem_addr[6:2]==MISC_REG_GENIO_W2S) begin
					genio_out <= genio_out | mem_wdata[29:0];
				end else if (mem_addr[6:2]==MISC_REG_GENIO_W2C) begin
					genio_out <= genio_out & ~mem_wdata[29:0];
				end else if (mem_addr[6:2]==MISC_REG_GPEXT_OUT) begin
					irda_sd <= mem_wdata[30];
					pmod_out <= mem_wdata[23:16];
					sao2_out <= mem_wdata[13:8];
					sao1_out <= mem_wdata[5:0];
				end else if (mem_addr[6:2]==MISC_REG_GPEXT_OE) begin
					pmod_oe <= mem_wdata[23:16];
					sao2_oe <= mem_wdata[13:8];
					sao1_oe <= mem_wdata[5:0];
				end else if (mem_addr[6:2]==MISC_REG_GPEXT_W2S) begin
					irda_sd <= irda_sd | mem_wdata[30];
					pmod_out <= pmod_out | mem_wdata[23:16];
					sao2_out <= sao2_out | mem_wdata[13:8];
					sao1_out <= sao1_out | mem_wdata[5:0];
				end else if (mem_addr[6:2]==MISC_REG_GPEXT_W2C) begin
					irda_sd <= irda_sd & ~mem_wdata[30];
					pmod_out <= pmod_out & ~mem_wdata[23:16];
					sao2_out <= sao2_out & ~mem_wdata[13:8];
					sao1_out <= sao1_out & ~mem_wdata[5:0];
				end
			end
		end
	end

	//The D-type flipflop that muxes between the two flashes should
	//be quick enough to work at 48MHz, but still, better to make sure it's
	//set before pulling PROGRAMN.
	reg [2:0] fsel_delay;

	assign fsel_c = (fsel_delay==5 || fsel_delay==4 || fsel_delay==3);
	always @(posedge clk48m) begin
		if (rst) begin
			fsel_delay <= 0;
			fpga_reload <= 0;
		end else begin
			if (fsel_strobe) begin
				fsel_delay <= 7;
			end else if (fsel_delay != 0) begin
				fsel_delay <= fsel_delay - 1;
				if (fsel_delay == 1 && programn_queue == 1) begin
					fpga_reload <= 1;
				end
			end
		end
	end

/*
IRQs used:
0 - Timer interrupt (internal to PicoRV32)
1 - EBREAK, ECALL, illegal inst (internal to PicoRV32)
2 - Unaligned memory access (internal to PicoRV32)
3 - Bus error - not decoded (e.g. dereferenced NULL)
4 - USB irq
*/

	//Interrupt logic
	always @(*) begin
		irq = 'h0;
		if (bus_error) begin
			irq[3] = 1;
		end
		if (usb_irq) begin
			irq[4] = 1;
		end
	end


	//Unused pins
	assign pwmout = 0;
endmodule
