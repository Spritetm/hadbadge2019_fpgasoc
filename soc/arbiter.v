/*
This is an arbiter that allows multiple masters speaking the de-facto SOC memory protocol to 
talk to one memory bus. This protocol is like this:
- Master sets up address and (if needed) wdata, raises either ren or one or more wen lines
- Slave processes what it needs to process, and raises ready as soon as it is done (can 
  be combinatorial, same cycle)
- Slave lowers ready combinatorially if it's not selected (wen/ren is all 0) anymore.

ToDo: is 'ready' defined as such that we can assume that if r/w is asserted the clock after,
that this is a new request? Otherwise, we need three cycles minimum: setup r/w, assert ready, idle.
(At the moment, we wait until ren/wen is deasserted before switching devices, implying a 3-cycle
memory access.)

ToDo: For pipelining, we should allow a new request to somehow be slotted into the acknowledge
cycle... for now, we just allow half the bandwidth to masters (by needing both a request and
acknowledge cycle) and hope the slack is picked up by distributing all bandwidth over multiple
masters.
*/

/*
Note: Verilog-2005 (and Yosys, at this time of writing) do not support arrays as ports. Instead, we pack
n m-sized arrays into one n*m-sized array.
*/

module arbiter #(
	parameter integer MASTER_IFACE_CNT = 1
) (
	input clk, reset,
	input [32*MASTER_IFACE_CNT-1:0] addr,
	input [32*MASTER_IFACE_CNT-1:0] wdata,
	output reg [32*MASTER_IFACE_CNT-1:0] rdata,
	input [MASTER_IFACE_CNT-1:0] valid,
	input [4*MASTER_IFACE_CNT-1:0] wen,
	output reg [MASTER_IFACE_CNT-1:0] ready,
	output [31:0] currmaster,
	
	output reg [31:0] s_addr,
	output reg [31:0] s_wdata,
	input [31:0] s_rdata,
	output reg s_valid,
	output reg [3:0] s_wen,
	input s_ready
);

/*
The connected masters are priority-encoded by index; higher index = higher prio. We can do something more fanciful later
(round-robin, fractional priority, ...) but for now this is simple and stupid.
*/


`ifdef verilator
genvar i;
`else
integer i;
`endif


`define SLICE_32(v, i) v[32*i+:32]
`define SLICE_4(v, i) v[4*i+:4]

reg idle;
reg [$clog2(MASTER_IFACE_CNT)-1:0] active_iface;
reg hold;		//if 1, hold_iface is permanently routed to slave iface
reg [$clog2(MASTER_IFACE_CNT)-1:0] hold_iface;

assign currmaster = hold_iface;

always @(*) begin
	idle=0;
	active_iface=0;
	for (i=0; i<MASTER_IFACE_CNT; i=i+1) begin : genblk
		`SLICE_32(rdata, i)=s_rdata; //no need to mux this
		if ((hold && (hold_iface==i)) || ((!hold) && (valid[i]))) begin
			idle=0;
			active_iface=i;
		end
	end
	ready=0;
	s_addr=`SLICE_32(addr, active_iface);
	s_wdata=`SLICE_32(wdata,  active_iface);
	s_valid=valid[active_iface];
	s_wen=`SLICE_4(wen, active_iface);
	//Note: verilator complains about some circular dependency because of this line... no clue what it's on about.
	if (!idle) ready[active_iface]=s_ready;
//	if (hold) ready[hold_iface]=s_ready;
end

always @(posedge clk) begin
	if (reset) begin
		hold <= 0;
		hold_iface <= 0;
	end else begin
		if (hold && !valid[hold_iface]) begin
			//Read/write is done; un-hold
			hold <= 0;
		end else if (!idle) begin //note: idle is also 0 if hold was set last run
			//We're serving a device.
			hold <= 1;
			hold_iface <= active_iface;
		end else begin
			hold <= 0;
		end
	end
end

endmodule