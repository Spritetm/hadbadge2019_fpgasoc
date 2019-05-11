// File hdl/vga2dvid.vhd translated with vhd2vl v3.0 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 2001

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002-2017 Larry Doolittle
//     http://doolittle.icarus.com/~larry/vhd2vl/
//   Modifications (C) 2017 Rodrigo A. Melo
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

//------------------------------------------------------------------------------
// Engineer:		Mike Field <hamster@snap.net.nz>
// Description:	Converts VGA signals into DVID bitstreams.
//
//	'clk_shift' 10x clk_pixel for SDR
//      'clk_shift'  5x clk_pixel for DDR
//
//	'blank' should be asserted during the non-display 
//	portions of the frame
//------------------------------------------------------------------------------
// See: http://hamsterworks.co.nz/mediawiki/index.php/Dvid_test
//		http://hamsterworks.co.nz/mediawiki/index.php/FPGA_Projects
//
// Copyright (c) 2012 Mike Field <hamster@snap.net.nz>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// takes VGA input and prepares output
// for SDR buffer, which send 1 bit per 1 clock period output out_red(0), out_green(0), ... etc.
// for DDR buffers, which send 2 bits per 1 clock period output out_red(1 downto 0), ...
// EMARD unified SDR and DDR into one module
// no timescale needed

module vga2dvid(
input wire clk_pixel,
input wire clk_shift,
input wire [C_depth - 1:0] in_red,
input wire [C_depth - 1:0] in_green,
input wire [C_depth - 1:0] in_blue,
input wire in_blank,
input wire in_hsync,
input wire in_vsync,
output wire [9:0] outp_red,
output wire [9:0] outp_green,
output wire [9:0] outp_blue,
output wire [1:0] out_red,
output wire [1:0] out_green,
output wire [1:0] out_blue,
output wire [1:0] out_clock
);

parameter C_shift_clock_synchronizer=1'b1;
parameter C_parallel=1'b1;
parameter C_serial=1'b1;
parameter C_ddr=1'b0;
parameter [31:0] C_depth=8;
// VGA pixel clock, 25 MHz for 640x480
// SDR: 10x clk_pixel, DDR: 5x clk_pixel, in phase with clk_pixel
// parallel outputs
// serial outputs



