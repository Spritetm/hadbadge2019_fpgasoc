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
	output reg [31:0] dout,
	output ready,
	
	//Video mem iface
	output reg [19:0] vid_addr, //assume 1 meg-words linebuf mem max
	output reg [23:0] vid_data_out,
	output reg vid_wen, vid_ren,
	input [23:0] vid_data_in,
	input [19:0] curr_vid_addr,
	input next_field,

	//Master iface to spi mem
	output reg m_do_read,
	input m_next_word,
	output reg [23:0] m_addr,
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
reg [16:0] pitch;

reg [23:0] dma_start_addr;
reg dma_run;
wire dma_ready;
reg dma_do_read;
reg [31:0] dma_data;
qpimem_dma_rdr dma_rdr(
	.clk(clk),
	.rst(reset),
	.addr_start(dma_start_addr),
	.addr_end(dma_start_addr+(480/2)),
	.run(dma_run),
	.do_read(dma_do_read),
	.ready(dma_ready),
	.rdata(dma_data),

	.qpi_do_read(m_do_read),
	.qpi_next_word(m_next_word),
	.qpi_addr(m_addr),
	.qpi_rdata(m_rdata),
	.qpi_is_idle(m_is_idle)
);


always @(posedge clk) begin
	if (reset) begin
		ready_read <= 0;
		ready_write <= 0;
		dout <= 0;
		fb_addr <= 'h7E0000; //top 128K of RAM
		pitch <= 512;
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

always @(posedge clk) begin
	if (reset) begin
		write_vid_addr <= 'h400; //2 lines in advance, so we start writing immediately (good for sim)
		vid_addr <= 0;
		vid_ren <= 0;
		dma_start_addr <= fb_addr;
	end else begin
		//vid_addr is write_vid_addr delayed by one cycle, so we can make
		//decisions of the data to write depending on the contents of write_vid_addr.
		vid_addr <= write_vid_addr;
		dma_do_read <= 0;

		if (write_vid_addr[19:9]>=320) begin
			//We're finished with this frame. Wait until the video generator starts drawing the next frame.
			vid_wen <= 0;
			dma_run <= 0;
			if (next_field) begin
				write_vid_addr <= 0;
				dma_start_addr <= fb_addr;
			end else begin
				//Not yet, keep idling
			end
		end else if (write_vid_addr[10:9] != curr_vid_addr[10:9]) begin
			//If we're here, there is room in the line memory to write a new line into.
			dma_run <= 1;
			if (dma_ready || write_vid_addr[2:0]!=0) begin
				if (write_vid_addr[2:0] == 6) begin
					//We need a new word. Enable read here because:
					// dma_do_read actually goes high next cycle
					// correct data will get returned next next cycle
					dma_do_read <= 1;
				end
				if (write_vid_addr[2:0]==7) vid_data_out <= palette[dma_data[31:28]];
				if (write_vid_addr[2:0]==6) vid_data_out <= palette[dma_data[27:24]];
				if (write_vid_addr[2:0]==5) vid_data_out <= palette[dma_data[23:20]];
				if (write_vid_addr[2:0]==4) vid_data_out <= palette[dma_data[19:16]];
				if (write_vid_addr[2:0]==3) vid_data_out <= palette[dma_data[15:12]];
				if (write_vid_addr[2:0]==2) vid_data_out <= palette[dma_data[11:8]];
				if (write_vid_addr[2:0]==1) vid_data_out <= palette[dma_data[7:4]];
				if (write_vid_addr[2:0]==0) vid_data_out <= palette[dma_data[3:0]];
				if (write_vid_addr[8:0]>479) begin
					//next line
					write_vid_addr[19:9] <= write_vid_addr[19:9] + 'h1;
					write_vid_addr[8:0] <= 0;
					dma_start_addr <= dma_start_addr + pitch/2;
					dma_run <= 0;
				end else begin
					write_vid_addr <= write_vid_addr + 'h1;
				end
				vid_wen <= 1;
			end else begin
				//waiting for dma to have something
			end
		end else begin
			//wait for next line
			dma_run <= 0;
			vid_wen <= 0;
		end
	end
end

endmodule
