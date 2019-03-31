module qpimem_cache #(
	//Simple 2-way cache.
	parameter integer CACHELINE_WORDS=4,
	parameter integer CACHELINE_CT=32,
	parameter integer ADDR_WIDTH=22 //addresses words
	//Cache size is CACHELINE_WORDS*CACHELINE_CT*4 bytes.
) (
	input clk,
	input rst,
	
	output reg qpi_do_read,
	output reg qpi_do_write,
	input qpi_next_byte,
	output reg [ADDR_WIDTH+2-1:0] qpi_addr, //note: this addresses bytes
	output reg [31:0] qpi_wdata,
	input [31:0] qpi_rdata,
	input qpi_is_idle,

	input [ADDR_WIDTH-1:0] addr,
	input [3:0] wen,
	input ren,
	input [31:0] wdata,
	output reg [31:0] rdata,
	output ready
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

//Bits in flag memory
parameter integer FLAG_LRU=0;
parameter integer FLAG_CW1_DIRTY=1;
parameter integer FLAG_CW2_DIRTY=2;

//Cache memory, tag memory, flags memory.
reg [31:0] cachedata [0:CACHELINE_CT*CACHELINE_WORDS-1];
reg [CACHE_TAG_BITS-1:0] tagdata [0:CACHELINE_CT-1];
reg [2:0] flagdata [0:(CACHE_SETS)-1];

//Easy accessor for cache/tag memory
`define CACHEDATA(way, set, offset) cachedata[way*CACHE_SETS*CACHELINE_WORDS+set*CACHELINE_WORDS+offset]
`define TAGDATA(way, set) tagdata[way*CACHE_SETS+set]

//Initial values for cache data
integer i;
initial begin
	for (i=0; i<CACHELINE_CT*CACHELINE_WORDS; i++) cachedata[i]=0;
	for (i=0; i<CACHE_SETS; i++) begin
		//make sure we don't have two cache lines pointing to the same address
		//plus, this works if we directly readmemh() into the cache ram.
		tagdata[i]=0;
		tagdata[i+CACHE_SETS]=1;
	end
	for (i=0; i<CACHE_SETS; i++) begin
		//Mark all cache as dirty: we want the preloaded cache to be written back to
		//main memory if needed.
		flagdata[i][FLAG_LRU]=0;
		flagdata[i][FLAG_CW1_DIRTY]=1;
		flagdata[i][FLAG_CW2_DIRTY]=1;
	end
end

wire [CACHE_SET_BITS-1:0] current_set;
assign current_set = `SET_FROM_ADDR(addr);

//Find the cache line the current address is located in.
reg cachehit_way;
reg found_tag; //this being 0 indicates a cache miss
always @(*) begin
	found_tag=0;
	if (`TAGDATA(0, current_set)==`TAG_FROM_ADDR(addr)) begin
		found_tag=1;
		cachehit_way=0; //DO U KNOW THE WAY
	end
	if (`TAGDATA(1, current_set)==`TAG_FROM_ADDR(addr)) begin
		found_tag=1;
		cachehit_way=1;
	end
end

//Idea here is if we don't find the tag, we have a cache miss. The tag will
//only be written after a cache hit, so we're ready by then.
assign ready = found_tag;

always @(posedge clk) begin
	if (rst) begin
		//na
	end else begin
		if (ren && found_tag) begin
			//Cache hit. Read, mark other line as LRU, return.
			flagdata[current_set][FLAG_LRU]<=!cachehit_way;
			rdata <= `CACHEDATA(cachehit_way, current_set, `OFFSET_FROM_ADDR(addr));
		end else if (wen!=0 && found_tag) begin
			//Cache hit for write. Mark other line as LRU first.
			flagdata[current_set][FLAG_LRU]<=!cachehit_way;
			//Mark cache line as dirty, so we'll do writeback
			if (cachehit_way) begin
				flagdata[current_set][FLAG_CW1_DIRTY]<=1;
			end else begin
				flagdata[current_set][FLAG_CW2_DIRTY]<=1;
			end
			//Change requested byte(s)
			if (wen[0]) `CACHEDATA(cachehit_way, current_set, `OFFSET_FROM_ADDR(addr))[7:0] <= wdata[7:0];
			if (wen[1]) `CACHEDATA(cachehit_way, current_set, `OFFSET_FROM_ADDR(addr))[15:8] <= wdata[15:8];
			if (wen[2]) `CACHEDATA(cachehit_way, current_set, `OFFSET_FROM_ADDR(addr))[23:16] <= wdata[23:16];
			if (wen[3]) `CACHEDATA(cachehit_way, current_set, `OFFSET_FROM_ADDR(addr))[31:24] <= wdata[31:24];
		end
	end
end


wire need_cache_refill;
wire cache_line_lru;
assign need_cache_refill = !found_tag && (ren || wen!=0);
assign cache_line_lru = flagdata[current_set][FLAG_LRU];
assign cache_line_lru_dirty = cache_line_lru ? 
		flagdata[current_set][FLAG_CW2_DIRTY] : 
		flagdata[current_set][FLAG_CW1_DIRTY];

always @(posedge clk) begin
	if (rst) begin
		qpi_do_read <= 0;
		qpi_do_write <= 0;
		qpi_addr <= 0;
		qpi_wdata <= 0;
	end else begin
		if (!need_cache_refill) begin
			//Whee, we can idle.
		end else if (!qpi_do_read && !qpi_do_write && !qpi_is_idle) begin
			//Done reading/writing, but we have no 
		end else if (need_cache_refill) begin
			//Tag not found! Grabbing from SPI memory.
			if (!qpi_do_read && !qpi_do_write) begin
				//Start. See if we need to do writeback
				if (cache_line_lru_dirty) begin
					qpi_do_write <= 1;
					//Address is the address that the LRU has
					qpi_addr[24:2+CACHE_OFFSET_BITS] <= {flagdata[current_set][FLAG_LRU]?`TAGDATA(1, current_set):`TAGDATA(0, current_set), current_set};
					qpi_addr[2+CACHE_OFFSET_BITS-1:0] <= 0;
					qpi_wdata <= `CACHEDATA(cache_line_lru, `SET_FROM_ADDR(addr), 0);
				end else begin
					qpi_do_read <= 1;
					//Read from the address the user gave
					qpi_addr[24:2+CACHE_OFFSET_BITS] <= {`TAG_FROM_ADDR(addr), current_set};
					qpi_addr[2+CACHE_OFFSET_BITS-1:0] <= 0;
				end
			end else if (qpi_do_write && qpi_next_byte) begin
				qpi_addr[2+CACHE_OFFSET_BITS-1:2] <= qpi_addr[2+CACHE_OFFSET_BITS-1:2] + 1;
				qpi_wdata <= `CACHEDATA(cache_line_lru, `SET_FROM_ADDR(addr), 0);
				if (&qpi_addr[2+CACHE_OFFSET_BITS-1:2]) begin
					//last write of the cache line, un-dirty cache line
					//Note that because we un-dirtied the cache line but there's still no cache hit,
					//the next round (after the qspi machine has gone idle), we'll do the actual
					//read of the cache line.
					qpi_do_write <= 0;
					if (cache_line_lru==0) flagdata[current_set][FLAG_CW1_DIRTY] <= 0;
					if (cache_line_lru==1) flagdata[current_set][FLAG_CW2_DIRTY] <= 0;
				end
			end else if (qpi_do_read && qpi_next_byte) begin
				`CACHEDATA(cache_line_lru, current_set, qpi_addr[2+CACHE_OFFSET_BITS-1:2]) <= qpi_rdata;
				qpi_addr[2+CACHE_OFFSET_BITS-1:2] <= qpi_addr[2+CACHE_OFFSET_BITS-1:2] + 1;
				if (&qpi_addr[2+CACHE_OFFSET_BITS-1:2]) begin
					`TAGDATA(cache_line_lru, `SET_FROM_ADDR(addr)) <= `TAG_FROM_ADDR(addr);
					qpi_do_read <= 0;
				end
			end
		end
	end
end

endmodule