wire [9:0] encoded_red; wire [9:0] encoded_green; wire [9:0] encoded_blue;
reg [9:0] latched_red = 1'b0; reg [9:0] latched_green = 1'b0; reg [9:0] latched_blue = 1'b0;
reg [9:0] shift_red = 1'b0; reg [9:0] shift_green = 1'b0; reg [9:0] shift_blue = 1'b0;
parameter C_shift_clock_initial = 10'b0000011111;
reg [9:0] shift_clock = C_shift_clock_initial;
reg R_shift_clock_off_sync = 1'b0;
reg [7:0] R_shift_clock_synchronizer = 1'b0;
reg [6:0] R_sync_fail;  // counts sync fails, after too many, reinitialize shift_clock
parameter c_red = 1'b0;
parameter c_green = 1'b0;
wire [1:0] c_blue;
wire [7:0] red_d;
wire [7:0] green_d;
wire [7:0] blue_d;

  assign c_blue = {in_vsync,in_hsync};
  assign red_d[7:8 - C_depth] = in_red[C_depth - 1:0];
  assign green_d[7:8 - C_depth] = in_green[C_depth - 1:0];
  assign blue_d[7:8 - C_depth] = in_blue[C_depth - 1:0];
  // fill vacant low bits with value repeated (so min/max value is always 0 or 255)
  //	G_bits: for i in 8-C_depth-1 downto 0 generate
  //	red_d(i)   <= in_red(0);
  //	green_d(i) <= in_green(0);
  //	blue_d(i)  <= in_blue(0);
  //	end generate;
  generate if (C_shift_clock_synchronizer == 1'b1) begin: G_shift_clock_synchronizer
      // sampler verifies is shift_clock state synchronous with pixel_clock
    always @(posedge clk_pixel) begin
      // does 0 to 1 transition at bits 5 downto 4 happen at rising_edge of clk_pixel?
      // if shift_clock = C_shift_clock_initial then
      if(shift_clock[5:4] == C_shift_clock_initial[5:4]) begin
        // same as above line but simplified 
        R_shift_clock_off_sync <= 1'b0;
      end
      else begin
        R_shift_clock_off_sync <= 1'b1;
      end
    end

    // every N cycles of clk_shift: signal to skip 1 cycle in order to get in sync
    always @(posedge clk_shift) begin
      if(R_shift_clock_off_sync == 1'b1) begin
        if(R_shift_clock_synchronizer[(7)] == 1'b1) begin
          R_shift_clock_synchronizer <= {8{1'b0}};
        end
        else begin
          R_shift_clock_synchronizer <= R_shift_clock_synchronizer + 1;
        end
      end
      else begin
        R_shift_clock_synchronizer <= {8{1'b0}};
      end
    end

  end
  endgenerate
  // shift_clock_synchronizer
  tmds_encoder u21(
      .clk(clk_pixel),
    .data(red_d),
    .c(c_red),
    .blank(in_blank),
    .encoded(encoded_red));

  tmds_encoder u22(
      .clk(clk_pixel),
    .data(green_d),
    .c(c_green),
    .blank(in_blank),
    .encoded(encoded_green));

  tmds_encoder u23(
      .clk(clk_pixel),
    .data(blue_d),
    .c(c_blue),
    .blank(in_blank),
    .encoded(encoded_blue));

  always @(posedge clk_pixel) begin
    latched_red <= encoded_red;
    latched_green <= encoded_green;
    latched_blue <= encoded_blue;
  end

  generate if (C_parallel == 1'b1) begin: G_parallel
      assign outp_red = latched_red;
    assign outp_green = latched_green;
    assign outp_blue = latched_blue;
  end
  endgenerate
  generate if ((C_serial &  ~C_ddr) == 1'b1) begin: G_SDR
      always @(posedge clk_shift) begin
      //if shift_clock = "0000011111" then
      if(shift_clock[5:4] == C_shift_clock_initial[5:4]) begin
        // same as above line but simplified
        shift_red <= latched_red;
        shift_green <= latched_green;
        shift_blue <= latched_blue;
      end
      else begin
        shift_red <= {1'b0,shift_red[9:1]};
        shift_green <= {1'b0,shift_green[9:1]};
        shift_blue <= {1'b0,shift_blue[9:1]};
      end
      if(R_shift_clock_synchronizer[(7)] == 1'b0) begin
        shift_clock <= {shift_clock[0],shift_clock[9:1]};
      end
      else begin
        // synchronization failed.
        // after too many fails, reinitialize shift_clock
        if(R_sync_fail[(6)] == 1'b1) begin
          shift_clock <= C_shift_clock_initial;
          R_sync_fail <= {7{1'b0}};
        end
        else begin
          R_sync_fail <= R_sync_fail + 1;
        end
      end
    end

  end
  endgenerate
  generate if ((C_serial & C_ddr) == 1'b1) begin: G_DDR
      always @(posedge clk_shift) begin
      //if shift_clock = "0000011111" then
      if(shift_clock[5:4] == C_shift_clock_initial[5:4]) begin
        // same as above line but simplified
        shift_red <= latched_red;
        shift_green <= latched_green;
        shift_blue <= latched_blue;
      end
      else begin
        shift_red <= {2'b00,shift_red[9:2]};
        shift_green <= {2'b00,shift_green[9:2]};
        shift_blue <= {2'b00,shift_blue[9:2]};
      end
      if(R_shift_clock_synchronizer[(7)] == 1'b0) begin
        shift_clock <= {shift_clock[1:0],shift_clock[9:2]};
      end
      else begin
        // synchronization failed.
        // after too many fails, reinitialize shift_clock
        if(R_sync_fail[(6)] == 1'b1) begin
          shift_clock <= C_shift_clock_initial;
          R_sync_fail <= {7{1'b0}};
        end
        else begin
          R_sync_fail <= R_sync_fail + 1;
        end
      end
    end

  end
  endgenerate
  // SDR: use only bit 0 from each out_* channel 
  // DDR: 2 bits per 1 clock period,
  // (one bit output on rising edge, other on falling edge of clk_shift)
  generate if (C_serial == 1'b1) begin: G_serial
      assign out_red = shift_red[1:0];
    assign out_green = shift_green[1:0];
    assign out_blue = shift_blue[1:0];
    assign out_clock = shift_clock[1:0];
  end
  endgenerate

endmodule
