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

It *should* work even better with a r/c model to pass the sigma-delta stream through instead of
simply integrating it. (rc != perfect integrator)
*/

module dsadc (
	input clk,
	input rst, //also works as enable pin
	
	input difpin,
	input [4:0] divider,
	output reg refout,
	output reg [15:0] adcval,
	output reg valid
);

reg [4:0] divctr;
reg [15:0] counter;
reg [15:0] accumulator;
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
		if (divctr>=divider) begin
			divctr <= 0;
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
		end else begin
			divctr <= divctr + 1;
		end
	end
end

endmodule
