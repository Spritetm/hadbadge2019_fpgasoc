module lcdiface(
	input clk,
	input nrst,
	input [2:0] addr,
	input wen,
	input ren,
	output reg [31:0] rdata,
	input [31:0] wdata,
	output wire ready,

	output reg [17:0] lcd_db,
	output reg lcd_rd,
	output reg lcd_wr,
	output reg lcd_rs,
	output lcd_cs,
	input lcd_id,
	output lcd_rst,
	input lcd_fmark,
	output lcd_blen
);

reg [2:0] state;
reg [2:0] out_ctl;
reg [17:0] lcd_readbuf;
reg lcd_rw_done;

assign lcd_cs = out_ctl[2];
assign lcd_rst = ~out_ctl[1]; //note: inverted inverted
assign lcd_blen = out_ctl[0];

reg [31:0] rdata_c;
reg ready_c;
reg ready_n;
always @(*) begin
	if (addr=='h2) begin //xx08
		rdata_c = out_ctl;
		ready_c = wen || ren;
	end else if (addr=='h3) begin //xx0c
		rdata_c = {lcd_id, lcd_fmark};
		ready_c = wen || ren;
	end else begin
		rdata_c = lcd_readbuf;
		//Note we ready on state==3, so the CPU can lower its read line on state==4 so it's low when we re-sample
		//it on state==0
		ready_c = (state == 3);
	end
end

always @(posedge clk) begin
	if (!nrst) begin
		rdata <= 0;
		ready_n <= 0;
	end else begin
		rdata <= rdata_c;
		ready_n <= ready_c;
	end
end

assign ready = ready_n & (ren || wen);

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
			lcd_readbuf <= lcd_db; //ToDo: LCD_Rin or so
			lcd_rd <= 1;
			lcd_wr <= 1;
			lcd_rw_done <= 1;
			state <= 4;
		end else if (state==4) begin
			if (!(ren || wen)) state <= 0;
		end else begin
			state <= 0; //fallback
		end
	end
end

endmodule