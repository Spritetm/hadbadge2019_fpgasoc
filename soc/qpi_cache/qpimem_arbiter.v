/*
This is an arbiter that allows multiple masters speaking the QPI memory interface protocol to 
talk to one QPI memory device.
*/

/*
Note: Verilog-2005 (and Yosys, at this time of writing) do not support arrays as ports. Instead, we pack
n m-sized arrays into one n*m-sized array.
*/

module qpimem_arbiter #(
	parameter integer MASTER_IFACE_CNT = 1
) (
	input clk, reset,

	input [32*MASTER_IFACE_CNT-1:0] addr,
	input [32*MASTER_IFACE_CNT-1:0] wdata,
	output reg [32*MASTER_IFACE_CNT-1:0] rdata,
	input [MASTER_IFACE_CNT-1:0] do_read,
	input [MASTER_IFACE_CNT-1:0] do_write,
	output reg [MASTER_IFACE_CNT-1:0] next_byte,
	output reg [MASTER_IFACE_CNT-1:0] is_idle,
	
	output reg [31:0] s_addr,
	output reg [31:0] s_wdata,
	input [31:0] s_rdata,
	output reg s_do_write,
	output reg s_do_read,
	input s_is_idle,
	input s_next_byte
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

reg idle;
reg [$clog2(MASTER_IFACE_CNT)-1:0] active_iface;
reg hold;		//if 1, hold_iface is permanently routed to slave iface
reg [$clog2(MASTER_IFACE_CNT)-1:0] hold_iface;

always @(*) begin
	idle=0;
	active_iface=0;
	for (i=0; i<MASTER_IFACE_CNT; i=i+1) begin : genblk
		`SLICE_32(rdata, i)=s_rdata; //no need to mux this
		is_idle[i]=!(do_read[i] || do_write[i]); //we'll override this if selected
		next_byte[i]=0;
		if ((hold && (hold_iface==i)) || ((!hold) && (do_read[i] || do_write[i]))) begin
			idle=0;
			active_iface=i;
		end
	end
	s_addr=`SLICE_32(addr, active_iface);
	s_wdata=`SLICE_32(wdata,  active_iface);
	s_do_read=do_read[active_iface];
	s_do_write=do_write[active_iface];
	//Note: verilator complains about some circular dependency because of this line... no clue what it's on about.
	if (!idle) begin
		next_byte[active_iface]=s_next_byte;
		is_idle[active_iface]=s_is_idle;
	end
end

always @(posedge clk) begin
	if (reset) begin
		hold <= 0;
		hold_iface <= 0;
	end else begin
		if (hold && s_is_idle) begin
			//Read/write is done; un-hold
			hold <= 0;
		end else if (!idle) begin //note: idle is also 0 if hold was set last run
			//We're serving a master.
			hold <= 1;
			hold_iface <= active_iface;
		end else begin
			hold <= 0;
		end
	end
end

endmodule