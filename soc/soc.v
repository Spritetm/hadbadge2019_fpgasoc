/*
Top module for SoC.
*/


module soc(
		input clk, 
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
		output lcd_blen
	);

	parameter integer MEM_WORDS = 4096;
	parameter [31:0] STACKADDR = (MEM_WORDS*4);
	parameter [31:0] PROGADDR_RESET = 32'h0;
	parameter [31:0] PROGADDR_IRQ = 31'h10;

	reg [5:0] reset_cnt = 0;
	wire resetn = &reset_cnt;
	always @(posedge clk) begin
		if (btn[7]) begin
			reset_cnt <= reset_cnt + !resetn;
		end else begin
			reset_cnt <= 0;
		end
	end

	wire clk48m;
	pll_8_48 pll(
		.clki(clk),
		.clko(clk48m)
	);

	wire mem_valid;
	wire mem_instr;
	wire mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	reg [31:0] mem_rdata;
	wire [31:0] irq;
	reg [5:0] led;

	picorv32 #(
		.STACKADDR(STACKADDR),
		.PROGADDR_RESET(PROGADDR_RESET),
		.PROGADDR_IRQ(PROGADDR_IRQ),
		.BARREL_SHIFTER(1),
		.COMPRESSED_ISA(1),
		.ENABLE_COUNTERS(0),
		.ENABLE_MUL(1),
		.ENABLE_DIV(1),
		.ENABLE_IRQ(0),
		.ENABLE_IRQ_QREGS(0)
	) cpu (
		.clk         (clk48m     ),
		.resetn      (resetn     ),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  ),
		.mem_rdata   (mem_rdata  ),
		.irq         (irq        )
	);

	assign irq = 'h0;

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

	always @(*) begin
		mem_select = 0;
		uart_div_select = 0;
		uart_dat_select = 0;
		led_select = 0;
		lcd_select = 0;
		mem_rdata = 'hDEADBEEF;
		if (mem_addr[31:28]=='h0) begin
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
		end else if (mem_addr[31:28]=='h3) begin
			lcd_select = mem_valid;
			mem_rdata = lcd_rdata;
		end
	end

	assign mem_ready = ram_ready || uart_div_select || led_select || (uart_dat_select && !uart_reg_dat_wait) || lcd_ready;


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
		.reg_dat_re  (uart_dat_select && !mem_wstrb),
		.reg_dat_di  (mem_wdata),
		.reg_dat_do  (uart_reg_dat_do),
		.reg_dat_wait(uart_reg_dat_wait)
	);

	assign genio[29:4]='h0;
	assign genio[2]=clk48m;
	assign genio[3]=uart_rx;

	base_mem #(
		.WORDS(MEM_WORDS)
	) memory (
		.clk(clk48m),
		.wen((mem_valid && !mem_ready && mem_select) ? mem_wstrb : 4'b0),
		.addr(mem_addr[23:2]),
		.wdata(mem_wdata),
		.rdata(ram_rdata)
	);

	always @(posedge clk48m) begin
		ram_ready <= mem_valid && !mem_ready && mem_select;
		if (led_select && mem_wstrb[0]) begin
			led <= mem_wdata[5:0];
		end
	end

endmodule
