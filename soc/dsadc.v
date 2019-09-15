/*
Silly first-order delta-sigma ADC. It uses a LVDS input with its negative pin connected
to a reference to sample the input signal. That LVDS input is used as a comparator, and the
reference signal should be connected to a RC filtering network filtering the output of
the refout signan. The RC filter works as the integrator and the LVDS pin as the 1-pin DAC
required for sigma-delta operation; the rest is done in the digital world.

We get the return value by simply sampling the delta-sigma stream and averaging the value of the bits.

In the badge, the RC filtering is done by an 10n/100ohm RC combo, giving a -3db point of
give-or-take 160KHz. As we're doing 10-but ADC with a clock of 48MHz, this means we
sample at 48KHz, which means the RC-filter should have enough time to settle.
*/

module dsadc (
	input clk,
	input rst, //also works as enable pin
	
	input difpin,
	output reg refout,
	output reg [9:0] adcval,
	output reg valid
);

reg [9:0] counter;
reg [9:0] accumulator;
reg first_after_reset;

always @(posedge clk) begin
	if (rst) begin
		refout <= 0;
		adcval <= 0;
		valid <= 0;
		first_after_reset <= 1;
		counter <= 1;
		accumulator <= 0;
	end else begin
		refout <= difpin; //this is the feedback bit of the adc
		counter <= counter + 1;
		if (counter == 0) begin
			if (first_after_reset) begin
				first_after_reset <= 0;
			end else begin
				adcval <= accumulator;
				valid <= 1;
			end
			accumulator <= 0;
		end else begin
			if (!difpin) begin 
				accumulator <= accumulator + 1;
			end
		end
	end
end

endmodule
