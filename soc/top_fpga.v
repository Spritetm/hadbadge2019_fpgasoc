/*
Top module for FPGA. Essentially instantiates the SOC and adds the FPGA-specific things like
PLL, tristate buffers etc needed to interface with the hardware.
*/

module top_fpga(
		input clk, 
		input [7:0] btn, 
		output [5:0] led,
		output [27:0] genio,
		output uart_tx,
		input uart_rx,
		output pwmout,
		output [17:0] lcd_db,
		output lcd_rd,
		output lcd_wr,
		output lcd_rs,
		output lcd_cs,
		input lcd_id,
		output lcd_rst,
		input lcd_fmark,
		output lcd_blen,
		output psrama_nce,
		output psrama_sclk,
		inout [3:0] psrama_sio,
		output psramb_nce,
		output psramb_sclk,
		inout [3:0] psramb_sio
	);

	wire clk48m;

	wire [3:0] psrama_sout;
	wire [3:0] psrama_sin;
	wire psrama_oe;
	wire [3:0] psramb_sout;
	wire [3:0] psramb_sin;
	wire psramb_oe;

	soc soc (
		.clk48m(clk48m),
		.btn(btn),
		.led(led),
		.genio(genio),
		.uart_tx(uart_tx),
		.uart_rx(uart_rx),
		.pwmout(pwmout),
		.lcd_db(lcd_db),
		.lcd_rd(lcd_rd),
		.lcd_wr(lcd_wr),
		.lcd_rs(lcd_rs),
		.lcd_cs(lcd_cs),
		.lcd_id(lcd_id),
		.lcd_rst(lcd_rst),
		.lcd_fmark(lcd_fmark),
		.lcd_blen(lcd_blen),
		.psrama_nce(psrama_nce),
		.psrama_sclk(psrama_sclk),
		.psrama_sout(psrama_sout),
		.psrama_sin(psrama_sin),
		.psrama_oe(psrama_oe),
		.psramb_nce(psramb_nce),
		.psramb_sclk(psramb_sclk),
		.psramb_sin(psramb_sin),
		.psramb_sout(psramb_sout),
		.psramb_oe(psramb_oe)
	);

	pll_8_48 pll(
		.clki(clk),
		.clko(clk48m)
	);

	genvar i;
	for (i=0; i<4; i++) begin
		TRELLIS_IO #(.DIR("BIDIR")) psrama_sio_tristate[i] (.I(psrama_sout[i]),.T(psrama_oe),.B(psrama_sio[i]),.O(psrama_sin[i]));
		TRELLIS_IO #(.DIR("BIDIR")) psramb_sio_tristate[i] (.I(psramb_sout[i]),.T(psramb_oe),.B(psramb_sio[i]),.O(psramb_sin[i]));
	end

endmodule
