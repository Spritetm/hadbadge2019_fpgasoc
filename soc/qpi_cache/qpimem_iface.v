/*
Qpi interface. Note that this code assumes the chip already is in whatever state it needs to be to 
accept read/write commands over a qpi interface, e.g. by having a microcontroller or state machine bitbang 
the lines manually.

Instructions needed:
ly68l6400: 0x35 <- goto qio mode
w25q32: 0x50, 0x31 0x02 <- enable qio mode

How to use:
- Wait until is_idle is 1
- Put first word on wdata if write
- Put address to start reading/writing on addr
- Activate do_rdata or do_wdata
- When next_word is high, put next word on wdata or read word from rdata
- De-activate do_rdata or do_wdata when done

Note:
- Do_read/do_write should stay active as long as there's data to read/write. If it goes inactive,
  the current word will finish writing.
- This code needs at least one dummy cycle on read.

*WIP notes*
Modifications for flash memory:
Flash memory should already work well for the read scenario: poke do_read, hw auto-get bytes on next_byte.
For the write scenario, we need:
- Set write enable latch (cmd 0x06)
- Sector erase (cmd 0x20, address in SPI-mode)
- Read status register 1 until non-busy (cmd 0x05)
- Page program (can be SPI, 0x02)
- Read SR1
- Done!

All of this can be done in SPI. (Page program is so slow that qpi doesn't improve things at
our clock speed.) Means, we don't have to do qpi stuff and can just take a byte, push it out of MOSI,
grab a byte from MISO at the time and return that.

Wrt upgrading speed to 2x memory bus clock using a 2nd tap from the same PLL:
(on needing domain-crossing flipflops)
06:34 < tnt> Sprite_tm: no, you can get aways with much less in theory. _but_ ... nextpnr currently can't constraint clock 
             domain path.
06:34 < tnt> err "cross-clock domain path"
06:49 < Sprite_tm> tnt: Erm, what does that mean in practice? It doesn't know the two clocks are related?
06:55 < tnt> Sprite_tm: yes and it won't do any analysis on that path (just report the max-delay but without pass/fail or 
             attempt to optimize AFAIK).
06:56 < tnt> In general for those, I don't use a full cross clock, but I do make sure the output is a register and the input is 
             either a register or a single LUT + FF.
06:56 < Sprite_tm> Hm, gotcha, good advice, thanks.


*/

module qpimem_iface #(
	//ly68l6400:
	parameter [7:0] READCMD = 'hEB,
	parameter [7:0] WRITECMD = 'h38,
	parameter integer READDUMMY = 7,
	parameter integer WRITEDUMMY = 0,
	parameter [3:0] DUMMYVAL = 0,
	parameter [0:0] CMD_IS_SPI = 0
/*
	//w25q32:
	//NOTE: untested/not working. Write is probably impossible to get to work (because it's a flash part).
	parameter [7:0] READCMD = 'hEb,
	parameter [7:0] WRITECMD = 'hA5,
	parameter integer READDUMMY = 3,
	parameter [3:0] DUMMYVAL = 'hf,
	parameter integer WRITEDUMMY = 1,
	parameter [0:0] CMD_IS_SPI = 1
*/
) (
	input clk,
	input rst,
	
	input do_read,
	input do_write,
	output reg next_byte,
	input [23:0] addr,
	input [31:0] wdata,
	output [31:0] rdata,
	output is_idle,

	output spi_clk,
	output reg spi_ncs,
	output reg [3:0] spi_sout,
	input [3:0] spi_sin,
	output reg spi_oe
);

//Note: 32-bit words from RiscV are little-endian, but the way we send them is big-end first. Swap
//endian-ness to make tests happy.
wire [31:0] wdata_be;
assign wdata_be[31:24]=wdata[7:0];
assign wdata_be[23:16]=wdata[15:8];
assign wdata_be[15:8]=wdata[23:16];
assign wdata_be[7:0]=wdata[31:24];

reg [31:0] rdata_be;
assign rdata[31:24]=rdata_be[7:0];
assign rdata[23:16]=rdata_be[15:8];
assign rdata[15:8]=rdata_be[23:16];
assign rdata[7:0]=rdata_be[31:24];

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
		spi_ncs <= 1;
		spi_sout <= 0;
		curr_is_read <= 0;
		keep_transferring <= 0;
	end else begin
		if (next_byte) begin
			keep_transferring <= (do_read || do_write);
		end

		next_byte <= 0;
		if (state == 0) begin
			spi_ncs <= 1;
			if (do_read || do_write) begin
				//New write or read cycle starts.
				state <= 1;
				bitno <= 7;
				curr_is_read <= do_read;
			end
		end else if (state == 1) begin
			//Send out command
			spi_ncs <= 0;
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
				if ((do_read ? READDUMMY : WRITEDUMMY)==0) begin
					state <= 4;
						bitno <= 7;
					if (curr_is_read) begin
						//nop
					end else begin
						//Make sure we already have the data to shift out.
						data_shifted <= wdata_be;
						next_byte <= 1;
					end
				end else begin
					bitno <= do_read ? READDUMMY-1 : WRITEDUMMY-1;
					state <= 3;
				end
			end else begin
				bitno <= bitno - 1;
			end
		end else if (state == 3) begin
			//Dummy bytes. Amount of nibbles is in bitno.
			//Note that once the host has pulled down 
			spi_sout <= DUMMYVAL;
			bitno <= bitno - 1;
			if (bitno==0) begin
				//end of dummy cycle
				state <= 4;
				if (curr_is_read) begin
					bitno <= 7;
					spi_oe <= 0; //abuse one cycle for turnaround
				end else begin
					//Make sure we already have the data to shift out.
					data_shifted <= wdata_be;
					next_byte <= 1;
					bitno <= 7;
				end
			end
		end else if (state == 4) begin
			//Data state.
			if (curr_is_read) begin //read
				if (bitno==0) begin
					rdata_be <= {data_shifted[31:4], spi_sin_sampled[3:0]};
					next_byte <= 1;
					bitno <= 7;
					if (!do_read) begin //abort?
						state <= 5;
						spi_ncs <= 1;
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
						data_shifted <= wdata_be;
						next_byte <= 1;
						bitno <= 7;
					end
				end else begin
					bitno<=bitno-1;
				end
			end
		end else begin //state=5
			spi_ncs <= 1;
			spi_oe <= 0;
			state <= 0;
		end
	end
end


endmodule
