/*verilator tracing_off*/
/*
 * Copyright (C) 2019  Jeroen Domburg <jeroen@spritesmods.com>
 * All rights reserved.
 *
 * BSD 3-clause, see LICENSE.bsd
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the <organization> nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

module qpimem_cache #(
	//Simple 2-way cache.
	parameter integer CACHELINE_WORDS=16,
	parameter integer CACHELINE_CT=512,
	parameter integer ADDR_WIDTH=22 //addresses words
	//Cache size is CACHELINE_WORDS*CACHELINE_CT*4 bytes.
) (
	input clk,
	input rst,
	
	output reg qpi_do_read,
	output reg qpi_do_write,
	input qpi_next_word,
	output reg [ADDR_WIDTH+2-1:0] qpi_addr, //note: this addresses bytes
	output reg [31:0] qpi_wdata,
	input [31:0] qpi_rdata,
	input qpi_is_idle,

	input [ADDR_WIDTH-1:0] addr,
	input [3:0] wen,
	input ren,
	input flush,
	input [31:0] wdata,
	output [31:0] rdata,
	output reg ready
);

/*
Recap of cache theory: 
The cache itself is a memory consisting of x cache lines. These cache lines are
split in (here) 2 ways. Each pair of 2 cache lines with the same address is called
a cache set. Each line in the cache set has data memory of a bunch of words, as well
as tag and flag memory.

For the cache, an address is divided in three components:
addr = {tag, set, offset}
The set bit refers to a specific set of (2 here) cache lines, the offset is an offset
into these lines. The specific line that is used depends on the tag: the line where
the contents of its tag memory equals the tag bit of the address will be used. If there's
no match, there's a cache miss.

On a cache miss, one of the two lines needs to be flushed (written back to main memory)
if it's dirty (written to after read from memory). It then needs to be reloaded from the
bit of memory that contains the requested address, and its tag memory and flags updated.
After that, we can retry and the cache will hit.

The strategy to decide which cache line will be reloaded is LRU, or Least Recently Used.
Every read from or write to a cache line, the cache will store a flag in the flag memory
of the set indicating that that specific way of cache is used most recently, and thus
the other line should be choosen for flush/reload if needed.

This cache also has a 'flush'-line. If asserted with a valid address and wdata, all lines 
containing addresses from addr to wdata will be flushed and marked clean. The 'ready' line
will be low until the end of this operation, similar to a read or write.
*/


//note: do not change, there's no logic for anything but a 2-way LRU cache.
parameter integer CACHE_WAYS=2;

//Remember: address = {tag, set, offset}
parameter CACHE_SETS=CACHELINE_CT/CACHE_WAYS;
parameter CACHE_TAG_BITS=ADDR_WIDTH-$clog2(CACHELINE_WORDS*CACHE_SETS);
parameter CACHE_SET_BITS=$clog2(CACHE_SETS);
parameter CACHE_OFFSET_BITS=$clog2(CACHELINE_WORDS);

//Easy accessor macros
`define TAG_FROM_ADDR(addr) addr[ADDR_WIDTH-1:ADDR_WIDTH-CACHE_TAG_BITS]
`define SET_FROM_ADDR(addr) addr[CACHE_OFFSET_BITS+CACHE_SET_BITS-1:CACHE_OFFSET_BITS]
`define OFFSET_FROM_ADDR(addr) addr[CACHE_OFFSET_BITS-1:0]
`define CACHEDATA_ADDR(way, set, offset) (way*CACHE_SETS*CACHELINE_WORDS+set*CACHELINE_WORDS+offset)

//Bits in flag memory
parameter integer FLAG_LRU=0;
parameter integer FLAG_CW1_CLEAN=1;
parameter integer FLAG_CW2_CLEAN=2;

reg [3:0] cachedata_wen;
reg [31:0] cachedata_wdata;
wire [31:0] cachedata_rdata;
reg [CACHE_SET_BITS+CACHE_OFFSET_BITS:0] cachedata_addr;
reg [ADDR_WIDTH-1:0] caddr; //normally equals addr but when flushing will be controlled by the cache itself.

//We need to delay wen and ren by 1 clock cycle as the tag and flag memories are registered...
reg ren_delayed;
reg [3:0] wen_delayed;

// Capture QPI data on the strobe since we use it later
reg [31:0] qpi_rdata_r;
always @(posedge clk)
	if (qpi_next_word)
		qpi_rdata_r <= qpi_rdata;

