/*
Top module for FPGA. Essentially instantiates the SOC and adds the FPGA-specific things like
PLL, tristate buffers etc needed to interface with the hardware.
*/

module top_fpga(
		input clk, 
		input [7:0] btn, 
		output [8:0] led,
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
		inout [3:0] psramb_sio,
		output flash_cs,
		inout flash_miso,
		inout flash_mosi,
		inout flash_wp,
		inout flash_hold,
		
		output [3:0] gpdi_dp, gpdi_dn,
		inout usb_dp,
		inout usb_dm,
		output usb_pu
	);

	wire clk48m;

	wire clkint;
	OSCG #(
		.DIV(8) //155MHz by default... this divides it down to 19MHz.
	) oscint (
		.OSC(clkint)
	);

	wire [3:0] psrama_sout;
	wire [3:0] psrama_sin;
	wire psrama_oe;
	wire [3:0] psramb_sout;
	wire [3:0] psramb_sin;
	wire psramb_oe;

	wire vid_pixelclk;
	wire vid_fetch_next;
	wire vid_next_line;
	wire vid_next_field;
	wire [7:0] vid_red;
	wire [7:0] vid_green;
	wire [7:0] vid_blue;


	reg [31:0] jdreg_done;
	reg jdsel_done;
	reg jdreg_update;
	wire [31:0] jdreg_send;

	wire [3:0] flash_sout;
	wire [3:0] flash_sin;
	wire flash_oe;
	wire flash_bus_qpi;

	wire clkint;

	soc soc (
		.clk48m(clk48m),
		.clkint(clkint),
		.btn(btn),
		.led(led),
//		.genio(genio),
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
		.psramb_oe(psramb_oe),

		.flash_nce(flash_cs),
		.flash_sclk(flash_sclk),
		.flash_sin(flash_sin),
		.flash_sout(flash_sout),
		.flash_oe(flash_oe),
		.flash_bus_qpi(flash_bus_qpi),

		.vid_pixelclk(vid_pixelclk),
		.vid_fetch_next(vid_fetch_next),
		.vid_red(vid_red),
		.vid_green(vid_green),
		.vid_blue(vid_blue),
		.vid_next_line(vid_next_line),
		.vid_next_field(vid_next_field),

		.dbgreg_out(jdreg_send),
		.dbgreg_in(jdreg_done),
		.dbgreg_strobe(jdreg_update),
		.dbgreg_sel(jdsel_done), //0 for IR 0x32, 1 for IR 0x38

		.usb_dp(usb_dp),
		.usb_dn(usb_dm),
		.usb_pu(usb_pu)
	);


	pll_8_48 pll(
		.clki(clk),
		.clko(clk48m)
	);
//	assign clk=clk48m;

	hdmi_encoder hdmi_encoder(
		.clk_8m(clk),
		.gpdi_dp(gpdi_dp),
		.gpdi_dn(gpdi_dn),

		.pixelclk(vid_pixelclk),
		.fetch_next(vid_fetch_next),
		.red(vid_red),
		.green(vid_green),
		.blue(vid_blue),
		.next_line(vid_next_line),
		.next_field(vid_next_field),
	);

	genvar i;
	//Note: TRELLIS_IO has a T-ristate input, which does the opposite of OE.
	for (i=0; i<4; i++) begin
		TRELLIS_IO #(.DIR("BIDIR")) psrama_sio_tristate[i] (.I(psrama_sout[i]),.T(!psrama_oe),.B(psrama_sio[i]),.O(psrama_sin[i]));
		TRELLIS_IO #(.DIR("BIDIR")) psramb_sio_tristate[i] (.I(psramb_sout[i]),.T(!psramb_oe),.B(psramb_sio[i]),.O(psramb_sin[i]));
	end

	TRELLIS_IO #(.DIR("BIDIR")) flash_tristate_mosi (.I(flash_sout[0]),.T(flash_bus_qpi && !flash_oe),.B(flash_mosi),.O(flash_sin[0]));
	TRELLIS_IO #(.DIR("BIDIR")) flash_tristate_miso (.I(flash_sout[1]),.T(!flash_bus_qpi || !flash_oe),.B(flash_miso),.O(flash_sin[1]));
	TRELLIS_IO #(.DIR("BIDIR")) flash_tristate_wp (.I(flash_sout[2]),.T(flash_bus_qpi && !flash_oe),.B(flash_wp),.O(flash_sin[2]));
	TRELLIS_IO #(.DIR("BIDIR")) flash_tristate_hold (.I(flash_sout[3]),.T(flash_bus_qpi && !flash_oe),.B(flash_hold),.O(flash_sin[3]));

	USRMCLK usrmclk_inst (
		.USRMCLKI(flash_sclk),
		.USRMCLKTS(flash_cs)
	) /* synthesis syn_noprune=1 */;

	//Note: JTAG specs say we should sample on the rising edge of TCK. However, the LA readings show that 
	//this would be cutting it very close wrt sample/hold times... what's wise here?
	//Edit: Rising edge seems not to work. Using falling edge instead.
	//Note: TDO is not implemented atm.
	wire jtdi, jtck, jshift, jupdate, jce1, jce2, jrstn, jrti1, jrti2;
	JTAGG jtag(
		.JTDI(jtdi), //gets data
		.JTCK(jtck), //clock in
		.JRTI2(jrti1),  //1 if reg is selected and state is r/t idle
		.JRTI1(jrti2),
		.JSHIFT(jshift), //1 if data is shifted in
		.JUPDATE(jupdate), //1 for 1 tck on finish shifting
		.JRSTN(jrstn),
		.JCE2(jce2),  //1 if data shifted into this reg
		.JCE1(jce1)
	);

	assign genio[15]=jtdi;
	assign genio[14]=jtck;
	assign genio[13]=jshift;
	assign genio[12]=jupdate;
	assign genio[11]=jrstn;
	assign genio[10]=jce2;
	assign genio[9]=jce1;
	assign genio[8]=jrti2;
	assign genio[7]=jrti1;


	//Janky JTAG DR implementation.
	reg oldjshift;
	reg [3:0] tck_shift;
	reg [31:0] jdreg;
	reg jdsel;
	always @(posedge clk48m) begin
		jdreg_update <= 0;
		if (jrstn == 0) begin
			oldjshift <= jshift;
			jdreg <= 0;
			jdsel <= 0;
			tck_shift <= 0;
		end else begin
			tck_shift[3:1] <= tck_shift[2:0];
			tck_shift[0] <= jtck;
			if (tck_shift[3]==0 && tck_shift[2]==1) begin //somewhat after raising edge
				if (oldjshift) begin
					jdreg[30:0] <= jdreg[31:1];
					jdreg[31] <= jtdi;
				end
				if (jce1 || jce2) begin
					jdsel <= jce2;
				end
				if (jupdate) begin
					jdreg_done <= jdreg;
					jdsel_done <= jdsel;
					jdreg_update <= 1;
				end
				oldjshift <= jshift;
			end
		end
	end

endmodule
