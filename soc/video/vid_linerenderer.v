module vid_linerenderer (
	input clk, reset,
	input [24:0] addr,
	input [31:0] din,
	input wen, ren,
	output [31:0] dout,
	output reg ready,
	
	output [19:0] vid_addr, //assume 1 meg-words linebuf mem max
	output [23:0] vid_data_out,
	output vid_wen, vid_ren,
	input [23:0] vid_data_in,
	input curr_vid_addr
);

reg [23:0] palette [15:0];

reg [19:0] vid_write_adr;
reg [31:0] vid_write_data;
reg [4:0] vid_write_ctr;

always @(*) begin
	if (vid_write_ctr!=0) begin
		vid_addr <= vid_write_addr;
		vid_data_out <= palette[vid_write_data[3:0]];
		vid_wen <= 1;
	end else begin
		vid_addr <= 'hx;
		vid_data_out <= 'hx;
		vid_wen <= 0;
	end
end

reg ready_read;
assign ready = (wen && (vid_write_ctr!=0)) || (ren && ready_read);

always @(posedge clk) begin
	if (reset) begin
		vid_addr <= 0;
		vid_write_data <= 0;
		ready_read <= 0;
		dout <= 0;
	end else begin
		ready_read <= 0;
		if (wen && vid_write_ctr == 0) begin
			if (addr[23:20]==0) begin
				//settings, palette etc
				if (addr[19:0]<16) begin
					palette[addr[3:0]] <= din[23:0];
				end
			end else if (addr[23:20]==1) begin
				vid_write_addr <= addr[19:0];
				vid_write_data <= din;
				vid_write_ctr <= 9;
			end
		end else if (ren) begin
			dout <= curr_vid_addr;
			ready_read <= 0;
		end

		if (vid_write_ctr != 0) begin
			vid_write_addr <= vid_write_addr - 1;
			vid_write_data[31:4] <= vid_write_data[27:0];
			vid_write_ctr <= vid_write_ctr - 1;
		end
	end
end

endmodule