//Cache memory, tag memory, flags memory.
simple_mem_words #(
	.WORDS(CACHELINE_CT*CACHELINE_WORDS),
`ifdef verilator
	.INITIAL_HEX("rom.hex")
`else
	.INITIAL_HEX("rom_random_seeds0x123456.hex")
`endif
) cachedata (
	.clk(clk),
	.wen(cachedata_wen),
	.addr(cachedata_addr),
	.wdata(cachedata_wdata),
	.rdata(cachedata_rdata)
);

assign rdata = cachedata_rdata;
wire [CACHE_TAG_BITS-1:0] tag_wdata;
wire [CACHE_TAG_BITS-1:0] tag_rdata[0:1];
reg [1:0] tag_wen;

genvar i;
for (i=0; i<2; i=i+1) begin
	simple_mem #(
		.WORDS(CACHE_SETS),
		.WIDTH(CACHE_TAG_BITS),
`ifdef verilator
		//Cache maps to nowhere in particular. This means psram should already be in qpi mode otherwise cache does not work.
		.INITIAL_FILL(i+800)
`else
		.INITIAL_FILL(i) //*10 is random: we want only the first 8K for simulation as the app is in the 2nd.
`endif
	) tagdata (
		.clk(clk),
		.wen(tag_wen[i]),
		.addr(`SET_FROM_ADDR(caddr)),
		.wdata(`TAG_FROM_ADDR(caddr)),
		.rdata(tag_rdata[i])
	);
end

reg flag_wen;
reg [2:0] flag_wdata;
wire [2:0] flag_rdata;

