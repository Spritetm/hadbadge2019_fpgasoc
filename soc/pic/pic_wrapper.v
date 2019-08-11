
module pic_wrapper #(
	parameter ROM_HEX = "rom_initial.hex"
) (
	input clk,
	input reset,

	//I/O for the PIC
	input [15:0] gpio_in,
	output [15:0] gpio_out,

	//I/O for the master
	input [15:0] address,
	input [31:0] data_in,
	output reg [31:0] data_out,
	input wen,
	input ren,
	output ready
);

reg [13:0] prog_dat;   // ROM read data
wire [12:0] prog_adr;   // ROM address

reg [7:0] ram_dat_r;     // RAM read data
wire [7:0] ram_dat_w;     // RAM write data
wire [8:0] ram_adr;     // RAM address; ram_adr[8:7] indicates RAM-BANK
wire ram_we;            // RAM write strobe (H active)
reg pic_reset;
reg pic_int0;
reg pic_can_run;


risc16f84_clk2x pic(
	.clk_i(clk),
	.clk_en_i(pic_can_run),
	.reset_i(reset),
	.int0_i(pic_int0),
	.porta_i(gpio_in[7:0]),
	.portb_i(gpio_in[15:8]),
	.porta_o(gpio_out[7:0]),
	.portb_o(gpio_out[15:8]),
	.ram_we_o(ram_we),
	.ram_adr_o(ram_adr),
	.ram_dat_o(ram_dat_w),
	.ram_dat_i(ram_dat_r),
	.prog_adr_o(prog_adr),
	.prog_dat_i(prog_dat)
);

//Needed for memory:
//- Program ram: 14bit*1K (max 8K, but 'F84 only has 1K)
//- Data ram: 8bit*256

reg [13:0] prog_mem [0:1023];
reg [7:0] data_mem [0:255];

integer i;
initial begin
	if (ROM_HEX == "") begin
		for (i=0; i<1024; i=i+1) prog_mem[i]='h0;
	end else begin
		$readmemh(ROM_HEX, prog_mem);
	end
	for (i=0; i<256; i++) data_mem[i]=0;
end

assign ready = wen || ren;

always @(posedge clk) begin
	if (reset) begin
		pic_can_run <= 0;
	end else begin
		if (pic_can_run) begin
			//PIC just ran a cycle. Do writes, handle reads.
			pic_can_run <= 0;
			if (ram_we) begin
				data_mem[ram_adr] <= ram_dat_w;
			end
			prog_dat <= prog_mem[prog_adr];
			ram_dat_r <= data_mem[ram_adr];
		end else begin
			//Just set up data from and to memory. Run the PIC for another cycle.
			pic_can_run <= 1;
		end
	end
end

reg prog_sel, ctl_sel, ram_sel;

always @(*) begin
	prog_sel <= 0;
	ctl_sel <= 0;
	ram_sel <= 0;
	if (ren || wen) begin
		if (address[15:14]=='b00) begin
			ctl_sel <= 1;
		end else if (address[15:14]==2'b01) begin
			ram_sel <= 1;
		end else if (address[15]==1) begin
			prog_sel <= 1;
		end
	end
end

reg ready_dly;
assign ready = ready_dly && (wen || ren);

always @(posedge clk) begin
	if (reset) begin
		pic_reset <= 0;
		pic_int0 <= 0;
		ready_dly <= 0;
	end else begin
		data_out <= 'hx;
		ready_dly <= 0;
		if (ram_sel) begin
			data_out <= {30'b0, pic_int0, pic_reset};
			if (wen) begin
				data_mem[address[10:2]] <= data_in[7:0];
			end
			ready_dly<=1;
		end else if (prog_sel && wen) begin
			data_out <= {18'b0, prog_mem[address[11:2]]};
			if (wen) begin
				prog_mem[address[11:2]] <= data_in[13:0];
			end
			ready_dly<=1;
		end else if (ctl_sel && wen) begin
			data_out <= {30'b0, pic_int0, pic_reset};
			if (wen) begin
				pic_int0 <= data_in[1];
				pic_reset <= data_in[1];
			end
			ready_dly<=1;
		end
	end
end

endmodule