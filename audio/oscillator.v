module oscillator 
// #()
(
        input clk, 
	input [18:0] increment ,  // determines pitch = f*2**28/maxclock
	// note: check the max value here.  is this reasonable?
	input [3:0] saw_vol,
	input [3:0] pulse_vol,
	input [3:0] triangle_vol,
	input [3:0] suboctave_vol,
	/* input [3:0] pulsewidth; */

	output [15:0] mix 
);

// DDS
reg [28:0] accumulator ;  // 28 bits plus sub-octave: should implement as always statement/flipflop?

reg [15:0] pulsewidth = 2**13; 
/* reg [23:0] lf_counter; */

wire [15:0] saw;
wire [15:0] pulse;
wire [15:0] triangle;
wire [15:0] suboctave;

/* Set up divider counter */
always @(posedge clk) begin 
	accumulator <= accumulator + increment;
	/* lfocounter <= lf_counter + 1; */
	/* pulsewidth <=  2**13 + (lf_counter[23] ? ~lf_counter[22:10] : lf_counter[22:10]) ; */
end

// just the upper 16 bits
assign saw = accumulator[27:12] >> (15-saw_vol) ; 
assign pulse = ( ( accumulator[27:12] < pulsewidth ) ? 17'hffff : 16'h0000  ) >> (15 - pulse_vol) ; // change to be fixed fractions of accumulator?  fewer bits?
assign suboctave = {16{accumulator[28]}} >> (15 - suboctave_vol);
assign triangle = (accumulator[27] ? ~accumulator[26:11] : accumulator[26:11]) >> (15 - triangle_vol) ;

assign mix =  triangle + saw + pulse + suboctave;
endmodule