simple_mem #(
	.WORDS(CACHE_SETS),
	.WIDTH(3),
	.INITIAL_FILL('b0)
) flagdata (
	.clk(clk),
	.wen(flag_wen),
	.addr(`SET_FROM_ADDR(caddr)),
	.wdata(flag_wdata),
	.rdata(flag_rdata)
);

wire [CACHE_SET_BITS-1:0] current_set;
assign current_set = `SET_FROM_ADDR(caddr);


reg flushing;
reg [CACHE_SET_BITS-1:0] flush_line;
reg flush_way;

//Find the cache line the current address is located in.
reg cachehit_way;
reg found_tag; //this being 0 indicates a cache miss
wire doing_cache_refill;
reg [CACHE_OFFSET_BITS-1:0] cache_refill_offset;
reg [3:0] cache_refill_wen;
reg cache_refill_flag_wen;
always @(*) begin
	found_tag=0;
	cachehit_way=0;
	qpi_wdata = cachedata_rdata;
	flag_wdata = flag_rdata;
	flag_wen = 0;
	if (tag_rdata[0]==`TAG_FROM_ADDR(caddr)) begin
		found_tag=1;
		cachehit_way=0; //DO U KNOW THE WAY
		flag_wdata[FLAG_CW1_CLEAN] = flag_rdata[FLAG_CW1_CLEAN] && (wen_delayed == 0);
		flag_wdata[FLAG_CW2_CLEAN] = flag_rdata[FLAG_CW2_CLEAN];
		flag_wdata[FLAG_LRU]=1;
		flag_wen = (wen_delayed!=0 || ren_delayed);
	end else if (tag_rdata[1]==`TAG_FROM_ADDR(caddr)) begin
		found_tag=1;
		cachehit_way=1;
		flag_wdata[FLAG_CW1_CLEAN] = flag_rdata[FLAG_CW1_CLEAN];
		flag_wdata[FLAG_CW2_CLEAN] = flag_rdata[FLAG_CW2_CLEAN] && (wen_delayed == 0);
		flag_wdata[FLAG_LRU]=0;
		flag_wen = (wen_delayed!=0 || ren_delayed);
	end
	if (found_tag && !doing_cache_refill && !flushing) begin
		//Tag is found. Route the read or write to the cache data store
		cachedata_addr = `CACHEDATA_ADDR(cachehit_way, `SET_FROM_ADDR(caddr), `OFFSET_FROM_ADDR(caddr));
		cachedata_wen = wen_delayed;
		cachedata_wdata = wdata;
	end else begin
		//No tag. Switch over control of cache data to refill logic.
		if (flushing) begin
			cachedata_addr = `CACHEDATA_ADDR(flush_way, `SET_FROM_ADDR(caddr), cache_refill_offset);
		end else begin
			cachedata_addr = `CACHEDATA_ADDR(flag_rdata[FLAG_LRU], `SET_FROM_ADDR(caddr), cache_refill_offset);
		end
		//A cache line reload will always un-dirty the LRU page. Prepare the flags that indicate it so the
		//reload state machine only has to write them.
		if (flushing) begin
			flag_wdata[FLAG_CW1_CLEAN] = (flush_way==0) ? 1 : flag_rdata[FLAG_CW1_CLEAN];
			flag_wdata[FLAG_CW2_CLEAN] = (flush_way==1) ? 1 : flag_rdata[FLAG_CW2_CLEAN];
		end else begin
			flag_wdata[FLAG_CW1_CLEAN] = (flag_rdata[FLAG_LRU]==0) ? 1 : flag_rdata[FLAG_CW1_CLEAN];
			flag_wdata[FLAG_CW2_CLEAN] = (flag_rdata[FLAG_LRU]==1) ? 1 : flag_rdata[FLAG_CW2_CLEAN];
		end
		flag_wdata[FLAG_LRU] = flag_rdata[FLAG_LRU]; //doesn't matter actually
		flag_wen = cache_refill_flag_wen;
		cachedata_wdata = qpi_rdata_r;
		cachedata_wen = cache_refill_wen;
	end
end


wire flush_line_needs_flush;
wire need_cache_refill;
wire cache_line_lru;
wire cache_line_lru_clean;
//Assumption: ren/wen/addr will stay stable until we have signaled the memory is ready.
assign need_cache_refill = !found_tag && (ren_delayed || wen_delayed!=0) && (ren || wen!=0);
assign cache_line_lru = flag_rdata[FLAG_LRU];
assign cache_line_lru_clean = cache_line_lru ? 
		flag_rdata[FLAG_CW2_CLEAN] : 
		flag_rdata[FLAG_CW1_CLEAN];

//If flushing, flush_line and flush_way will cause caddr to iterate over the base address of each set in each
//way in the cache. We need to check here if 1. that address is in the range to be flushed (remember, when 
//flush=1, everything between addr and wdata should go) and 2. if it's dirty and actually needs to be flushed.
//If not flushing, this will be 0. Also note we count in words here; strip the last 2 bits off of wdata so we
//can feed the byte address in there.
assign flush_line_needs_flush = flushing &&
			((caddr >= addr) && (caddr < wdata[23:2]) 
			&& flag_rdata[flush_way?FLAG_CW2_CLEAN:FLAG_CW1_CLEAN]==0);

reg [CACHE_OFFSET_BITS-1:0] write_words_left;

assign doing_cache_refill = qpi_do_read || qpi_do_write;

//This muxes the current address (caddr) between the extenally-set address (for normal cache behaviour) and
//internally-generated addresses (for cache flush actions).
always @(*) begin
	if (!flushing) begin
		caddr <= addr; //just use external address
	end else begin
		//This is kinda roundabout... by setting the correct set here, we get the per-way tag from the tag memory
		//and we use that to set the tag here. It's more-or-less two operations in one go. The advantage here is that
		//we get the correct way selected by the address matching logic 'for free'.
		caddr <= {tag_rdata[flush_way], flush_line, {CACHE_OFFSET_BITS{1'b0}} };
	end
end

reg flush_delay_prop;
reg [64:0] cache_state_ascii;

always @(posedge clk) begin
	if (rst) begin
		qpi_do_read <= 0;
		qpi_do_write <= 0;
		qpi_addr <= 0;
		ready <= 0;
		cache_refill_flag_wen <= 0;
		tag_wen <= 0;
		cache_refill_offset <= 0;
		write_words_left <= 0;
		cache_refill_wen <= 0;
		flush_line <= 0;
		flush_way <= 0;
		flushing <= 0;
		flush_delay_prop <= 0;
	end else begin
		ready <= 0;
		cache_refill_flag_wen <= 0;
		tag_wen[0] <= 0;
		tag_wen[1] <= 0;
		cache_refill_wen <= 0;
		wen_delayed <= wen;
		ren_delayed <= ren;
		if (flush && !flushing) begin
			cache_state_ascii <= "FLSTART";
			flushing <= 1;
			flush_line <= 0;
			flush_way <= 0;
			flush_delay_prop <= 1;
		end else if (!flushing && found_tag && (ren_delayed || wen_delayed!=0) && !doing_cache_refill) begin
			//Cache hit
			cache_state_ascii <= "CACHEHIT";
			ready <= (wen!=0 || ren); //do not linger because the delayed signals do
		end else if (flush_delay_prop) begin
			//We're flushing and we just changed the address. Wait until that has propagated
			//through the tag/flag memory.
			cache_state_ascii <= "FLPROP";
			flush_delay_prop <= 0;
		end else if (!need_cache_refill && !flushing) begin
			cache_state_ascii <= "IDLE";
			//Nothing going on. Idle.
		end else if (!qpi_do_read && !qpi_do_write && !qpi_is_idle) begin
			//Done reading/writing, but we have to wait for the qpi iface to get idle again.
			cache_state_ascii <= "QPIWAIT";
		end else if (need_cache_refill || flush_line_needs_flush) begin
			//Tag not found! Grabbing from SPI memory.
			//Alternatively: flushing cache and this line needs writing back!
			if (!qpi_do_read && !qpi_do_write) begin
				//Start. See if we need to do writeback
				if (!cache_line_lru_clean || flush_line_needs_flush) begin
					cache_state_ascii <= "QPIWB";
					qpi_do_write <= 1;
					//Address is the address that the LRU has
					if (flushing) begin
						qpi_addr[ADDR_WIDTH+1:2+CACHE_OFFSET_BITS] <= {flush_way?tag_rdata[1]:tag_rdata[0], current_set};
					end else begin
						qpi_addr[ADDR_WIDTH+1:2+CACHE_OFFSET_BITS] <= {cache_line_lru?tag_rdata[1]:tag_rdata[0], current_set};
					end
					qpi_addr[2+CACHE_OFFSET_BITS-1:0] <= 0;
					write_words_left <= 'hffff; //all ones
					cache_refill_offset <= 0;
					//note: qpi memory always writes what's read from cachedata mem.
				end else begin
					cache_state_ascii <= "QPIRD";
					qpi_do_read <= 1;
					//Read from the address the user gave
					qpi_addr[ADDR_WIDTH+1:2+CACHE_OFFSET_BITS] <= {`TAG_FROM_ADDR(caddr), current_set};
					qpi_addr[2+CACHE_OFFSET_BITS-1:0] <= 0;
					cache_refill_offset <= -1;
					//note: on refill, cache always writes whatever comes from cachedata mem.
				end
			end else if (qpi_do_write && qpi_next_word) begin
				qpi_addr[2+CACHE_OFFSET_BITS-1:2] <= qpi_addr[2+CACHE_OFFSET_BITS-1:2] + 1;
				cache_refill_offset <= cache_refill_offset + 1;
				write_words_left <= write_words_left - 1;
				if ((write_words_left)==1) begin
					//last write of the cache line, mark cache line clean
					//Note that because we cleaned the cache line but there's still no cache hit,
					//the next round (after the qspi machine has gone idle), we'll do the actual
					//read of the cache line.
					qpi_do_write <= 0;
					//Un-dirtied flags are already prepared in the combinatorial logic; we just need to
					//write it.
					cache_refill_flag_wen <= 1;
				end
			end else if (qpi_do_read && qpi_next_word) begin
				qpi_addr[2+CACHE_OFFSET_BITS-1:2] <= qpi_addr[2+CACHE_OFFSET_BITS-1:2] + 1;
				cache_refill_offset <= cache_refill_offset + 1;
				cache_refill_wen <= 'hf;
				if (&qpi_addr[2+CACHE_OFFSET_BITS-1:2]) begin
					if (cache_line_lru == 0) begin
						tag_wen[0] <= 1;
					end else begin
						tag_wen[1] <= 1;
					end
					qpi_do_read <= 0;
				end
			end
		end else if (flushing && !flush_line_needs_flush) begin
			//Note: when flushing, flush_line/flush_way are used in a combinatorial
			//block above to pull the correct tag out of tag memory and send it to
			//caddr so the flushing mechanism can use it.
			cache_state_ascii <= "FLUSH";
			if ((&flush_line) && flush_way) begin
				flushing <= 0;
				ready <= 1;
			end else begin
				if (flush_way) begin
					flush_line <= flush_line + 1;
					flush_way <= 0;
				end else begin
					flush_way <= 1;
				end
				flush_delay_prop <= 1;
			end
		end
	end
end

endmodule