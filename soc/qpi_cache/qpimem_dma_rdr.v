/*
Simple buffered read-only DMA interface to QPI memory. Uses a blockram as a fifo.
*/

//Note: For interleaved psram @ 48MHz, burstlen should be <=32
module qpimem_dma_rdr #(
	//Simple 2-way cache.
	parameter integer FIFO_WORDS=512, //must be power of 2
	parameter integer BURST_LEN=16, //in words; note: must be power of 2, <= FIFO_WORDS
	parameter integer ADDR_WIDTH=24 //qpi bus address width
) (
	input clk,
	input rst,
	
	input [ADDR_WIDTH-1:0] addr_start, //byte addr
	input [ADDR_WIDTH-1:0] addr_end, //byte addr
	input run,			//Start/continue DMA transaction. This going low will end the transaction.
	output ready,		//A byte is available for reading
	output all_done,	//DMA transaction is complete.
	input do_read,		//Strobe for next word
	output [31:0] rdata,	//Data read
	
	//qpi memory interface
	output reg qpi_do_read,
	input qpi_next_word,
	output reg [ADDR_WIDTH-1:0] qpi_addr,
	input [31:0] qpi_rdata,
	input qpi_is_idle
);


reg [ADDR_WIDTH-1:0] out_addr;
wire [$clog2(FIFO_WORDS)-1:0] fifo_rptr;
wire [$clog2(FIFO_WORDS)-1:0] fifo_wptr;
assign fifo_rptr = out_addr[$clog2(FIFO_WORDS)-1+2:2]; //word addr
assign fifo_wptr = qpi_addr[$clog2(FIFO_WORDS)-1+2:2]; //word addr
assign ready = (fifo_rptr != fifo_wptr);
assign all_done = (out_addr >= addr_end);
wire qpi_done;
assign qpi_done = (qpi_addr >= addr_end);

qpimem_dma_rd_fifomem fifomem(
	.clk(clk),
	.w_en(qpi_next_word),
	.w_addr(fifo_wptr),
	.w_data(qpi_rdata),
	.r_addr(fifo_rptr),
	.r_data(rdata)
);

reg restarting;

always @(posedge clk) begin
	if (rst) begin
		out_addr <= 0;
		qpi_addr <= 0;
		qpi_do_read <= 0;
		restarting <= 1;
	end else begin
		//If we're reading, move out_addr
		if (ready && do_read) begin
			out_addr <= out_addr + 4; //we read one word at a time
		end

		//handle qpi logic
		if (!run) begin
			//End qpi transaction, but do not touch read side of fifo.
			qpi_addr <= addr_start;
			out_addr <= addr_start;
			qpi_do_read <= 0;
			restarting <= 1;
		end else if (restarting) begin
			restarting <= !qpi_is_idle; //we can begin when qpi has finished current transaction
		end else if (qpi_next_word) begin
			qpi_addr <= qpi_addr + 4; //we read one word at a time
			if ((fifo_wptr & (BURST_LEN-1)) == (BURST_LEN-1)) begin
				qpi_do_read <= 0; //abort burst
			end
			if ((qpi_addr+4) >= addr_end) begin
				qpi_do_read <= 0; //abort burst
			end
		end else if (qpi_is_idle && !qpi_do_read) begin
			//See if we should start reading again.
			if ((qpi_addr - out_addr) < ((FIFO_WORDS - BURST_LEN) * 4)) begin
				if (qpi_addr < addr_end) begin
					qpi_do_read <= 1; //go read more.
				end
			end
		end
	end
end

endmodule

module qpimem_dma_rd_fifomem #(
	parameter integer FIFO_WORDS = 512
) (
	input clk,
	input w_en,
	input [31:0] w_data,
	input [$clog2(FIFO_WORDS)-1:0] w_addr,
	output [31:0] r_data,
	input [$clog2(FIFO_WORDS)-1:0] r_addr
);

reg [31:0] ram [0:FIFO_WORDS-1];

assign r_data = ram[r_addr];
always @(posedge clk) begin
	if (w_en) ram[w_addr] <= w_data;
end

endmodule
