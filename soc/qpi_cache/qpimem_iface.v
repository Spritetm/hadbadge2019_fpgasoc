/*
Qpi interface. Note that this code assumes the chip already is in whatever state it needs to be to 
accept read/write commands over a qpi interface, e.g. by having a microcontroller or state machine bitbang 
the lines manually.

Instructions needed:
ly68l6400: 0x35 <- goto qio mode
w25q32: 0x50, 0x31 0x02 <- enable qio mode

Note:
- Do_read/do_write should stay active as long as there's data to read/write. If it goes inactive,
  the current word will finish writing.
- This code needs at least one dummy cycle.
*/

module qpimem_iface #(
/*
	//ly68l6400:
	parameter integer readcmd = 'hEB,
	parameter integer writecmd = 'h38,
	parameter integer readdummy = 7,
	parameter integer writedummy = 0,
	parameter integer cmd_is_spi = 0
*/
	//w25q32:
	parameter [7:0] READCMD = 'hEb,
	parameter [7:0] WRITECMD = 'hA5,
	parameter integer READDUMMY = 3,
	parameter [7:0] DUMMYVAL = 'hff,
	parameter [0:0] WRITEDUMMY = 1,
	parameter [0:0] CMD_IS_SPI = 0
) (
	input clk,
	input rst,
	
	input do_read,
	input do_write,
	output reg next_byte,
	input [24:0] addr,
	input [31:0] wdata,
	output reg [31:0] rdata,
	output is_idle,

	output spi_clk,
	output reg spi_cs,
	output reg [3:0] spi_sout,
	input [3:0] spi_sin,
	output reg spi_oe
);

reg [6:0] state;
reg [4:0] bitno; //note: this sometimes indicates nibble-no, not bitno. Also used to store dummy nibble count.
reg [3:0] spi_sin_sampled;
reg [31:0] data_shifted;

assign spi_clk = !clk;

assign is_idle = (state == 0) && !do_read && !do_write;

always @(negedge clk) begin
	spi_sin_sampled <= spi_sin;
end

reg curr_is_read;
wire [7:0] command;
assign command = curr_is_read ? READCMD : WRITECMD;
reg keep_transferring;

always @(posedge clk) begin
	if (rst) begin
		state <= 0;
		bitno <= 0;
		spi_oe <= 0;
		spi_cs <= 1;
		spi_sout <= 0;
		curr_is_read <= 0;
		keep_transferring <= 0;
	end else begin
		if (next_byte) begin
			keep_transferring <= (do_read || do_write);
		end

		next_byte <= 0;
		if (state == 0) begin
			if (do_read || do_write) begin
				//New write or read cycle starts.
				state <= 1;
				bitno <= 7;
				curr_is_read <= do_read;
			end
		end else if (state == 1) begin
			//Send out command
			spi_cs <= 0;
			spi_oe <= 1;
			if (CMD_IS_SPI) begin
				spi_sout <= {command[bitno],3'b0};
				if (bitno == 0) begin
					state <= 2;
					bitno <= 5;
				end else begin
					bitno <= bitno - 1;
				end
			end else begin
				spi_sout <= command[bitno -: 4];
				if (bitno == 3) begin
					bitno <= 5;
					state <= 2;
				end else begin
					bitno <= bitno - 4;
				end
			end
		end else if (state == 2) begin
			//Address, in qpi
			spi_sout <= addr[bitno*4+3 -: 4];
			if (bitno == 0) begin
				bitno <= do_read ? READDUMMY*2-1 : WRITEDUMMY*2-1;
				state <= 3;
			end else begin
				bitno <= bitno - 1;
			end
		end else if (state == 3) begin
			//Dummy bytes. Amount of nibbles is in bitno.
			//Note that once the host has pulled down 
			spi_sout <= bitno[0] ? DUMMYVAL[7:4] : DUMMYVAL[3:0];
			bitno <= bitno - 1;
			if (bitno==0) begin
				//end of dummy cycle
				state <= 4;
				if (curr_is_read) begin
					bitno <= 7;
					spi_oe <= 0; //abuse one cycle for turnaround
				end else begin
					//Make sure we already have the data to shift out.
					data_shifted <= wdata;
					next_byte <= 1;
					bitno <= 7;
				end
			end
		end else if (state == 4) begin
			//Data state.
			if (curr_is_read) begin
				if (bitno==0) begin
					rdata <= {data_shifted[31:4], spi_sin_sampled[3:0]};
					next_byte <= 1;
					bitno <= 7;
					if (!do_read) begin //abort?
						state <= 5;
						spi_cs <= 0;
					end
				end else begin
					data_shifted[bitno*4+3 -: 4]<=spi_sin_sampled;
					bitno<=bitno-1;
				end
			end else begin //write
				spi_sout <= data_shifted[bitno*4+3 -: 4];
				if (bitno==0) begin
					//note host may react on next_byte going high by putting one last word on the bus, then
					//lowering do_write. This is why we use keep_transfering instead of do_write
					if (!keep_transferring) begin //abort?
						state <= 5;
					end else begin
						data_shifted <= wdata;
						next_byte <= 1;
						bitno <= 7;
					end
				end else begin
					bitno<=bitno-1;
				end
			end
		end else begin
			spi_cs <= 1;
			spi_oe <= 0;
			state <= 0;
		end
	end
end


endmodule
