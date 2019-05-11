// File hdl/vga.vhd translated with vhd2vl v3.0 VHDL to Verilog RTL translator
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

//
// Copyright (c) 2015 Davor Jadrijevic
// All rights reserved.
//
// LICENSE=BSD
//
// Generates VGA picture from sequential bitmap data from pixel clock
// synchronous FIFO.
// the pixel data in *_byte registers
// should be present ahead of time
// signal 'fetch_next' is set high for 1 clk_pixel
// period as soon as current pixel data is consumed
// fifo should be fast enough to fetch new data for
// new pixel
// use ieee.math_real.all; -- to calculate log2 bit size
// no timescale needed

module vga(
input wire clk_pixel,
input wire test_picture,
output wire fetch_next,
output wire line_repeat,
input wire [7:0] red_byte,
input wire [7:0] green_byte,
input wire [7:0] blue_byte,
output wire [7:0] vga_r,
output wire [7:0] vga_g,
output wire [7:0] vga_b,
output wire next_line,
output wire next_field,
output wire vga_hsync,
output wire vga_vsync,
output wire vga_vblank,
output wire vga_blank
);

parameter [31:0] C_resolution_x=640;
parameter [31:0] C_hsync_front_porch=16;
parameter [31:0] C_hsync_pulse=96;
parameter [31:0] C_hsync_back_porch=44;
parameter [31:0] C_resolution_y=480;
parameter [31:0] C_vsync_front_porch=10;
parameter [31:0] C_vsync_pulse=2;
parameter [31:0] C_vsync_back_porch=31;
parameter [31:0] C_bits_x=10;
parameter [31:0] C_bits_y=10;
parameter [31:0] C_dbl_x=0;
parameter [31:0] C_dbl_y=0;
// 0-normal X, 1-double X
// pixel clock, 25 MHz for 640x480
// show test picture
// request FIFO to fetch next pixel data
// request FIFO to repeat previous scan line content (used in y-doublescan)
//beam_x: out std_logic_vector(9 downto 0);
//beam_y: out std_logic_vector(9 downto 0);
// pixel data from FIFO
// 8-bit VGA video signal out
// VGA sync
// V blank for CPU interrupts and H+V blank for digital encoder (HDMI)



// function integer ceiling log2
// returns how many bits are needed to represent a number of states
// example ceil_log2(255) = 8,  ceil_log2(256) = 8, ceil_log2(257) = 9
//  function ceil_log2(x: integer) return integer is
//  begin
//    return integer(ceil((log2(real(x)+1.0E-6))-1.0E-6));
//  end ceil_log2;
parameter C_frame_x = C_resolution_x + C_hsync_front_porch + C_hsync_pulse + C_hsync_back_porch;  // frame_x = 640 + 16 + 96 + 48 = 800;
parameter C_frame_y = C_resolution_y + C_vsync_front_porch + C_vsync_pulse + C_vsync_back_porch;  // frame_y = 480 + 10 + 2 + 33 = 525;
// refresh_rate = pixel_clock/(frame_x*frame_y) = 25MHz / (800*525) = 59.52Hz
parameter C_synclen = 3;  // >=2, bit length of the clock synchronizer shift register
//constant C_bits_x: integer := 13; -- ceil_log2(C_frame_x-1)
//constant C_bits_y: integer := 11; -- ceil_log2(C_frame_y-1)
reg [C_bits_x - 1:0] CounterX;  // (9 downto 0) is good for up to 1023 frame timing width (resolution 640x480)
reg [C_bits_y - 1:0] CounterY;  // (9 downto 0) is good for up to 1023 frame timing width (resolution 640x480)
reg hSync; reg vSync; reg vBlank; reg DrawArea; wire fetcharea;
wire [C_synclen - 1:0] clksync;  // fifo to clock synchronizer shift register
wire [7:0] shift_red; wire [7:0] shift_green; wire [7:0] shift_blue;  // RENAME shift_ -> latch_
// test picture generation
wire [7:0] W; wire [7:0] A; wire [7:0] T; reg [7:0] test_red; reg [7:0] test_green; reg [7:0] test_blue;
wire [5:0] Z;

  // wire fetcharea; // when to fetch data, must be 1 byte earlier than draw area
  assign fetcharea = CounterX < C_resolution_x && CounterY < C_resolution_y ? 1'b1 : 1'b0;
  // output request to fetch new data every pixel
  assign fetch_next = fetcharea;
  // increment and wraparound X and Y counters
  always @(posedge clk_pixel) begin
    next_line <= 0;
    next_field <= 0;
    // DrawArea is fetcharea delayed one clock later
    DrawArea <= fetcharea;
    // on end of each X line, reset CounterX
    // and increment Y counter, also reset Y at bottom of screen
    if(CounterX == (C_frame_x - 1)) begin
      CounterX <= {(((C_bits_x - 1))-((0))+1){1'b0}};
      next_line <= 1;
      if(CounterY == (C_frame_y - 1)) begin
        CounterY <= {(((C_bits_y - 1))-((0))+1){1'b0}};
        next_field <= 1;
      end else begin
        CounterY <= CounterY + 1;
      end
    end
    else begin
      CounterX <= CounterX + 1;
    end
  end

  //beam_x <= CounterX;
  //beam_y <= CounterY;
  assign vga_blank =  ~DrawArea;
  // Sync and VBlank generation
  always @(posedge clk_pixel) begin
    if(CounterX == (C_resolution_x + C_hsync_front_porch)) begin
      hSync <= 1'b1;
    end
    if(CounterX == (C_resolution_x + C_hsync_front_porch + C_hsync_pulse)) begin
      hSync <= 1'b0;
    end
    if(CounterY == C_resolution_y) begin
      vBlank <= 1'b1;
    end
    if(CounterY == (C_resolution_y + C_vsync_front_porch)) begin
      vSync <= 1'b1;
    end
    if(CounterY == (C_resolution_y + C_vsync_front_porch + C_vsync_pulse)) begin
      vSync <= 1'b0;
      vBlank <= 1'b0;
    end
  end

  assign vga_hsync = hSync;
  assign vga_vsync = vSync;
  assign vga_vblank = vBlank;
  assign line_repeat = C_dbl_y == 0 ? 1'b0 : hSync &  ~CounterY[0];
  // test picture generator
  assign A = CounterX[7:5] == 3'b010 && CounterY[7:5] == 3'b010 ? {8{1'b1}} : {8{1'b0}};
  assign W = CounterX[7:0] == CounterY[7:0] ? {8{1'b1}} : {8{1'b0}};
  assign Z = CounterY[4:3] == ( ~CounterX[4:3]) ? {6{1'b1}} : {6{1'b0}};
  assign T = {8{CounterY[6]}};
  always @(posedge clk_pixel) begin
    test_red <= (({CounterX[5:0] & Z,2'b00}) | W) &  ~A;
    test_green <= ((CounterX[7:0] & T) | W) &  ~A;
    test_blue <= CounterY[7:0] | W | A;
  end

  // output multiplexer: bitmap graphics or test picture
  assign vga_r = DrawArea == 1'b0 ? {8{1'b0}} : test_picture == 1'b0 ? red_byte : test_red;
  assign vga_g = DrawArea == 1'b0 ? {8{1'b0}} : test_picture == 1'b0 ? green_byte : test_green;
  assign vga_b = DrawArea == 1'b0 ? {8{1'b0}} : test_picture == 1'b0 ? blue_byte : test_blue;

endmodule
