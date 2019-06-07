/*
This effectively is the GPU. It has a slave interface to the CPU, for register-settings and 
'on-chip' video memory, as well as a master interface for the SPI RAM, for grabbing a bitmap.
*/

module vid_linerenderer (
	input clk, reset,

	//Slave iface from cpu
	input [24:0] addr,
	input [31:0] din,
	input wen, ren,
	output [31:0] dout,
	output reg ready,
	
	//Video mem iface
	output reg [19:0] vid_addr, //assume 1 meg-words linebuf mem max
	output reg [23:0] vid_data_out,
	output reg vid_wen, vid_ren,
	input [23:0] vid_data_in,
	input [19:0] curr_vid_addr,
	input next_field,

	//Master iface to spi mem
	output m_do_read,
	input m_next_byte,
	output [23:0] m_addr,
	input [31:0] m_rdata,
	input m_is_idle
);

reg [23:0] palette [15:0];

reg ready_read;
reg ready_write;
assign ready = (wen && ready_write) || (ren && ready_read);

initial begin
	palette[0] = 24'h000000;
	palette[1] = 24'h000080;
	palette[2] = 24'h008000;
	palette[3] = 24'h008080;
	palette[4] = 24'h800000;
	palette[5] = 24'h800080;
	palette[6] = 24'h808000;
	palette[7] = 24'h808080;
	palette[8] = 24'h404040;
	palette[9] = 24'h0000ff;
	palette[10] = 24'h00ff00;
	palette[11] = 24'h00ffff;
	palette[12] = 24'hff0000;
	palette[13] = 24'hff00ff;
	palette[14] = 24'hffff00;
	palette[15] = 24'hffffff;
end

reg [23:0] fb_addr;

always @(posedge clk) begin
	if (reset) begin
		ready_read <= 0;
		ready_write <= 0;
		dout <= 0;
		fb_addr <= 'h7E0000; //top 128K of RAM
	end else begin
		/* CPU interface */
		ready_read <= 0;
		ready_write <= 0;
		if (wen) begin
			if (addr[23:20]==0) begin
				//settings, palette etc
				if (addr[19:2]<16) begin
					palette[addr[5:2]] <= din[23:0];
				end else if (addr[19:2]==16) begin
					fb_addr <= din[23:0];
				end
				ready_write <= 1;
			end
		end else if (ren) begin
			dout <= {curr_vid_addr, 4'b0};
			ready_read <= 1;
		end
	end
end

reg [19:0] write_vid_addr;
//Note: We should only grab 64 bytes at a time.
//A line is 512 pixels, so 256 bytes are needed... need 4 reloads.

always @(posedge clk) begin
	if (reset) begin
		write_vid_addr <= 'h400; //2 lines in advance, so we start writing immediately (good for sim)
		vid_addr <= 0;
		vid_ren <= 0;
		m_addr <= fb_addr;
		m_do_read <= 0;
	end else begin
		//vid_addr is write_vid_addr delayed by one cycle, so we can make
		//decisions of the data to write depending on the contents of write_vid_addr.
		vid_addr <= write_vid_addr;
		if (write_vid_addr[19:9]==320) begin
			if (next_field) begin
				write_vid_addr <= 0;
			end else begin
				m_do_read <= 0;
				vid_wen <= 0;
			end
		end else if (write_vid_addr[10:9] != curr_vid_addr[10:9]) begin
			if (m_do_read == 0 && m_is_idle) begin //cs was lowered but iface is idle again: we can go
				m_do_read <= 1;
				m_addr <= fb_addr + (write_vid_addr/2);
			end else if (write_vid_addr[6:0] == 'h70) begin
				m_do_read <= 0; //lower cs until iface is idle
			end
			if (m_next_byte || write_vid_addr[2:0]!=0) begin
				if (write_vid_addr[2:0]==0) vid_data_out <= palette[m_rdata[31:28]];
				if (write_vid_addr[2:0]==1) vid_data_out <= palette[m_rdata[27:24]];
				if (write_vid_addr[2:0]==2) vid_data_out <= palette[m_rdata[23:20]];
				if (write_vid_addr[2:0]==3) vid_data_out <= palette[m_rdata[19:16]];
				if (write_vid_addr[2:0]==4) vid_data_out <= palette[m_rdata[15:12]];
				if (write_vid_addr[2:0]==5) vid_data_out <= palette[m_rdata[11:8]];
				if (write_vid_addr[2:0]==6) vid_data_out <= palette[m_rdata[7:4]];
				if (write_vid_addr[2:0]==7) vid_data_out <= palette[m_rdata[3:0]];
				if (write_vid_addr[8:0]==480) begin
					write_vid_addr <= write_vid_addr + 'h20; //skip invisible pixels
				end else begin
					write_vid_addr <= write_vid_addr + 'h1;
				end
				vid_wen <= 1;
			end else begin
				vid_wen <= 0;
			end
		end else begin
			//wait for next line
			m_do_read <= 0;
			vid_wen <= 0;
			m_addr <= fb_addr + (write_vid_addr/2);
		end
	end
end

endmodule
