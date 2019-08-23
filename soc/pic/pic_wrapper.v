
module pic_wrapper #(
	parameter ROM_HEX = "rom_initial.hex"
) (
	input clk,
	input reset,

	//I/O for the PIC
	input [15:0] gpio_in,
	output [15:0] gpio_out,
	input [7:0] rng,

	//I/O for the master
	input [15:0] address,
	input [31:0] data_in,
	output reg [31:0] data_out,
	input wen,
	input ren,
	output ready
);

wire [15:0] prog_dat;   // ROM read data
wire [12:0] prog_adr;   // ROM address

wire [15:0] ram_dat_r;     // RAM read data, note only [7:0] are used
wire [15:0] ram_dat_w;     // RAM write data
wire [9:0] ram_adr;     // RAM address; ram_adr[8:7] indicates RAM-BANK
wire ram_we;            // RAM write strobe (H active)
reg pic_reset;
reg pic_int0;
reg pic_can_run;

assign ram_dat_w[15:8] = 'h0;
assign ram_adr[9] = 0;

risc16f84_clk2x pic(
	.clk_i(clk),
	.clk_en_i(pic_can_run),
	.reset_i(reset || pic_reset),
	.int0_i(pic_int0),
	.porta_i(gpio_in[15:8]),
	.portb_i(gpio_in[7:0]),
	.porta_o(gpio_out[15:8]),
	.portb_o(gpio_out[7:0]),
	.rng_i(rng),
	.ram_we_o(ram_we),
	.ram_adr_o(ram_adr),
	.ram_dat_o(ram_dat_w),
	.ram_dat_i(ram_dat_r[7:0]),
	.prog_adr_o(prog_adr),
	.prog_dat_i(prog_dat[13:0])
);


//Needed for memory:
//- Program ram: 14bit*1K (max 8K, but 'F84 only has 1K)
//- Data ram: 8bit*256

wire [15:0] host_progmem_out;
reg host_progmem_wen;
wire [15:0] host_datamem_out;
reg host_datamem_wen;
reg ctlreg_wen;

dpram_1kx16 #(
	.INIT_FILE(ROM_HEX)
) progmem (
	.clk(clk),
	.rst(reset),
	.addr_a(prog_adr[9:0]),
	.wdata_a(16'h0),
	.rdata_a(prog_dat),
	.wen_a(1'b0),
	.addr_b(address[11:2]),
	.wdata_b(data_in[15:0]),
	.rdata_b(host_progmem_out),
	.wen_b(host_progmem_wen)
);

//Data ram is only 256 bytes of 8 bit, but we use up a dpram anyway, so it doesn't really make sense to
//have a smaller memory here.
dpram_1kx16 #(
	.INIT_FILE(ROM_HEX)
) datamem (
	.clk(clk),
	.rst(reset),
	.addr_a(ram_adr),
	.wdata_a(ram_dat_w),
	.rdata_a(ram_dat_r),
	.wen_a(ram_we),
	.addr_b(address[11:2]),
	.wdata_b(data_in),
	.rdata_b(host_datamem_out),
	.wen_b(host_datamem_wen)
);

assign ready = wen || ren;

//We run the PIC at half speed as reads/writes are registered.
always @(posedge clk) begin
	if (reset) begin
		pic_can_run <= 0;
	end else begin
		if (pic_can_run) begin
			//PIC just ran a cycle. Do writes, handle reads.
			pic_can_run <= 0;
		end else begin
			//Just set up data from and to memory. Run the PIC for another cycle.
			pic_can_run <= 1;
		end
	end
end

always @(*) begin
	host_datamem_wen <= 0;
	host_progmem_wen <= 0;
	ctlreg_wen <= 0;
	data_out <= 'hx;
	if (ren || wen) begin
		if (address[15:14]=='b00) begin
			data_out <= {30'b0, pic_int0, pic_reset};
			ctlreg_wen <= wen;
		end else if (address[15:14]==2'b01) begin
			data_out <= {16'h0, host_datamem_out};
			host_datamem_wen <= wen;
		end else if (address[15]==1) begin
			data_out <= {16'h0, host_progmem_out};
			host_progmem_wen <= wen;
		end
	end
end

reg ready_dly;
assign ready = ready_dly && (wen || ren);

always @(posedge clk) begin
	if (reset) begin
		ready_dly <= 0;
		pic_int0 <= 0;
		pic_reset <= 0;
	end else begin
		if (ctlreg_wen) begin
			pic_int0 <= data_in[1];
			pic_reset <= data_in[0];
		end
		ready_dly <= wen || ren;
	end
end

endmodule




