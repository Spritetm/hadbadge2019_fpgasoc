module lcdiface(
	input clk,
	input nrst,
	input [2:0] addr,
	input wen,
	input ren,
	output reg [31:0] rdata,
	input [31:0] wdata,
	output ready,

	output [17:0] lcd_db,
	output reg lcd_rd,
	output reg lcd_wr,
	output reg lcd_rs,
	output lcd_cs,
	input lcd_id,
	output lcd_rst,
	input lcd_fmark,
	output lcd_blen
);

reg [1:0] state;
reg [2:0] out_ctl;
reg [17:0] lcd_readbuf;
reg lcd_rw_done;

assign lcd_cs = out_ctl[2];
assign lcd_rst = ~out_ctl[1]; //note: inverted inverted
assign lcd_blen = out_ctl[0];

always @(*) begin
	if (addr=='h2) begin //xx08
		rdata = out_ctl;
		ready = wen || ren;
	end else if (addr=='h3) begin //xx0c
		rdata = {lcd_id, lcd_fmark};
		ready = wen || ren;
	end else begin
		rdata = lcd_readbuf;
		ready = (state == 3);
	end
end

always @(posedge clk) begin
	if (!nrst) begin
		lcd_rw_done <= 0;
		out_ctl <= 'h6;
		state <= 0;
		lcd_readbuf <= 0;
		lcd_rs <= 0;
		lcd_rd <= 1;
		lcd_wr <= 1;
	end else begin
		if (state==0) begin
			if (addr == 'h2) begin //xx08
				if (wen) out_ctl <= wdata;
			end else if ((addr=='h0 || addr=='h1) && (ren || wen)) begin //xx00/xx04
				lcd_rs <= addr[0];
				lcd_db <= wdata[17:0];
				state <= 1;
			end
		end else if (state==1) begin
			lcd_rd <= ~ren;
			lcd_wr <= ~wen;
			state <= 2;
		end else if (state==2) begin
			state <= 3;
		end else if (state==3) begin
			lcd_rd <= 1;
			lcd_wr <= 1;
			lcd_rw_done <= 1;
			state <= 0;
		end
	end
end

endmodule