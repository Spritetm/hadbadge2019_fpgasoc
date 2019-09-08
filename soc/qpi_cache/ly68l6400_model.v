/*
Simplified SPI SRAM model. Supports qpi only.
*/

module spiram (
	input spi_clk,
	input spi_ncs,
	input [3:0] spi_sin,
	output reg [3:0] spi_sout,
	input spi_oe
);

reg [7:0] mem [0:8*1024*1024-1];

reg [3:0] spi_sout_next;
always @(negedge spi_clk) begin
	spi_sout <= spi_sout_next;
end

integer state;
reg [23:0] addr;
reg [7:0] cmd;
reg hinib;
integer i;
initial begin
	state <= 0;
	for (i=0; i<8*1024*1024; i++) begin
		mem[i]=i & 'hff;
	end
end

always @(posedge spi_clk) begin
	if (spi_ncs) begin
		state <= 0;
		hinib <= 1;
	end else begin
		spi_sout_next <= 'hz;
		if (state==0) begin
			cmd[7:4]<=spi_sin;
		end else if (state==1) begin
			cmd[3:0]<=spi_sin;
		end else if (state==2) begin
			addr[23:20]<=spi_sin;
		end else if (state==3) begin
			addr[19:16]<=spi_sin;
		end else if (state==4) begin
			addr[15:12]<=spi_sin;
		end else if (state==5) begin
			addr[11:8]<=spi_sin;
		end else if (state==6) begin
			addr[7:4]<=spi_sin;
		end else if (state==7) begin
			addr[3:0]<=spi_sin;
		end else begin
			if (cmd=='heb) begin //fast read
				if (state>=13) begin
					if (hinib) begin
						spi_sout_next <= mem[addr][7:4];
						hinib <= 0;
					end else begin
						spi_sout_next <= mem[addr][3:0];
						hinib <= 1;
						addr <= addr + 1;
					end
				end
			end else if (cmd=='h02 || cmd=='h38) begin
				if (hinib) begin
					mem[addr][7:4] <= spi_sin;
					hinib <= 0;
				end else begin
					mem[addr][3:0] <= spi_sin;
					hinib <= 1;
					addr <= addr + 1;
				end
			end else begin
				$display("psram: unknown cmd %h", cmd);
			end
		end
		state <= state + 1;
	end
end

endmodule