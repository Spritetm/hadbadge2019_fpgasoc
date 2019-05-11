//Generated using the Diamond tools because holy crap, I'm not going to enter all this manually...


`timescale 1 ns / 1 ps
module ecp5_dspmul32x32 ( 
    input wire CLK0,
    input wire CE0,
    input wire RST0,
    input wire SignA,
    input wire SignB,
    input wire [31:0] A,
    input wire [31:0] B,
    output wire [63:0] P
	);

	assign scuba_vlo=0;
	assign scuba_vhi=1;


    wire mult_alu_signedcin_1_0;
    wire mult_alu_in_cin_1_0_53;
    wire mult_alu_in_cin_1_0_52;
    wire mult_alu_in_cin_1_0_51;
    wire mult_alu_in_cin_1_0_50;
    wire mult_alu_in_cin_1_0_49;
    wire mult_alu_in_cin_1_0_48;
    wire mult_alu_in_cin_1_0_47;
    wire mult_alu_in_cin_1_0_46;
    wire mult_alu_in_cin_1_0_45;
    wire mult_alu_in_cin_1_0_44;
    wire mult_alu_in_cin_1_0_43;
    wire mult_alu_in_cin_1_0_42;
    wire mult_alu_in_cin_1_0_41;
    wire mult_alu_in_cin_1_0_40;
    wire mult_alu_in_cin_1_0_39;
    wire mult_alu_in_cin_1_0_38;
    wire mult_alu_in_cin_1_0_37;
    wire mult_alu_in_cin_1_0_36;
    wire mult_alu_in_cin_1_0_35;
    wire mult_alu_in_cin_1_0_34;
    wire mult_alu_in_cin_1_0_33;
    wire mult_alu_in_cin_1_0_32;
    wire mult_alu_in_cin_1_0_31;
    wire mult_alu_in_cin_1_0_30;
    wire mult_alu_in_cin_1_0_29;
    wire mult_alu_in_cin_1_0_28;
    wire mult_alu_in_cin_1_0_27;
    wire mult_alu_in_cin_1_0_26;
    wire mult_alu_in_cin_1_0_25;
    wire mult_alu_in_cin_1_0_24;
    wire mult_alu_in_cin_1_0_23;
    wire mult_alu_in_cin_1_0_22;
    wire mult_alu_in_cin_1_0_21;
    wire mult_alu_in_cin_1_0_20;
    wire mult_alu_in_cin_1_0_19;
    wire mult_alu_in_cin_1_0_18;
    wire mult_alu_in_cin_1_0_17;
    wire mult_alu_in_cin_1_0_16;
    wire mult_alu_in_cin_1_0_15;
    wire mult_alu_in_cin_1_0_14;
    wire mult_alu_in_cin_1_0_13;
    wire mult_alu_in_cin_1_0_12;
    wire mult_alu_in_cin_1_0_11;
    wire mult_alu_in_cin_1_0_10;
    wire mult_alu_in_cin_1_0_9;
    wire mult_alu_in_cin_1_0_8;
    wire mult_alu_in_cin_1_0_7;
    wire mult_alu_in_cin_1_0_6;
    wire mult_alu_in_cin_1_0_5;
    wire mult_alu_in_cin_1_0_4;
    wire mult_alu_in_cin_1_0_3;
    wire mult_alu_in_cin_1_0_2;
    wire mult_alu_in_cin_1_0_1;
    wire mult_alu_in_cin_1_0_0;
    wire mult_alu_signedr_2_1;
    wire mult_alu_output_r_2_1_53;
    wire mult_alu_output_r_2_1_52;
    wire mult_alu_output_r_2_1_51;
    wire mult_alu_output_r_2_1_50;
    wire mult_alu_output_r_2_1_49;
    wire mult_alu_output_r_2_1_48;
    wire mult_alu_output_r_2_1_47;
    wire mult_alu_output_r_2_1_46;
    wire mult_alu_output_r_2_1_45;
    wire mult_alu_output_r_2_1_44;
    wire mult_alu_output_r_2_1_43;
    wire mult_alu_output_r_2_1_42;
    wire mult_alu_output_r_2_1_41;
    wire mult_alu_output_r_2_1_40;
    wire mult_alu_output_r_2_1_39;
    wire mult_alu_output_r_2_1_38;
    wire mult_alu_output_r_2_1_37;
    wire mult_alu_output_r_2_1_36;
    wire mult_alu_output_r_2_1_35;
    wire mult_alu_output_r_2_1_34;
    wire mult_alu_output_r_2_1_33;
    wire mult_alu_output_r_2_1_32;
    wire mult_alu_output_r_2_1_31;
    wire mult_alu_output_r_2_1_30;
    wire mult_alu_output_r_2_1_29;
    wire mult_alu_output_r_2_1_28;
    wire mult_alu_output_r_2_1_27;
    wire mult_alu_output_r_2_1_26;
    wire mult_alu_output_r_2_1_25;
    wire mult_alu_output_r_2_1_24;
    wire mult_alu_output_r_2_1_23;
    wire mult_alu_output_r_2_1_22;
    wire mult_alu_output_r_2_1_21;
    wire mult_alu_output_r_2_1_20;
    wire mult_alu_output_r_2_1_19;
    wire mult_alu_output_r_2_1_18;
    wire mult_alu_output_r_2_1_17;
    wire mult_alu_output_r_2_1_16;
    wire mult_alu_output_r_2_1_15;
    wire mult_alu_output_r_2_1_14;
    wire mult_alu_output_r_2_1_13;
    wire mult_alu_output_r_2_1_12;
    wire mult_alu_output_r_2_1_11;
    wire mult_alu_output_r_2_1_10;
    wire mult_alu_output_r_2_1_9;
    wire mult_alu_output_r_2_1_8;
    wire mult_alu_output_r_2_1_7;
    wire mult_alu_output_r_2_1_6;
    wire mult_alu_output_r_2_1_5;
    wire mult_alu_output_r_2_1_4;
    wire mult_alu_output_r_2_1_3;
    wire mult_alu_output_r_2_1_2;
    wire mult_alu_output_r_2_1_1;
    wire mult_alu_output_r_2_1_0;
    wire mult_alu_signedr_1_0;
    wire mult_alu_output_r_1_0_53;
    wire mult_alu_output_r_1_0_52;
    wire mult_alu_output_r_1_0_51;
    wire mult_alu_output_r_1_0_50;
    wire mult_alu_output_r_1_0_49;
    wire mult_alu_output_r_1_0_48;
    wire mult_alu_output_r_1_0_47;
    wire mult_alu_output_r_1_0_46;
    wire mult_alu_output_r_1_0_45;
    wire mult_alu_output_r_1_0_44;
    wire mult_alu_output_r_1_0_43;
    wire mult_alu_output_r_1_0_42;
    wire mult_alu_output_r_1_0_41;
    wire mult_alu_output_r_1_0_40;
    wire mult_alu_output_r_1_0_39;
    wire mult_alu_output_r_1_0_38;
    wire mult_alu_output_r_1_0_37;
    wire mult_alu_output_r_1_0_36;
    wire mult_alu_output_r_1_0_35;
    wire mult_alu_output_r_1_0_34;
    wire mult_alu_output_r_1_0_33;
    wire mult_alu_output_r_1_0_32;
    wire mult_alu_output_r_1_0_31;
    wire mult_alu_output_r_1_0_30;
    wire mult_alu_output_r_1_0_29;
    wire mult_alu_output_r_1_0_28;
    wire mult_alu_output_r_1_0_27;
    wire mult_alu_output_r_1_0_26;
    wire mult_alu_output_r_1_0_25;
    wire mult_alu_output_r_1_0_24;
    wire mult_alu_output_r_1_0_23;
    wire mult_alu_output_r_1_0_22;
    wire mult_alu_output_r_1_0_21;
    wire mult_alu_output_r_1_0_20;
    wire mult_alu_output_r_1_0_19;
    wire mult_alu_output_r_1_0_18;
    wire mult_alu_output_r_1_0_17;
    wire mult_alu_output_r_1_0_16;
    wire mult_alu_output_r_1_0_15;
    wire mult_alu_output_r_1_0_14;
    wire mult_alu_output_r_1_0_13;
    wire mult_alu_output_r_1_0_12;
    wire mult_alu_output_r_1_0_11;
    wire mult_alu_output_r_1_0_10;
    wire mult_alu_output_r_1_0_9;
    wire mult_alu_output_r_1_0_8;
    wire mult_alu_output_r_1_0_7;
    wire mult_alu_output_r_1_0_6;
    wire mult_alu_output_r_1_0_5;
    wire mult_alu_output_r_1_0_4;
    wire mult_alu_output_r_1_0_3;
    wire mult_alu_output_r_1_0_2;
    wire mult_alu_output_r_1_0_1;
    wire mult_alu_output_r_1_0_0;
    wire mult_0_mult_out_rob_0_17;
    wire mult_0_mult_out_roa_0_17;
    wire mult_0_mult_out_rob_0_16;
    wire mult_0_mult_out_roa_0_16;
    wire mult_0_mult_out_rob_0_15;
    wire mult_0_mult_out_roa_0_15;
    wire mult_0_mult_out_rob_0_14;
    wire mult_0_mult_out_roa_0_14;
    wire mult_0_mult_out_rob_0_13;
    wire mult_0_mult_out_roa_0_13;
    wire mult_0_mult_out_rob_0_12;
    wire mult_0_mult_out_roa_0_12;
    wire mult_0_mult_out_rob_0_11;
    wire mult_0_mult_out_roa_0_11;
    wire mult_0_mult_out_rob_0_10;
    wire mult_0_mult_out_roa_0_10;
    wire mult_0_mult_out_rob_0_9;
    wire mult_0_mult_out_roa_0_9;
    wire mult_0_mult_out_rob_0_8;
    wire mult_0_mult_out_roa_0_8;
    wire mult_0_mult_out_rob_0_7;
    wire mult_0_mult_out_roa_0_7;
    wire mult_0_mult_out_rob_0_6;
    wire mult_0_mult_out_roa_0_6;
    wire mult_0_mult_out_rob_0_5;
    wire mult_0_mult_out_roa_0_5;
    wire mult_0_mult_out_rob_0_4;
    wire mult_0_mult_out_roa_0_4;
    wire mult_0_mult_out_rob_0_3;
    wire mult_0_mult_out_roa_0_3;
    wire mult_0_mult_out_rob_0_2;
    wire mult_0_mult_out_roa_0_2;
    wire mult_0_mult_out_rob_0_1;
    wire mult_0_mult_out_roa_0_1;
    wire mult_0_mult_out_rob_0_0;
    wire mult_0_mult_out_roa_0_0;
    wire mult_0_mult_out_p_0_35;
    wire mult_0_mult_out_p_0_34;
    wire mult_0_mult_out_p_0_33;
    wire mult_0_mult_out_p_0_32;
    wire mult_0_mult_out_p_0_31;
    wire mult_0_mult_out_p_0_30;
    wire mult_0_mult_out_p_0_29;
    wire mult_0_mult_out_p_0_28;
    wire mult_0_mult_out_p_0_27;
    wire mult_0_mult_out_p_0_26;
    wire mult_0_mult_out_p_0_25;
    wire mult_0_mult_out_p_0_24;
    wire mult_0_mult_out_p_0_23;
    wire mult_0_mult_out_p_0_22;
    wire mult_0_mult_out_p_0_21;
    wire mult_0_mult_out_p_0_20;
    wire mult_0_mult_out_p_0_19;
    wire mult_0_mult_out_p_0_18;
    wire mult_0_mult_out_p_0_17;
    wire mult_0_mult_out_p_0_16;
    wire mult_0_mult_out_p_0_15;
    wire mult_0_mult_out_p_0_14;
    wire mult_0_mult_out_p_0_13;
    wire mult_0_mult_out_p_0_12;
    wire mult_0_mult_out_p_0_11;
    wire mult_0_mult_out_p_0_10;
    wire mult_0_mult_out_p_0_9;
    wire mult_0_mult_out_p_0_8;
    wire mult_0_mult_out_p_0_7;
    wire mult_0_mult_out_p_0_6;
    wire mult_0_mult_out_p_0_5;
    wire mult_0_mult_out_p_0_4;
    wire mult_0_mult_out_p_0_3;
    wire mult_0_mult_out_p_0_2;
    wire mult_0_mult_out_p_0_1;
    wire mult_0_mult_out_p_0_0;
    wire mult_0_mult_out_signedp_0;
    wire mult_0_mult_out_rob_1_17;
    wire mult_0_mult_out_roa_1_17;
    wire mult_0_mult_out_rob_1_16;
    wire mult_0_mult_out_roa_1_16;
    wire mult_0_mult_out_rob_1_15;
    wire mult_0_mult_out_roa_1_15;
    wire mult_0_mult_out_rob_1_14;
    wire mult_0_mult_out_roa_1_14;
    wire mult_0_mult_out_rob_1_13;
    wire mult_0_mult_out_roa_1_13;
    wire mult_0_mult_out_rob_1_12;
    wire mult_0_mult_out_roa_1_12;
    wire mult_0_mult_out_rob_1_11;
    wire mult_0_mult_out_roa_1_11;
    wire mult_0_mult_out_rob_1_10;
    wire mult_0_mult_out_roa_1_10;
    wire mult_0_mult_out_rob_1_9;
    wire mult_0_mult_out_roa_1_9;
    wire mult_0_mult_out_rob_1_8;
    wire mult_0_mult_out_roa_1_8;
    wire mult_0_mult_out_rob_1_7;
    wire mult_0_mult_out_roa_1_7;
    wire mult_0_mult_out_rob_1_6;
    wire mult_0_mult_out_roa_1_6;
    wire mult_0_mult_out_rob_1_5;
    wire mult_0_mult_out_roa_1_5;
    wire mult_0_mult_out_rob_1_4;
    wire mult_0_mult_out_roa_1_4;
    wire mult_0_mult_out_rob_1_3;
    wire mult_0_mult_out_roa_1_3;
    wire mult_0_mult_out_rob_1_2;
    wire mult_0_mult_out_roa_1_2;
    wire mult_0_mult_out_rob_1_1;
    wire mult_0_mult_out_roa_1_1;
    wire mult_0_mult_out_rob_1_0;
    wire mult_0_mult_out_roa_1_0;
    wire mult_0_mult_out_p_1_35;
    wire mult_0_mult_out_p_1_34;
    wire mult_0_mult_out_p_1_33;
    wire mult_0_mult_out_p_1_32;
    wire mult_0_mult_out_p_1_31;
    wire mult_0_mult_out_p_1_30;
    wire mult_0_mult_out_p_1_29;
    wire mult_0_mult_out_p_1_28;
    wire mult_0_mult_out_p_1_27;
    wire mult_0_mult_out_p_1_26;
    wire mult_0_mult_out_p_1_25;
    wire mult_0_mult_out_p_1_24;
    wire mult_0_mult_out_p_1_23;
    wire mult_0_mult_out_p_1_22;
    wire mult_0_mult_out_p_1_21;
    wire mult_0_mult_out_p_1_20;
    wire mult_0_mult_out_p_1_19;
    wire mult_0_mult_out_p_1_18;
    wire mult_0_mult_out_p_1_17;
    wire mult_0_mult_out_p_1_16;
    wire mult_0_mult_out_p_1_15;
    wire mult_0_mult_out_p_1_14;
    wire mult_0_mult_out_p_1_13;
    wire mult_0_mult_out_p_1_12;
    wire mult_0_mult_out_p_1_11;
    wire mult_0_mult_out_p_1_10;
    wire mult_0_mult_out_p_1_9;
    wire mult_0_mult_out_p_1_8;
    wire mult_0_mult_out_p_1_7;
    wire mult_0_mult_out_p_1_6;
    wire mult_0_mult_out_p_1_5;
    wire mult_0_mult_out_p_1_4;
    wire mult_0_mult_out_p_1_3;
    wire mult_0_mult_out_p_1_2;
    wire mult_0_mult_out_p_1_1;
    wire mult_0_mult_out_p_1_0;
    wire mult_0_mult_out_signedp_1;
    wire mult_0_mult_out_rob_2_17;
    wire mult_0_mult_out_roa_2_17;
    wire mult_0_mult_out_rob_2_16;
    wire mult_0_mult_out_roa_2_16;
    wire mult_0_mult_out_rob_2_15;
    wire mult_0_mult_out_roa_2_15;
    wire mult_0_mult_out_rob_2_14;
    wire mult_0_mult_out_roa_2_14;
    wire mult_0_mult_out_rob_2_13;
    wire mult_0_mult_out_roa_2_13;
    wire mult_0_mult_out_rob_2_12;
    wire mult_0_mult_out_roa_2_12;
    wire mult_0_mult_out_rob_2_11;
    wire mult_0_mult_out_roa_2_11;
    wire mult_0_mult_out_rob_2_10;
    wire mult_0_mult_out_roa_2_10;
    wire mult_0_mult_out_rob_2_9;
    wire mult_0_mult_out_roa_2_9;
    wire mult_0_mult_out_rob_2_8;
    wire mult_0_mult_out_roa_2_8;
    wire mult_0_mult_out_rob_2_7;
    wire mult_0_mult_out_roa_2_7;
    wire mult_0_mult_out_rob_2_6;
    wire mult_0_mult_out_roa_2_6;
    wire mult_0_mult_out_rob_2_5;
    wire mult_0_mult_out_roa_2_5;
    wire mult_0_mult_out_rob_2_4;
    wire mult_0_mult_out_roa_2_4;
    wire mult_0_mult_out_rob_2_3;
    wire mult_0_mult_out_roa_2_3;
    wire mult_0_mult_out_rob_2_2;
    wire mult_0_mult_out_roa_2_2;
    wire mult_0_mult_out_rob_2_1;
    wire mult_0_mult_out_roa_2_1;
    wire mult_0_mult_out_rob_2_0;
    wire mult_0_mult_out_roa_2_0;
    wire mult_0_mult_out_p_2_35;
    wire mult_0_mult_out_p_2_34;
    wire mult_0_mult_out_p_2_33;
    wire mult_0_mult_out_p_2_32;
    wire mult_0_mult_out_p_2_31;
    wire mult_0_mult_out_p_2_30;
    wire mult_0_mult_out_p_2_29;
    wire mult_0_mult_out_p_2_28;
    wire mult_0_mult_out_p_2_27;
    wire mult_0_mult_out_p_2_26;
    wire mult_0_mult_out_p_2_25;
    wire mult_0_mult_out_p_2_24;
    wire mult_0_mult_out_p_2_23;
    wire mult_0_mult_out_p_2_22;
    wire mult_0_mult_out_p_2_21;
    wire mult_0_mult_out_p_2_20;
    wire mult_0_mult_out_p_2_19;
    wire mult_0_mult_out_p_2_18;
    wire mult_0_mult_out_p_2_17;
    wire mult_0_mult_out_p_2_16;
    wire mult_0_mult_out_p_2_15;
    wire mult_0_mult_out_p_2_14;
    wire mult_0_mult_out_p_2_13;
    wire mult_0_mult_out_p_2_12;
    wire mult_0_mult_out_p_2_11;
    wire mult_0_mult_out_p_2_10;
    wire mult_0_mult_out_p_2_9;
    wire mult_0_mult_out_p_2_8;
    wire mult_0_mult_out_p_2_7;
    wire mult_0_mult_out_p_2_6;
    wire mult_0_mult_out_p_2_5;
    wire mult_0_mult_out_p_2_4;
    wire mult_0_mult_out_p_2_3;
    wire mult_0_mult_out_p_2_2;
    wire mult_0_mult_out_p_2_1;
    wire mult_0_mult_out_p_2_0;
    wire mult_0_mult_out_signedp_2;
    wire mult_0_mult_out_rob_3_17;
    wire mult_0_mult_out_roa_3_17;
    wire mult_0_mult_out_rob_3_16;
    wire mult_0_mult_out_roa_3_16;
    wire mult_0_mult_out_rob_3_15;
    wire mult_0_mult_out_roa_3_15;
    wire mult_0_mult_out_rob_3_14;
    wire mult_0_mult_out_roa_3_14;
    wire mult_0_mult_out_rob_3_13;
    wire mult_0_mult_out_roa_3_13;
    wire mult_0_mult_out_rob_3_12;
    wire mult_0_mult_out_roa_3_12;
    wire mult_0_mult_out_rob_3_11;
    wire mult_0_mult_out_roa_3_11;
    wire mult_0_mult_out_rob_3_10;
    wire mult_0_mult_out_roa_3_10;
    wire mult_0_mult_out_rob_3_9;
    wire mult_0_mult_out_roa_3_9;
    wire mult_0_mult_out_rob_3_8;
    wire mult_0_mult_out_roa_3_8;
    wire mult_0_mult_out_rob_3_7;
    wire mult_0_mult_out_roa_3_7;
    wire mult_0_mult_out_rob_3_6;
    wire mult_0_mult_out_roa_3_6;
    wire mult_0_mult_out_rob_3_5;
    wire mult_0_mult_out_roa_3_5;
    wire mult_0_mult_out_rob_3_4;
    wire mult_0_mult_out_roa_3_4;
    wire mult_0_mult_out_rob_3_3;
    wire mult_0_mult_out_roa_3_3;
    wire mult_0_mult_out_rob_3_2;
    wire mult_0_mult_out_roa_3_2;
    wire mult_0_mult_out_rob_3_1;
    wire mult_0_mult_out_roa_3_1;
    wire mult_0_mult_out_rob_3_0;
    wire mult_0_mult_out_roa_3_0;
    wire mult_0_mult_out_p_3_35;
    wire mult_0_mult_out_p_3_34;
    wire mult_0_mult_out_p_3_33;
    wire mult_0_mult_out_p_3_32;
    wire mult_0_mult_out_p_3_31;
    wire mult_0_mult_out_p_3_30;
    wire mult_0_mult_out_p_3_29;
    wire mult_0_mult_out_p_3_28;
    wire mult_0_mult_out_p_3_27;
    wire mult_0_mult_out_p_3_26;
    wire mult_0_mult_out_p_3_25;
    wire mult_0_mult_out_p_3_24;
    wire mult_0_mult_out_p_3_23;
    wire mult_0_mult_out_p_3_22;
    wire mult_0_mult_out_p_3_21;
    wire mult_0_mult_out_p_3_20;
    wire mult_0_mult_out_p_3_19;
    wire mult_0_mult_out_p_3_18;
    wire mult_0_mult_out_p_3_17;
    wire mult_0_mult_out_p_3_16;
    wire mult_0_mult_out_p_3_15;
    wire mult_0_mult_out_p_3_14;
    wire mult_0_mult_out_p_3_13;
    wire mult_0_mult_out_p_3_12;
    wire mult_0_mult_out_p_3_11;
    wire mult_0_mult_out_p_3_10;
    wire mult_0_mult_out_p_3_9;
    wire mult_0_mult_out_p_3_8;
    wire mult_0_mult_out_p_3_7;
    wire mult_0_mult_out_p_3_6;
    wire mult_0_mult_out_p_3_5;
    wire mult_0_mult_out_p_3_4;
    wire mult_0_mult_out_p_3_3;
    wire mult_0_mult_out_p_3_2;
    wire mult_0_mult_out_p_3_1;
    wire mult_0_mult_out_p_3_0;
    wire mult_0_mult_out_signedp_3;
    wire mult_shift_out_b_4_1_1_17;
    wire mult_shift_out_b_4_1_1_16;
    wire mult_shift_out_b_4_1_1_15;
    wire mult_shift_out_b_4_1_1_14;
    wire mult_shift_out_b_4_1_1_13;
    wire mult_shift_out_b_4_1_1_12;
    wire mult_shift_out_b_4_1_1_11;
    wire mult_shift_out_b_4_1_1_10;
    wire mult_shift_out_b_4_1_1_9;
    wire mult_shift_out_b_4_1_1_8;
    wire mult_shift_out_b_4_1_1_7;
    wire mult_shift_out_b_4_1_1_6;
    wire mult_shift_out_b_4_1_1_5;
    wire mult_shift_out_b_4_1_1_4;
    wire mult_shift_out_b_4_1_1_3;
    wire mult_shift_out_b_4_1_1_2;
    wire mult_shift_out_b_4_1_1_1;
    wire mult_shift_out_b_4_1_1_0;
    wire scuba_vhi;
    wire scuba_vlo;

    defparam dsp_alu_1.CLK3_DIV = "ENABLED" ;
    defparam dsp_alu_1.CLK2_DIV = "ENABLED" ;
    defparam dsp_alu_1.CLK1_DIV = "ENABLED" ;
    defparam dsp_alu_1.CLK0_DIV = "ENABLED" ;
//    defparam dsp_alu_1.REG_INPUTCFB_RST = "RST0" ;
//    defparam dsp_alu_1.REG_INPUTCFB_CE = "CE0" ;
//    defparam dsp_alu_1.REG_INPUTCFB_CLK = "NONE" ;
    defparam dsp_alu_1.REG_OPCODEIN_1_RST = "RST0" ;
    defparam dsp_alu_1.REG_OPCODEIN_1_CE = "CE0" ;
    defparam dsp_alu_1.REG_OPCODEIN_1_CLK = "NONE" ;
    defparam dsp_alu_1.REG_OPCODEIN_0_RST = "RST0" ;
    defparam dsp_alu_1.REG_OPCODEIN_0_CE = "CE0" ;
    defparam dsp_alu_1.REG_OPCODEIN_0_CLK = "NONE" ;
//    defparam dsp_alu_1.REG_OPCODEOP1_1_CLK = "NONE" ;
    defparam dsp_alu_1.REG_OPCODEOP1_0_CLK = "NONE" ;
    defparam dsp_alu_1.REG_OPCODEOP0_1_RST = "RST0" ;
    defparam dsp_alu_1.REG_OPCODEOP0_1_CE = "CE0" ;
    defparam dsp_alu_1.REG_OPCODEOP0_1_CLK = "NONE" ;
    defparam dsp_alu_1.REG_OPCODEOP0_0_RST = "RST0" ;
    defparam dsp_alu_1.REG_OPCODEOP0_0_CE = "CE0" ;
    defparam dsp_alu_1.REG_OPCODEOP0_0_CLK = "NONE" ;
//    defparam dsp_alu_1.REG_INPUTC1_RST = "RST0" ;
//    defparam dsp_alu_1.REG_INPUTC1_CE = "CE0" ;
    defparam dsp_alu_1.REG_INPUTC1_CLK = "NONE" ;
//    defparam dsp_alu_1.REG_INPUTC0_RST = "RST0" ;
//    defparam dsp_alu_1.REG_INPUTC0_CE = "CE0" ;
    defparam dsp_alu_1.REG_INPUTC0_CLK = "NONE" ;
    defparam dsp_alu_1.LEGACY = "DISABLED" ;
//    defparam dsp_alu_1.REG_FLAG_RST = "RST0" ;
//    defparam dsp_alu_1.REG_FLAG_CE = "CE0" ;
    defparam dsp_alu_1.REG_FLAG_CLK = "NONE" ;
//    defparam dsp_alu_1.REG_OUTPUT1_RST = "RST0" ;
//    defparam dsp_alu_1.REG_OUTPUT1_CE = "CE0" ;
    defparam dsp_alu_1.REG_OUTPUT1_CLK = "NONE" ;
//    defparam dsp_alu_1.REG_OUTPUT0_RST = "RST0" ;
//    defparam dsp_alu_1.REG_OUTPUT0_CE = "CE0" ;
    defparam dsp_alu_1.REG_OUTPUT0_CLK = "CLK0" ;
//    defparam dsp_alu_1.MULT9_MODE = "DISABLED" ;
    defparam dsp_alu_1.RNDPAT = "0x00000000000000" ;
    defparam dsp_alu_1.MASKPAT = "0x00000000000000" ;
    defparam dsp_alu_1.MCPAT = "0x00000000000000" ;
    defparam dsp_alu_1.MASK01 = "0x00000000000000" ;
    defparam dsp_alu_1.MASKPAT_SOURCE = "STATIC" ;
    defparam dsp_alu_1.MCPAT_SOURCE = "STATIC" ;
    defparam dsp_alu_1.RESETMODE = "SYNC" ;
    defparam dsp_alu_1.GSR = "ENABLED" ;
    ALU54B dsp_alu_1 (.A35(mult_0_mult_out_rob_0_17), .A34(mult_0_mult_out_rob_0_16), 
        .A33(mult_0_mult_out_rob_0_15), .A32(mult_0_mult_out_rob_0_14), 
        .A31(mult_0_mult_out_rob_0_13), .A30(mult_0_mult_out_rob_0_12), 
        .A29(mult_0_mult_out_rob_0_11), .A28(mult_0_mult_out_rob_0_10), 
        .A27(mult_0_mult_out_rob_0_9), .A26(mult_0_mult_out_rob_0_8), .A25(mult_0_mult_out_rob_0_7), 
        .A24(mult_0_mult_out_rob_0_6), .A23(mult_0_mult_out_rob_0_5), .A22(mult_0_mult_out_rob_0_4), 
        .A21(mult_0_mult_out_rob_0_3), .A20(mult_0_mult_out_rob_0_2), .A19(mult_0_mult_out_rob_0_1), 
        .A18(mult_0_mult_out_rob_0_0), .A17(mult_0_mult_out_roa_0_17), .A16(mult_0_mult_out_roa_0_16), 
        .A15(mult_0_mult_out_roa_0_15), .A14(mult_0_mult_out_roa_0_14), 
        .A13(mult_0_mult_out_roa_0_13), .A12(mult_0_mult_out_roa_0_12), 
        .A11(mult_0_mult_out_roa_0_11), .A10(mult_0_mult_out_roa_0_10), 
        .A9(mult_0_mult_out_roa_0_9), .A8(mult_0_mult_out_roa_0_8), .A7(mult_0_mult_out_roa_0_7), 
        .A6(mult_0_mult_out_roa_0_6), .A5(mult_0_mult_out_roa_0_5), .A4(mult_0_mult_out_roa_0_4), 
        .A3(mult_0_mult_out_roa_0_3), .A2(mult_0_mult_out_roa_0_2), .A1(mult_0_mult_out_roa_0_1), 
        .A0(mult_0_mult_out_roa_0_0), .B35(mult_0_mult_out_rob_1_17), .B34(mult_0_mult_out_rob_1_16), 
        .B33(mult_0_mult_out_rob_1_15), .B32(mult_0_mult_out_rob_1_14), 
        .B31(mult_0_mult_out_rob_1_13), .B30(mult_0_mult_out_rob_1_12), 
        .B29(mult_0_mult_out_rob_1_11), .B28(mult_0_mult_out_rob_1_10), 
        .B27(mult_0_mult_out_rob_1_9), .B26(mult_0_mult_out_rob_1_8), .B25(mult_0_mult_out_rob_1_7), 
        .B24(mult_0_mult_out_rob_1_6), .B23(mult_0_mult_out_rob_1_5), .B22(mult_0_mult_out_rob_1_4), 
        .B21(mult_0_mult_out_rob_1_3), .B20(mult_0_mult_out_rob_1_2), .B19(mult_0_mult_out_rob_1_1), 
        .B18(mult_0_mult_out_rob_1_0), .B17(mult_0_mult_out_roa_1_17), .B16(mult_0_mult_out_roa_1_16), 
        .B15(mult_0_mult_out_roa_1_15), .B14(mult_0_mult_out_roa_1_14), 
        .B13(mult_0_mult_out_roa_1_13), .B12(mult_0_mult_out_roa_1_12), 
        .B11(mult_0_mult_out_roa_1_11), .B10(mult_0_mult_out_roa_1_10), 
        .B9(mult_0_mult_out_roa_1_9), .B8(mult_0_mult_out_roa_1_8), .B7(mult_0_mult_out_roa_1_7), 
        .B6(mult_0_mult_out_roa_1_6), .B5(mult_0_mult_out_roa_1_5), .B4(mult_0_mult_out_roa_1_4), 
        .B3(mult_0_mult_out_roa_1_3), .B2(mult_0_mult_out_roa_1_2), .B1(mult_0_mult_out_roa_1_1), 
        .B0(mult_0_mult_out_roa_1_0), .CFB53(scuba_vlo), .CFB52(scuba_vlo), 
        .CFB51(scuba_vlo), .CFB50(scuba_vlo), .CFB49(scuba_vlo), .CFB48(scuba_vlo), 
        .CFB47(scuba_vlo), .CFB46(scuba_vlo), .CFB45(scuba_vlo), .CFB44(scuba_vlo), 
        .CFB43(scuba_vlo), .CFB42(scuba_vlo), .CFB41(scuba_vlo), .CFB40(scuba_vlo), 
        .CFB39(scuba_vlo), .CFB38(scuba_vlo), .CFB37(scuba_vlo), .CFB36(scuba_vlo), 
        .CFB35(scuba_vlo), .CFB34(scuba_vlo), .CFB33(scuba_vlo), .CFB32(scuba_vlo), 
        .CFB31(scuba_vlo), .CFB30(scuba_vlo), .CFB29(scuba_vlo), .CFB28(scuba_vlo), 
        .CFB27(scuba_vlo), .CFB26(scuba_vlo), .CFB25(scuba_vlo), .CFB24(scuba_vlo), 
        .CFB23(scuba_vlo), .CFB22(scuba_vlo), .CFB21(scuba_vlo), .CFB20(scuba_vlo), 
        .CFB19(scuba_vlo), .CFB18(scuba_vlo), .CFB17(scuba_vlo), .CFB16(scuba_vlo), 
        .CFB15(scuba_vlo), .CFB14(scuba_vlo), .CFB13(scuba_vlo), .CFB12(scuba_vlo), 
        .CFB11(scuba_vlo), .CFB10(scuba_vlo), .CFB9(scuba_vlo), .CFB8(scuba_vlo), 
        .CFB7(scuba_vlo), .CFB6(scuba_vlo), .CFB5(scuba_vlo), .CFB4(scuba_vlo), 
        .CFB3(scuba_vlo), .CFB2(scuba_vlo), .CFB1(scuba_vlo), .CFB0(scuba_vlo), 
        .C53(scuba_vlo), .C52(scuba_vlo), .C51(scuba_vlo), .C50(scuba_vlo), 
        .C49(scuba_vlo), .C48(scuba_vlo), .C47(scuba_vlo), .C46(scuba_vlo), 
        .C45(scuba_vlo), .C44(scuba_vlo), .C43(scuba_vlo), .C42(scuba_vlo), 
        .C41(scuba_vlo), .C40(scuba_vlo), .C39(scuba_vlo), .C38(scuba_vlo), 
        .C37(scuba_vlo), .C36(scuba_vlo), .C35(scuba_vlo), .C34(scuba_vlo), 
        .C33(scuba_vlo), .C32(scuba_vlo), .C31(scuba_vlo), .C30(scuba_vlo), 
        .C29(scuba_vlo), .C28(scuba_vlo), .C27(scuba_vlo), .C26(scuba_vlo), 
        .C25(scuba_vlo), .C24(scuba_vlo), .C23(scuba_vlo), .C22(scuba_vlo), 
        .C21(scuba_vlo), .C20(scuba_vlo), .C19(scuba_vlo), .C18(scuba_vlo), 
        .C17(scuba_vlo), .C16(scuba_vlo), .C15(scuba_vlo), .C14(scuba_vlo), 
        .C13(scuba_vlo), .C12(scuba_vlo), .C11(scuba_vlo), .C10(scuba_vlo), 
        .C9(scuba_vlo), .C8(scuba_vlo), .C7(scuba_vlo), .C6(scuba_vlo), 
        .C5(scuba_vlo), .C4(scuba_vlo), .C3(scuba_vlo), .C2(scuba_vlo), 
        .C1(scuba_vlo), .C0(scuba_vlo), .CE0(CE0), .CE1(scuba_vhi), .CE2(scuba_vhi), 
        .CE3(scuba_vhi), .CLK0(CLK0), .CLK1(CLK0), .CLK2(scuba_vlo), .CLK3(scuba_vlo), 
        .RST0(RST0), .RST1(scuba_vlo), .RST2(scuba_vlo), .RST3(scuba_vlo), 
        .SIGNEDIA(mult_0_mult_out_signedp_0), .SIGNEDIB(mult_0_mult_out_signedp_1), 
        .SIGNEDCIN(mult_alu_signedcin_1_0), .MA35(mult_0_mult_out_p_0_35), 
        .MA34(mult_0_mult_out_p_0_34), .MA33(mult_0_mult_out_p_0_33), .MA32(mult_0_mult_out_p_0_32), 
        .MA31(mult_0_mult_out_p_0_31), .MA30(mult_0_mult_out_p_0_30), .MA29(mult_0_mult_out_p_0_29), 
        .MA28(mult_0_mult_out_p_0_28), .MA27(mult_0_mult_out_p_0_27), .MA26(mult_0_mult_out_p_0_26), 
        .MA25(mult_0_mult_out_p_0_25), .MA24(mult_0_mult_out_p_0_24), .MA23(mult_0_mult_out_p_0_23), 
        .MA22(mult_0_mult_out_p_0_22), .MA21(mult_0_mult_out_p_0_21), .MA20(mult_0_mult_out_p_0_20), 
        .MA19(mult_0_mult_out_p_0_19), .MA18(mult_0_mult_out_p_0_18), .MA17(mult_0_mult_out_p_0_17), 
        .MA16(mult_0_mult_out_p_0_16), .MA15(mult_0_mult_out_p_0_15), .MA14(mult_0_mult_out_p_0_14), 
        .MA13(mult_0_mult_out_p_0_13), .MA12(mult_0_mult_out_p_0_12), .MA11(mult_0_mult_out_p_0_11), 
        .MA10(mult_0_mult_out_p_0_10), .MA9(mult_0_mult_out_p_0_9), .MA8(mult_0_mult_out_p_0_8), 
        .MA7(mult_0_mult_out_p_0_7), .MA6(mult_0_mult_out_p_0_6), .MA5(mult_0_mult_out_p_0_5), 
        .MA4(mult_0_mult_out_p_0_4), .MA3(mult_0_mult_out_p_0_3), .MA2(mult_0_mult_out_p_0_2), 
        .MA1(mult_0_mult_out_p_0_1), .MA0(mult_0_mult_out_p_0_0), .MB35(mult_0_mult_out_p_1_35), 
        .MB34(mult_0_mult_out_p_1_34), .MB33(mult_0_mult_out_p_1_33), .MB32(mult_0_mult_out_p_1_32), 
        .MB31(mult_0_mult_out_p_1_31), .MB30(mult_0_mult_out_p_1_30), .MB29(mult_0_mult_out_p_1_29), 
        .MB28(mult_0_mult_out_p_1_28), .MB27(mult_0_mult_out_p_1_27), .MB26(mult_0_mult_out_p_1_26), 
        .MB25(mult_0_mult_out_p_1_25), .MB24(mult_0_mult_out_p_1_24), .MB23(mult_0_mult_out_p_1_23), 
        .MB22(mult_0_mult_out_p_1_22), .MB21(mult_0_mult_out_p_1_21), .MB20(mult_0_mult_out_p_1_20), 
        .MB19(mult_0_mult_out_p_1_19), .MB18(mult_0_mult_out_p_1_18), .MB17(mult_0_mult_out_p_1_17), 
        .MB16(mult_0_mult_out_p_1_16), .MB15(mult_0_mult_out_p_1_15), .MB14(mult_0_mult_out_p_1_14), 
        .MB13(mult_0_mult_out_p_1_13), .MB12(mult_0_mult_out_p_1_12), .MB11(mult_0_mult_out_p_1_11), 
        .MB10(mult_0_mult_out_p_1_10), .MB9(mult_0_mult_out_p_1_9), .MB8(mult_0_mult_out_p_1_8), 
        .MB7(mult_0_mult_out_p_1_7), .MB6(mult_0_mult_out_p_1_6), .MB5(mult_0_mult_out_p_1_5), 
        .MB4(mult_0_mult_out_p_1_4), .MB3(mult_0_mult_out_p_1_3), .MB2(mult_0_mult_out_p_1_2), 
        .MB1(mult_0_mult_out_p_1_1), .MB0(mult_0_mult_out_p_1_0), .CIN53(mult_alu_in_cin_1_0_53), 
        .CIN52(mult_alu_in_cin_1_0_52), .CIN51(mult_alu_in_cin_1_0_51), 
        .CIN50(mult_alu_in_cin_1_0_50), .CIN49(mult_alu_in_cin_1_0_49), 
        .CIN48(mult_alu_in_cin_1_0_48), .CIN47(mult_alu_in_cin_1_0_47), 
        .CIN46(mult_alu_in_cin_1_0_46), .CIN45(mult_alu_in_cin_1_0_45), 
        .CIN44(mult_alu_in_cin_1_0_44), .CIN43(mult_alu_in_cin_1_0_43), 
        .CIN42(mult_alu_in_cin_1_0_42), .CIN41(mult_alu_in_cin_1_0_41), 
        .CIN40(mult_alu_in_cin_1_0_40), .CIN39(mult_alu_in_cin_1_0_39), 
        .CIN38(mult_alu_in_cin_1_0_38), .CIN37(mult_alu_in_cin_1_0_37), 
        .CIN36(mult_alu_in_cin_1_0_36), .CIN35(mult_alu_in_cin_1_0_35), 
        .CIN34(mult_alu_in_cin_1_0_34), .CIN33(mult_alu_in_cin_1_0_33), 
        .CIN32(mult_alu_in_cin_1_0_32), .CIN31(mult_alu_in_cin_1_0_31), 
        .CIN30(mult_alu_in_cin_1_0_30), .CIN29(mult_alu_in_cin_1_0_29), 
        .CIN28(mult_alu_in_cin_1_0_28), .CIN27(mult_alu_in_cin_1_0_27), 
        .CIN26(mult_alu_in_cin_1_0_26), .CIN25(mult_alu_in_cin_1_0_25), 
        .CIN24(mult_alu_in_cin_1_0_24), .CIN23(mult_alu_in_cin_1_0_23), 
        .CIN22(mult_alu_in_cin_1_0_22), .CIN21(mult_alu_in_cin_1_0_21), 
        .CIN20(mult_alu_in_cin_1_0_20), .CIN19(mult_alu_in_cin_1_0_19), 
        .CIN18(mult_alu_in_cin_1_0_18), .CIN17(mult_alu_in_cin_1_0_17), 
        .CIN16(mult_alu_in_cin_1_0_16), .CIN15(mult_alu_in_cin_1_0_15), 
        .CIN14(mult_alu_in_cin_1_0_14), .CIN13(mult_alu_in_cin_1_0_13), 
        .CIN12(mult_alu_in_cin_1_0_12), .CIN11(mult_alu_in_cin_1_0_11), 
        .CIN10(mult_alu_in_cin_1_0_10), .CIN9(mult_alu_in_cin_1_0_9), .CIN8(mult_alu_in_cin_1_0_8), 
        .CIN7(mult_alu_in_cin_1_0_7), .CIN6(mult_alu_in_cin_1_0_6), .CIN5(mult_alu_in_cin_1_0_5), 
        .CIN4(mult_alu_in_cin_1_0_4), .CIN3(mult_alu_in_cin_1_0_3), .CIN2(mult_alu_in_cin_1_0_2), 
        .CIN1(mult_alu_in_cin_1_0_1), .CIN0(mult_alu_in_cin_1_0_0), .OP10(scuba_vlo), 
        .OP9(scuba_vhi), .OP8(scuba_vlo), .OP7(scuba_vlo), .OP6(scuba_vlo), 
        .OP5(scuba_vlo), .OP4(scuba_vlo), .OP3(scuba_vlo), .OP2(scuba_vlo), 
        .OP1(scuba_vlo), .OP0(scuba_vhi), .R53(mult_alu_output_r_1_0_53), 
        .R52(mult_alu_output_r_1_0_52), .R51(mult_alu_output_r_1_0_51), 
        .R50(mult_alu_output_r_1_0_50), .R49(mult_alu_output_r_1_0_49), 
        .R48(mult_alu_output_r_1_0_48), .R47(mult_alu_output_r_1_0_47), 
        .R46(mult_alu_output_r_1_0_46), .R45(mult_alu_output_r_1_0_45), 
        .R44(mult_alu_output_r_1_0_44), .R43(mult_alu_output_r_1_0_43), 
        .R42(mult_alu_output_r_1_0_42), .R41(mult_alu_output_r_1_0_41), 
        .R40(mult_alu_output_r_1_0_40), .R39(mult_alu_output_r_1_0_39), 
        .R38(mult_alu_output_r_1_0_38), .R37(mult_alu_output_r_1_0_37), 
        .R36(mult_alu_output_r_1_0_36), .R35(mult_alu_output_r_1_0_35), 
        .R34(mult_alu_output_r_1_0_34), .R33(mult_alu_output_r_1_0_33), 
        .R32(mult_alu_output_r_1_0_32), .R31(mult_alu_output_r_1_0_31), 
        .R30(mult_alu_output_r_1_0_30), .R29(mult_alu_output_r_1_0_29), 
        .R28(mult_alu_output_r_1_0_28), .R27(mult_alu_output_r_1_0_27), 
        .R26(mult_alu_output_r_1_0_26), .R25(mult_alu_output_r_1_0_25), 
        .R24(mult_alu_output_r_1_0_24), .R23(mult_alu_output_r_1_0_23), 
        .R22(mult_alu_output_r_1_0_22), .R21(mult_alu_output_r_1_0_21), 
        .R20(mult_alu_output_r_1_0_20), .R19(mult_alu_output_r_1_0_19), 
        .R18(mult_alu_output_r_1_0_18), .R17(mult_alu_output_r_1_0_17), 
        .R16(mult_alu_output_r_1_0_16), .R15(mult_alu_output_r_1_0_15), 
        .R14(mult_alu_output_r_1_0_14), .R13(mult_alu_output_r_1_0_13), 
        .R12(mult_alu_output_r_1_0_12), .R11(mult_alu_output_r_1_0_11), 
        .R10(mult_alu_output_r_1_0_10), .R9(mult_alu_output_r_1_0_9), .R8(mult_alu_output_r_1_0_8), 
        .R7(mult_alu_output_r_1_0_7), .R6(mult_alu_output_r_1_0_6), .R5(mult_alu_output_r_1_0_5), 
        .R4(mult_alu_output_r_1_0_4), .R3(mult_alu_output_r_1_0_3), .R2(mult_alu_output_r_1_0_2), 
        .R1(mult_alu_output_r_1_0_1), .R0(mult_alu_output_r_1_0_0), .CO53(), 
        .CO52(), .CO51(), .CO50(), .CO49(), .CO48(), .CO47(), .CO46(), .CO45(), 
        .CO44(), .CO43(), .CO42(), .CO41(), .CO40(), .CO39(), .CO38(), .CO37(), 
        .CO36(), .CO35(), .CO34(), .CO33(), .CO32(), .CO31(), .CO30(), .CO29(), 
        .CO28(), .CO27(), .CO26(), .CO25(), .CO24(), .CO23(), .CO22(), .CO21(), 
        .CO20(), .CO19(), .CO18(), .CO17(), .CO16(), .CO15(), .CO14(), .CO13(), 
        .CO12(), .CO11(), .CO10(), .CO9(), .CO8(), .CO7(), .CO6(), .CO5(), 
        .CO4(), .CO3(), .CO2(), .CO1(), .CO0(), .EQZ(), .EQZM(), .EQOM(), 
        .EQPAT(), .EQPATB(), .OVER(), .UNDER(), .OVERUNDER(), .SIGNEDR(mult_alu_signedr_1_0));

    defparam dsp_alu_0.CLK3_DIV = "ENABLED" ;
    defparam dsp_alu_0.CLK2_DIV = "ENABLED" ;
    defparam dsp_alu_0.CLK1_DIV = "ENABLED" ;
    defparam dsp_alu_0.CLK0_DIV = "ENABLED" ;
//    defparam dsp_alu_0.REG_INPUTCFB_RST = "RST0" ;
//    defparam dsp_alu_0.REG_INPUTCFB_CE = "CE0" ;
//    defparam dsp_alu_0.REG_INPUTCFB_CLK = "NONE" ;
    defparam dsp_alu_0.REG_OPCODEIN_1_RST = "RST0" ;
    defparam dsp_alu_0.REG_OPCODEIN_1_CE = "CE0" ;
    defparam dsp_alu_0.REG_OPCODEIN_1_CLK = "NONE" ;
    defparam dsp_alu_0.REG_OPCODEIN_0_RST = "RST0" ;
    defparam dsp_alu_0.REG_OPCODEIN_0_CE = "CE0" ;
    defparam dsp_alu_0.REG_OPCODEIN_0_CLK = "NONE" ;
//    defparam dsp_alu_0.REG_OPCODEOP1_1_CLK = "NONE" ;
    defparam dsp_alu_0.REG_OPCODEOP1_0_CLK = "NONE" ;
    defparam dsp_alu_0.REG_OPCODEOP0_1_RST = "RST0" ;
    defparam dsp_alu_0.REG_OPCODEOP0_1_CE = "CE0" ;
    defparam dsp_alu_0.REG_OPCODEOP0_1_CLK = "NONE" ;
    defparam dsp_alu_0.REG_OPCODEOP0_0_RST = "RST0" ;
    defparam dsp_alu_0.REG_OPCODEOP0_0_CE = "CE0" ;
    defparam dsp_alu_0.REG_OPCODEOP0_0_CLK = "NONE" ;
//    defparam dsp_alu_0.REG_INPUTC1_RST = "RST0" ;
//    defparam dsp_alu_0.REG_INPUTC1_CE = "CE0" ;
    defparam dsp_alu_0.REG_INPUTC1_CLK = "NONE" ;
//    defparam dsp_alu_0.REG_INPUTC0_RST = "RST0" ;
//    defparam dsp_alu_0.REG_INPUTC0_CE = "CE0" ;
    defparam dsp_alu_0.REG_INPUTC0_CLK = "NONE" ;
    defparam dsp_alu_0.LEGACY = "DISABLED" ;
//    defparam dsp_alu_0.REG_FLAG_RST = "RST0" ;
//    defparam dsp_alu_0.REG_FLAG_CE = "CE0" ;
    defparam dsp_alu_0.REG_FLAG_CLK = "NONE" ;
//    defparam dsp_alu_0.REG_OUTPUT1_RST = "RST0" ;
//    defparam dsp_alu_0.REG_OUTPUT1_CE = "CE0" ;
    defparam dsp_alu_0.REG_OUTPUT1_CLK = "CLK0" ;
//    defparam dsp_alu_0.REG_OUTPUT0_RST = "RST0" ;
//    defparam dsp_alu_0.REG_OUTPUT0_CE = "CE0" ;
    defparam dsp_alu_0.REG_OUTPUT0_CLK = "CLK0" ;
//    defparam dsp_alu_0.MULT9_MODE = "DISABLED" ;
    defparam dsp_alu_0.RNDPAT = "0x00000000000000" ;
    defparam dsp_alu_0.MASKPAT = "0x00000000000000" ;
    defparam dsp_alu_0.MCPAT = "0x00000000000000" ;
    defparam dsp_alu_0.MASK01 = "0x00000000000000" ;
    defparam dsp_alu_0.MASKPAT_SOURCE = "STATIC" ;
    defparam dsp_alu_0.MCPAT_SOURCE = "STATIC" ;
    defparam dsp_alu_0.RESETMODE = "SYNC" ;
    defparam dsp_alu_0.GSR = "ENABLED" ;
    ALU54B dsp_alu_0 (.A35(mult_0_mult_out_rob_2_17), .A34(mult_0_mult_out_rob_2_16), 
        .A33(mult_0_mult_out_rob_2_15), .A32(mult_0_mult_out_rob_2_14), 
        .A31(mult_0_mult_out_rob_2_13), .A30(mult_0_mult_out_rob_2_12), 
        .A29(mult_0_mult_out_rob_2_11), .A28(mult_0_mult_out_rob_2_10), 
        .A27(mult_0_mult_out_rob_2_9), .A26(mult_0_mult_out_rob_2_8), .A25(mult_0_mult_out_rob_2_7), 
        .A24(mult_0_mult_out_rob_2_6), .A23(mult_0_mult_out_rob_2_5), .A22(mult_0_mult_out_rob_2_4), 
        .A21(mult_0_mult_out_rob_2_3), .A20(mult_0_mult_out_rob_2_2), .A19(mult_0_mult_out_rob_2_1), 
        .A18(mult_0_mult_out_rob_2_0), .A17(mult_0_mult_out_roa_2_17), .A16(mult_0_mult_out_roa_2_16), 
        .A15(mult_0_mult_out_roa_2_15), .A14(mult_0_mult_out_roa_2_14), 
        .A13(mult_0_mult_out_roa_2_13), .A12(mult_0_mult_out_roa_2_12), 
        .A11(mult_0_mult_out_roa_2_11), .A10(mult_0_mult_out_roa_2_10), 
        .A9(mult_0_mult_out_roa_2_9), .A8(mult_0_mult_out_roa_2_8), .A7(mult_0_mult_out_roa_2_7), 
        .A6(mult_0_mult_out_roa_2_6), .A5(mult_0_mult_out_roa_2_5), .A4(mult_0_mult_out_roa_2_4), 
        .A3(mult_0_mult_out_roa_2_3), .A2(mult_0_mult_out_roa_2_2), .A1(mult_0_mult_out_roa_2_1), 
        .A0(mult_0_mult_out_roa_2_0), .B35(mult_0_mult_out_rob_3_17), .B34(mult_0_mult_out_rob_3_16), 
        .B33(mult_0_mult_out_rob_3_15), .B32(mult_0_mult_out_rob_3_14), 
        .B31(mult_0_mult_out_rob_3_13), .B30(mult_0_mult_out_rob_3_12), 
        .B29(mult_0_mult_out_rob_3_11), .B28(mult_0_mult_out_rob_3_10), 
        .B27(mult_0_mult_out_rob_3_9), .B26(mult_0_mult_out_rob_3_8), .B25(mult_0_mult_out_rob_3_7), 
        .B24(mult_0_mult_out_rob_3_6), .B23(mult_0_mult_out_rob_3_5), .B22(mult_0_mult_out_rob_3_4), 
        .B21(mult_0_mult_out_rob_3_3), .B20(mult_0_mult_out_rob_3_2), .B19(mult_0_mult_out_rob_3_1), 
        .B18(mult_0_mult_out_rob_3_0), .B17(mult_0_mult_out_roa_3_17), .B16(mult_0_mult_out_roa_3_16), 
        .B15(mult_0_mult_out_roa_3_15), .B14(mult_0_mult_out_roa_3_14), 
        .B13(mult_0_mult_out_roa_3_13), .B12(mult_0_mult_out_roa_3_12), 
        .B11(mult_0_mult_out_roa_3_11), .B10(mult_0_mult_out_roa_3_10), 
        .B9(mult_0_mult_out_roa_3_9), .B8(mult_0_mult_out_roa_3_8), .B7(mult_0_mult_out_roa_3_7), 
        .B6(mult_0_mult_out_roa_3_6), .B5(mult_0_mult_out_roa_3_5), .B4(mult_0_mult_out_roa_3_4), 
        .B3(mult_0_mult_out_roa_3_3), .B2(mult_0_mult_out_roa_3_2), .B1(mult_0_mult_out_roa_3_1), 
        .B0(mult_0_mult_out_roa_3_0), .CFB53(scuba_vlo), .CFB52(scuba_vlo), 
        .CFB51(scuba_vlo), .CFB50(scuba_vlo), .CFB49(scuba_vlo), .CFB48(scuba_vlo), 
        .CFB47(scuba_vlo), .CFB46(scuba_vlo), .CFB45(scuba_vlo), .CFB44(scuba_vlo), 
        .CFB43(scuba_vlo), .CFB42(scuba_vlo), .CFB41(scuba_vlo), .CFB40(scuba_vlo), 
        .CFB39(scuba_vlo), .CFB38(scuba_vlo), .CFB37(scuba_vlo), .CFB36(scuba_vlo), 
        .CFB35(scuba_vlo), .CFB34(scuba_vlo), .CFB33(scuba_vlo), .CFB32(scuba_vlo), 
        .CFB31(scuba_vlo), .CFB30(scuba_vlo), .CFB29(scuba_vlo), .CFB28(scuba_vlo), 
        .CFB27(scuba_vlo), .CFB26(scuba_vlo), .CFB25(scuba_vlo), .CFB24(scuba_vlo), 
        .CFB23(scuba_vlo), .CFB22(scuba_vlo), .CFB21(scuba_vlo), .CFB20(scuba_vlo), 
        .CFB19(scuba_vlo), .CFB18(scuba_vlo), .CFB17(scuba_vlo), .CFB16(scuba_vlo), 
        .CFB15(scuba_vlo), .CFB14(scuba_vlo), .CFB13(scuba_vlo), .CFB12(scuba_vlo), 
        .CFB11(scuba_vlo), .CFB10(scuba_vlo), .CFB9(scuba_vlo), .CFB8(scuba_vlo), 
        .CFB7(scuba_vlo), .CFB6(scuba_vlo), .CFB5(scuba_vlo), .CFB4(scuba_vlo), 
        .CFB3(scuba_vlo), .CFB2(scuba_vlo), .CFB1(scuba_vlo), .CFB0(scuba_vlo), 
        .C53(scuba_vlo), .C52(scuba_vlo), .C51(scuba_vlo), .C50(scuba_vlo), 
        .C49(scuba_vlo), .C48(scuba_vlo), .C47(scuba_vlo), .C46(scuba_vlo), 
        .C45(scuba_vlo), .C44(scuba_vlo), .C43(scuba_vlo), .C42(scuba_vlo), 
        .C41(scuba_vlo), .C40(scuba_vlo), .C39(scuba_vlo), .C38(scuba_vlo), 
        .C37(scuba_vlo), .C36(scuba_vlo), .C35(scuba_vlo), .C34(scuba_vlo), 
        .C33(scuba_vlo), .C32(scuba_vlo), .C31(scuba_vlo), .C30(scuba_vlo), 
        .C29(scuba_vlo), .C28(scuba_vlo), .C27(scuba_vlo), .C26(scuba_vlo), 
        .C25(scuba_vlo), .C24(scuba_vlo), .C23(scuba_vlo), .C22(scuba_vlo), 
        .C21(scuba_vlo), .C20(scuba_vlo), .C19(scuba_vlo), .C18(scuba_vlo), 
        .C17(scuba_vlo), .C16(scuba_vlo), .C15(scuba_vlo), .C14(scuba_vlo), 
        .C13(scuba_vlo), .C12(scuba_vlo), .C11(scuba_vlo), .C10(scuba_vlo), 
        .C9(scuba_vlo), .C8(scuba_vlo), .C7(scuba_vlo), .C6(scuba_vlo), 
        .C5(scuba_vlo), .C4(scuba_vlo), .C3(scuba_vlo), .C2(scuba_vlo), 
        .C1(scuba_vlo), .C0(scuba_vlo), .CE0(CE0), .CE1(scuba_vhi), .CE2(scuba_vhi), 
        .CE3(scuba_vhi), .CLK0(CLK0), .CLK1(CLK0), .CLK2(scuba_vlo), .CLK3(scuba_vlo), 
        .RST0(RST0), .RST1(scuba_vlo), .RST2(scuba_vlo), .RST3(scuba_vlo), 
        .SIGNEDIA(mult_0_mult_out_signedp_2), .SIGNEDIB(mult_0_mult_out_signedp_3), 
        .SIGNEDCIN(mult_alu_signedr_1_0), .MA35(mult_0_mult_out_p_2_35), 
        .MA34(mult_0_mult_out_p_2_34), .MA33(mult_0_mult_out_p_2_33), .MA32(mult_0_mult_out_p_2_32), 
        .MA31(mult_0_mult_out_p_2_31), .MA30(mult_0_mult_out_p_2_30), .MA29(mult_0_mult_out_p_2_29), 
        .MA28(mult_0_mult_out_p_2_28), .MA27(mult_0_mult_out_p_2_27), .MA26(mult_0_mult_out_p_2_26), 
        .MA25(mult_0_mult_out_p_2_25), .MA24(mult_0_mult_out_p_2_24), .MA23(mult_0_mult_out_p_2_23), 
        .MA22(mult_0_mult_out_p_2_22), .MA21(mult_0_mult_out_p_2_21), .MA20(mult_0_mult_out_p_2_20), 
        .MA19(mult_0_mult_out_p_2_19), .MA18(mult_0_mult_out_p_2_18), .MA17(mult_0_mult_out_p_2_17), 
        .MA16(mult_0_mult_out_p_2_16), .MA15(mult_0_mult_out_p_2_15), .MA14(mult_0_mult_out_p_2_14), 
        .MA13(mult_0_mult_out_p_2_13), .MA12(mult_0_mult_out_p_2_12), .MA11(mult_0_mult_out_p_2_11), 
        .MA10(mult_0_mult_out_p_2_10), .MA9(mult_0_mult_out_p_2_9), .MA8(mult_0_mult_out_p_2_8), 
        .MA7(mult_0_mult_out_p_2_7), .MA6(mult_0_mult_out_p_2_6), .MA5(mult_0_mult_out_p_2_5), 
        .MA4(mult_0_mult_out_p_2_4), .MA3(mult_0_mult_out_p_2_3), .MA2(mult_0_mult_out_p_2_2), 
        .MA1(mult_0_mult_out_p_2_1), .MA0(mult_0_mult_out_p_2_0), .MB35(mult_0_mult_out_p_3_35), 
        .MB34(mult_0_mult_out_p_3_34), .MB33(mult_0_mult_out_p_3_33), .MB32(mult_0_mult_out_p_3_32), 
        .MB31(mult_0_mult_out_p_3_31), .MB30(mult_0_mult_out_p_3_30), .MB29(mult_0_mult_out_p_3_29), 
        .MB28(mult_0_mult_out_p_3_28), .MB27(mult_0_mult_out_p_3_27), .MB26(mult_0_mult_out_p_3_26), 
        .MB25(mult_0_mult_out_p_3_25), .MB24(mult_0_mult_out_p_3_24), .MB23(mult_0_mult_out_p_3_23), 
        .MB22(mult_0_mult_out_p_3_22), .MB21(mult_0_mult_out_p_3_21), .MB20(mult_0_mult_out_p_3_20), 
        .MB19(mult_0_mult_out_p_3_19), .MB18(mult_0_mult_out_p_3_18), .MB17(mult_0_mult_out_p_3_17), 
        .MB16(mult_0_mult_out_p_3_16), .MB15(mult_0_mult_out_p_3_15), .MB14(mult_0_mult_out_p_3_14), 
        .MB13(mult_0_mult_out_p_3_13), .MB12(mult_0_mult_out_p_3_12), .MB11(mult_0_mult_out_p_3_11), 
        .MB10(mult_0_mult_out_p_3_10), .MB9(mult_0_mult_out_p_3_9), .MB8(mult_0_mult_out_p_3_8), 
        .MB7(mult_0_mult_out_p_3_7), .MB6(mult_0_mult_out_p_3_6), .MB5(mult_0_mult_out_p_3_5), 
        .MB4(mult_0_mult_out_p_3_4), .MB3(mult_0_mult_out_p_3_3), .MB2(mult_0_mult_out_p_3_2), 
        .MB1(mult_0_mult_out_p_3_1), .MB0(mult_0_mult_out_p_3_0), .CIN53(mult_alu_output_r_1_0_53), 
        .CIN52(mult_alu_output_r_1_0_52), .CIN51(mult_alu_output_r_1_0_51), 
        .CIN50(mult_alu_output_r_1_0_50), .CIN49(mult_alu_output_r_1_0_49), 
        .CIN48(mult_alu_output_r_1_0_48), .CIN47(mult_alu_output_r_1_0_47), 
        .CIN46(mult_alu_output_r_1_0_46), .CIN45(mult_alu_output_r_1_0_45), 
        .CIN44(mult_alu_output_r_1_0_44), .CIN43(mult_alu_output_r_1_0_43), 
        .CIN42(mult_alu_output_r_1_0_42), .CIN41(mult_alu_output_r_1_0_41), 
        .CIN40(mult_alu_output_r_1_0_40), .CIN39(mult_alu_output_r_1_0_39), 
        .CIN38(mult_alu_output_r_1_0_38), .CIN37(mult_alu_output_r_1_0_37), 
        .CIN36(mult_alu_output_r_1_0_36), .CIN35(mult_alu_output_r_1_0_35), 
        .CIN34(mult_alu_output_r_1_0_34), .CIN33(mult_alu_output_r_1_0_33), 
        .CIN32(mult_alu_output_r_1_0_32), .CIN31(mult_alu_output_r_1_0_31), 
        .CIN30(mult_alu_output_r_1_0_30), .CIN29(mult_alu_output_r_1_0_29), 
        .CIN28(mult_alu_output_r_1_0_28), .CIN27(mult_alu_output_r_1_0_27), 
        .CIN26(mult_alu_output_r_1_0_26), .CIN25(mult_alu_output_r_1_0_25), 
        .CIN24(mult_alu_output_r_1_0_24), .CIN23(mult_alu_output_r_1_0_23), 
        .CIN22(mult_alu_output_r_1_0_22), .CIN21(mult_alu_output_r_1_0_21), 
        .CIN20(mult_alu_output_r_1_0_20), .CIN19(mult_alu_output_r_1_0_19), 
        .CIN18(mult_alu_output_r_1_0_18), .CIN17(mult_alu_output_r_1_0_17), 
        .CIN16(mult_alu_output_r_1_0_16), .CIN15(mult_alu_output_r_1_0_15), 
        .CIN14(mult_alu_output_r_1_0_14), .CIN13(mult_alu_output_r_1_0_13), 
        .CIN12(mult_alu_output_r_1_0_12), .CIN11(mult_alu_output_r_1_0_11), 
        .CIN10(mult_alu_output_r_1_0_10), .CIN9(mult_alu_output_r_1_0_9), 
        .CIN8(mult_alu_output_r_1_0_8), .CIN7(mult_alu_output_r_1_0_7), 
        .CIN6(mult_alu_output_r_1_0_6), .CIN5(mult_alu_output_r_1_0_5), 
        .CIN4(mult_alu_output_r_1_0_4), .CIN3(mult_alu_output_r_1_0_3), 
        .CIN2(mult_alu_output_r_1_0_2), .CIN1(mult_alu_output_r_1_0_1), 
        .CIN0(mult_alu_output_r_1_0_0), .OP10(scuba_vlo), .OP9(scuba_vhi), 
        .OP8(scuba_vlo), .OP7(scuba_vlo), .OP6(scuba_vlo), .OP5(scuba_vlo), 
        .OP4(scuba_vhi), .OP3(scuba_vlo), .OP2(scuba_vlo), .OP1(scuba_vlo), 
        .OP0(scuba_vhi), .R53(mult_alu_output_r_2_1_53), .R52(mult_alu_output_r_2_1_52), 
        .R51(mult_alu_output_r_2_1_51), .R50(mult_alu_output_r_2_1_50), 
        .R49(mult_alu_output_r_2_1_49), .R48(mult_alu_output_r_2_1_48), 
        .R47(mult_alu_output_r_2_1_47), .R46(mult_alu_output_r_2_1_46), 
        .R45(mult_alu_output_r_2_1_45), .R44(mult_alu_output_r_2_1_44), 
        .R43(mult_alu_output_r_2_1_43), .R42(mult_alu_output_r_2_1_42), 
        .R41(mult_alu_output_r_2_1_41), .R40(mult_alu_output_r_2_1_40), 
        .R39(mult_alu_output_r_2_1_39), .R38(mult_alu_output_r_2_1_38), 
        .R37(mult_alu_output_r_2_1_37), .R36(mult_alu_output_r_2_1_36), 
        .R35(mult_alu_output_r_2_1_35), .R34(mult_alu_output_r_2_1_34), 
        .R33(mult_alu_output_r_2_1_33), .R32(mult_alu_output_r_2_1_32), 
        .R31(mult_alu_output_r_2_1_31), .R30(mult_alu_output_r_2_1_30), 
        .R29(mult_alu_output_r_2_1_29), .R28(mult_alu_output_r_2_1_28), 
        .R27(mult_alu_output_r_2_1_27), .R26(mult_alu_output_r_2_1_26), 
        .R25(mult_alu_output_r_2_1_25), .R24(mult_alu_output_r_2_1_24), 
        .R23(mult_alu_output_r_2_1_23), .R22(mult_alu_output_r_2_1_22), 
        .R21(mult_alu_output_r_2_1_21), .R20(mult_alu_output_r_2_1_20), 
        .R19(mult_alu_output_r_2_1_19), .R18(mult_alu_output_r_2_1_18), 
        .R17(mult_alu_output_r_2_1_17), .R16(mult_alu_output_r_2_1_16), 
        .R15(mult_alu_output_r_2_1_15), .R14(mult_alu_output_r_2_1_14), 
        .R13(mult_alu_output_r_2_1_13), .R12(mult_alu_output_r_2_1_12), 
        .R11(mult_alu_output_r_2_1_11), .R10(mult_alu_output_r_2_1_10), 
        .R9(mult_alu_output_r_2_1_9), .R8(mult_alu_output_r_2_1_8), .R7(mult_alu_output_r_2_1_7), 
        .R6(mult_alu_output_r_2_1_6), .R5(mult_alu_output_r_2_1_5), .R4(mult_alu_output_r_2_1_4), 
        .R3(mult_alu_output_r_2_1_3), .R2(mult_alu_output_r_2_1_2), .R1(mult_alu_output_r_2_1_1), 
        .R0(mult_alu_output_r_2_1_0), .CO53(), .CO52(), .CO51(), .CO50(), 
        .CO49(), .CO48(), .CO47(), .CO46(), .CO45(), .CO44(), .CO43(), .CO42(), 
        .CO41(), .CO40(), .CO39(), .CO38(), .CO37(), .CO36(), .CO35(), .CO34(), 
        .CO33(), .CO32(), .CO31(), .CO30(), .CO29(), .CO28(), .CO27(), .CO26(), 
        .CO25(), .CO24(), .CO23(), .CO22(), .CO21(), .CO20(), .CO19(), .CO18(), 
        .CO17(), .CO16(), .CO15(), .CO14(), .CO13(), .CO12(), .CO11(), .CO10(), 
        .CO9(), .CO8(), .CO7(), .CO6(), .CO5(), .CO4(), .CO3(), .CO2(), 
        .CO1(), .CO0(), .EQZ(), .EQZM(), .EQOM(), .EQPAT(), .EQPATB(), .OVER(), 
        .UNDER(), .OVERUNDER(), .SIGNEDR(mult_alu_signedr_2_1));

    defparam dsp_mult_3.CLK3_DIV = "ENABLED" ;
    defparam dsp_mult_3.CLK2_DIV = "ENABLED" ;
    defparam dsp_mult_3.CLK1_DIV = "ENABLED" ;
    defparam dsp_mult_3.CLK0_DIV = "ENABLED" ;
//    defparam dsp_mult_3.HIGHSPEED_CLK = "NONE" ;
//    defparam dsp_mult_3.REG_INPUTC_RST = "RST0" ;
//    defparam dsp_mult_3.REG_INPUTC_CE = "CE0" ;
    defparam dsp_mult_3.REG_INPUTC_CLK = "NONE" ;
    defparam dsp_mult_3.SOURCEB_MODE = "B_SHIFT" ;
//    defparam dsp_mult_3.MULT_BYPASS = "DISABLED" ;
//    defparam dsp_mult_3.CAS_MATCH_REG = "FALSE" ;
    defparam dsp_mult_3.RESETMODE = "SYNC" ;
    defparam dsp_mult_3.GSR = "ENABLED" ;
//    defparam dsp_mult_3.REG_OUTPUT_RST = "RST0" ;
//    defparam dsp_mult_3.REG_OUTPUT_CE = "CE0" ;
    defparam dsp_mult_3.REG_OUTPUT_CLK = "NONE" ;
    defparam dsp_mult_3.REG_PIPELINE_RST = "RST0" ;
    defparam dsp_mult_3.REG_PIPELINE_CE = "CE0" ;
    defparam dsp_mult_3.REG_PIPELINE_CLK = "CLK0" ;
    defparam dsp_mult_3.REG_INPUTB_RST = "RST0" ;
    defparam dsp_mult_3.REG_INPUTB_CE = "CE0" ;
    defparam dsp_mult_3.REG_INPUTB_CLK = "CLK0" ;
    defparam dsp_mult_3.REG_INPUTA_RST = "RST0" ;
    defparam dsp_mult_3.REG_INPUTA_CE = "CE0" ;
    defparam dsp_mult_3.REG_INPUTA_CLK = "CLK0" ;
    MULT18X18D dsp_mult_3 (.A17(A[13]), .A16(A[12]), .A15(A[11]), .A14(A[10]), 
        .A13(A[9]), .A12(A[8]), .A11(A[7]), .A10(A[6]), .A9(A[5]), .A8(A[4]), 
        .A7(A[3]), .A6(A[2]), .A5(A[1]), .A4(A[0]), .A3(scuba_vlo), .A2(scuba_vlo), 
        .A1(scuba_vlo), .A0(scuba_vlo), .B17(B[13]), .B16(B[12]), .B15(B[11]), 
        .B14(B[10]), .B13(B[9]), .B12(B[8]), .B11(B[7]), .B10(B[6]), .B9(B[5]), 
        .B8(B[4]), .B7(B[3]), .B6(B[2]), .B5(B[1]), .B4(B[0]), .B3(scuba_vlo), 
        .B2(scuba_vlo), .B1(scuba_vlo), .B0(scuba_vlo), .C17(scuba_vlo), 
        .C16(scuba_vlo), .C15(scuba_vlo), .C14(scuba_vlo), .C13(scuba_vlo), 
        .C12(scuba_vlo), .C11(scuba_vlo), .C10(scuba_vlo), .C9(scuba_vlo), 
        .C8(scuba_vlo), .C7(scuba_vlo), .C6(scuba_vlo), .C5(scuba_vlo), 
        .C4(scuba_vlo), .C3(scuba_vlo), .C2(scuba_vlo), .C1(scuba_vlo), 
        .C0(scuba_vlo), .SIGNEDA(scuba_vlo), .SIGNEDB(scuba_vlo), .SOURCEA(scuba_vlo), 
        .SOURCEB(scuba_vlo), .CE0(CE0), .CE1(scuba_vhi), .CE2(scuba_vhi), 
        .CE3(scuba_vhi), .CLK0(CLK0), .CLK1(scuba_vlo), .CLK2(scuba_vlo), 
        .CLK3(scuba_vlo), .RST0(RST0), .RST1(scuba_vlo), .RST2(scuba_vlo), 
        .RST3(scuba_vlo), .SROA17(), .SROA16(), .SROA15(), .SROA14(), .SROA13(), 
        .SROA12(), .SROA11(), .SROA10(), .SROA9(), .SROA8(), .SROA7(), .SROA6(), 
        .SROA5(), .SROA4(), .SROA3(), .SROA2(), .SROA1(), .SROA0(), .SROB17(), 
        .SROB16(), .SROB15(), .SROB14(), .SROB13(), .SROB12(), .SROB11(), 
        .SROB10(), .SROB9(), .SROB8(), .SROB7(), .SROB6(), .SROB5(), .SROB4(), 
        .SROB3(), .SROB2(), .SROB1(), .SROB0(), .ROA17(mult_0_mult_out_roa_0_17), 
        .ROA16(mult_0_mult_out_roa_0_16), .ROA15(mult_0_mult_out_roa_0_15), 
        .ROA14(mult_0_mult_out_roa_0_14), .ROA13(mult_0_mult_out_roa_0_13), 
        .ROA12(mult_0_mult_out_roa_0_12), .ROA11(mult_0_mult_out_roa_0_11), 
        .ROA10(mult_0_mult_out_roa_0_10), .ROA9(mult_0_mult_out_roa_0_9), 
        .ROA8(mult_0_mult_out_roa_0_8), .ROA7(mult_0_mult_out_roa_0_7), 
        .ROA6(mult_0_mult_out_roa_0_6), .ROA5(mult_0_mult_out_roa_0_5), 
        .ROA4(mult_0_mult_out_roa_0_4), .ROA3(mult_0_mult_out_roa_0_3), 
        .ROA2(mult_0_mult_out_roa_0_2), .ROA1(mult_0_mult_out_roa_0_1), 
        .ROA0(mult_0_mult_out_roa_0_0), .ROB17(mult_0_mult_out_rob_0_17), 
        .ROB16(mult_0_mult_out_rob_0_16), .ROB15(mult_0_mult_out_rob_0_15), 
        .ROB14(mult_0_mult_out_rob_0_14), .ROB13(mult_0_mult_out_rob_0_13), 
        .ROB12(mult_0_mult_out_rob_0_12), .ROB11(mult_0_mult_out_rob_0_11), 
        .ROB10(mult_0_mult_out_rob_0_10), .ROB9(mult_0_mult_out_rob_0_9), 
        .ROB8(mult_0_mult_out_rob_0_8), .ROB7(mult_0_mult_out_rob_0_7), 
        .ROB6(mult_0_mult_out_rob_0_6), .ROB5(mult_0_mult_out_rob_0_5), 
        .ROB4(mult_0_mult_out_rob_0_4), .ROB3(mult_0_mult_out_rob_0_3), 
        .ROB2(mult_0_mult_out_rob_0_2), .ROB1(mult_0_mult_out_rob_0_1), 
        .ROB0(mult_0_mult_out_rob_0_0), .ROC17(), .ROC16(), .ROC15(), .ROC14(), 
        .ROC13(), .ROC12(), .ROC11(), .ROC10(), .ROC9(), .ROC8(), .ROC7(), 
        .ROC6(), .ROC5(), .ROC4(), .ROC3(), .ROC2(), .ROC1(), .ROC0(), .P35(mult_0_mult_out_p_0_35), 
        .P34(mult_0_mult_out_p_0_34), .P33(mult_0_mult_out_p_0_33), .P32(mult_0_mult_out_p_0_32), 
        .P31(mult_0_mult_out_p_0_31), .P30(mult_0_mult_out_p_0_30), .P29(mult_0_mult_out_p_0_29), 
        .P28(mult_0_mult_out_p_0_28), .P27(mult_0_mult_out_p_0_27), .P26(mult_0_mult_out_p_0_26), 
        .P25(mult_0_mult_out_p_0_25), .P24(mult_0_mult_out_p_0_24), .P23(mult_0_mult_out_p_0_23), 
        .P22(mult_0_mult_out_p_0_22), .P21(mult_0_mult_out_p_0_21), .P20(mult_0_mult_out_p_0_20), 
        .P19(mult_0_mult_out_p_0_19), .P18(mult_0_mult_out_p_0_18), .P17(mult_0_mult_out_p_0_17), 
        .P16(mult_0_mult_out_p_0_16), .P15(mult_0_mult_out_p_0_15), .P14(mult_0_mult_out_p_0_14), 
        .P13(mult_0_mult_out_p_0_13), .P12(mult_0_mult_out_p_0_12), .P11(mult_0_mult_out_p_0_11), 
        .P10(mult_0_mult_out_p_0_10), .P9(mult_0_mult_out_p_0_9), .P8(mult_0_mult_out_p_0_8), 
        .P7(mult_0_mult_out_p_0_7), .P6(mult_0_mult_out_p_0_6), .P5(mult_0_mult_out_p_0_5), 
        .P4(mult_0_mult_out_p_0_4), .P3(mult_0_mult_out_p_0_3), .P2(mult_0_mult_out_p_0_2), 
        .P1(mult_0_mult_out_p_0_1), .P0(mult_0_mult_out_p_0_0), .SIGNEDP(mult_0_mult_out_signedp_0));

    defparam dsp_mult_2.CLK3_DIV = "ENABLED" ;
    defparam dsp_mult_2.CLK2_DIV = "ENABLED" ;
    defparam dsp_mult_2.CLK1_DIV = "ENABLED" ;
    defparam dsp_mult_2.CLK0_DIV = "ENABLED" ;
//    defparam dsp_mult_2.HIGHSPEED_CLK = "NONE" ;
//    defparam dsp_mult_2.REG_INPUTC_RST = "RST0" ;
//    defparam dsp_mult_2.REG_INPUTC_CE = "CE0" ;
    defparam dsp_mult_2.REG_INPUTC_CLK = "NONE" ;
    defparam dsp_mult_2.SOURCEB_MODE = "B_SHIFT" ;
//    defparam dsp_mult_2.MULT_BYPASS = "DISABLED" ;
//    defparam dsp_mult_2.CAS_MATCH_REG = "FALSE" ;
    defparam dsp_mult_2.RESETMODE = "SYNC" ;
    defparam dsp_mult_2.GSR = "ENABLED" ;
//    defparam dsp_mult_2.REG_OUTPUT_RST = "RST0" ;
//    defparam dsp_mult_2.REG_OUTPUT_CE = "CE0" ;
    defparam dsp_mult_2.REG_OUTPUT_CLK = "NONE" ;
    defparam dsp_mult_2.REG_PIPELINE_RST = "RST0" ;
    defparam dsp_mult_2.REG_PIPELINE_CE = "CE0" ;
    defparam dsp_mult_2.REG_PIPELINE_CLK = "CLK0" ;
    defparam dsp_mult_2.REG_INPUTB_RST = "RST0" ;
    defparam dsp_mult_2.REG_INPUTB_CE = "CE0" ;
    defparam dsp_mult_2.REG_INPUTB_CLK = "CLK0" ;
    defparam dsp_mult_2.REG_INPUTA_RST = "RST0" ;
    defparam dsp_mult_2.REG_INPUTA_CE = "CE0" ;
    defparam dsp_mult_2.REG_INPUTA_CLK = "CLK0" ;
    MULT18X18D dsp_mult_2 (.A17(A[31]), .A16(A[30]), .A15(A[29]), .A14(A[28]), 
        .A13(A[27]), .A12(A[26]), .A11(A[25]), .A10(A[24]), .A9(A[23]), 
        .A8(A[22]), .A7(A[21]), .A6(A[20]), .A5(A[19]), .A4(A[18]), .A3(A[17]), 
        .A2(A[16]), .A1(A[15]), .A0(A[14]), .B17(B[13]), .B16(B[12]), .B15(B[11]), 
        .B14(B[10]), .B13(B[9]), .B12(B[8]), .B11(B[7]), .B10(B[6]), .B9(B[5]), 
        .B8(B[4]), .B7(B[3]), .B6(B[2]), .B5(B[1]), .B4(B[0]), .B3(scuba_vlo), 
        .B2(scuba_vlo), .B1(scuba_vlo), .B0(scuba_vlo), .C17(scuba_vlo), 
        .C16(scuba_vlo), .C15(scuba_vlo), .C14(scuba_vlo), .C13(scuba_vlo), 
        .C12(scuba_vlo), .C11(scuba_vlo), .C10(scuba_vlo), .C9(scuba_vlo), 
        .C8(scuba_vlo), .C7(scuba_vlo), .C6(scuba_vlo), .C5(scuba_vlo), 
        .C4(scuba_vlo), .C3(scuba_vlo), .C2(scuba_vlo), .C1(scuba_vlo), 
        .C0(scuba_vlo), .SIGNEDA(SignA), .SIGNEDB(scuba_vlo), .SOURCEA(scuba_vlo), 
        .SOURCEB(scuba_vlo), .CE0(CE0), .CE1(scuba_vhi), .CE2(scuba_vhi), 
        .CE3(scuba_vhi), .CLK0(CLK0), .CLK1(scuba_vlo), .CLK2(scuba_vlo), 
        .CLK3(scuba_vlo), .RST0(RST0), .RST1(scuba_vlo), .RST2(scuba_vlo), 
        .RST3(scuba_vlo), .SROA17(), .SROA16(), .SROA15(), .SROA14(), .SROA13(), 
        .SROA12(), .SROA11(), .SROA10(), .SROA9(), .SROA8(), .SROA7(), .SROA6(), 
        .SROA5(), .SROA4(), .SROA3(), .SROA2(), .SROA1(), .SROA0(), .SROB17(), 
        .SROB16(), .SROB15(), .SROB14(), .SROB13(), .SROB12(), .SROB11(), 
        .SROB10(), .SROB9(), .SROB8(), .SROB7(), .SROB6(), .SROB5(), .SROB4(), 
        .SROB3(), .SROB2(), .SROB1(), .SROB0(), .ROA17(mult_0_mult_out_roa_1_17), 
        .ROA16(mult_0_mult_out_roa_1_16), .ROA15(mult_0_mult_out_roa_1_15), 
        .ROA14(mult_0_mult_out_roa_1_14), .ROA13(mult_0_mult_out_roa_1_13), 
        .ROA12(mult_0_mult_out_roa_1_12), .ROA11(mult_0_mult_out_roa_1_11), 
        .ROA10(mult_0_mult_out_roa_1_10), .ROA9(mult_0_mult_out_roa_1_9), 
        .ROA8(mult_0_mult_out_roa_1_8), .ROA7(mult_0_mult_out_roa_1_7), 
        .ROA6(mult_0_mult_out_roa_1_6), .ROA5(mult_0_mult_out_roa_1_5), 
        .ROA4(mult_0_mult_out_roa_1_4), .ROA3(mult_0_mult_out_roa_1_3), 
        .ROA2(mult_0_mult_out_roa_1_2), .ROA1(mult_0_mult_out_roa_1_1), 
        .ROA0(mult_0_mult_out_roa_1_0), .ROB17(mult_0_mult_out_rob_1_17), 
        .ROB16(mult_0_mult_out_rob_1_16), .ROB15(mult_0_mult_out_rob_1_15), 
        .ROB14(mult_0_mult_out_rob_1_14), .ROB13(mult_0_mult_out_rob_1_13), 
        .ROB12(mult_0_mult_out_rob_1_12), .ROB11(mult_0_mult_out_rob_1_11), 
        .ROB10(mult_0_mult_out_rob_1_10), .ROB9(mult_0_mult_out_rob_1_9), 
        .ROB8(mult_0_mult_out_rob_1_8), .ROB7(mult_0_mult_out_rob_1_7), 
        .ROB6(mult_0_mult_out_rob_1_6), .ROB5(mult_0_mult_out_rob_1_5), 
        .ROB4(mult_0_mult_out_rob_1_4), .ROB3(mult_0_mult_out_rob_1_3), 
        .ROB2(mult_0_mult_out_rob_1_2), .ROB1(mult_0_mult_out_rob_1_1), 
        .ROB0(mult_0_mult_out_rob_1_0), .ROC17(), .ROC16(), .ROC15(), .ROC14(), 
        .ROC13(), .ROC12(), .ROC11(), .ROC10(), .ROC9(), .ROC8(), .ROC7(), 
        .ROC6(), .ROC5(), .ROC4(), .ROC3(), .ROC2(), .ROC1(), .ROC0(), .P35(mult_0_mult_out_p_1_35), 
        .P34(mult_0_mult_out_p_1_34), .P33(mult_0_mult_out_p_1_33), .P32(mult_0_mult_out_p_1_32), 
        .P31(mult_0_mult_out_p_1_31), .P30(mult_0_mult_out_p_1_30), .P29(mult_0_mult_out_p_1_29), 
        .P28(mult_0_mult_out_p_1_28), .P27(mult_0_mult_out_p_1_27), .P26(mult_0_mult_out_p_1_26), 
        .P25(mult_0_mult_out_p_1_25), .P24(mult_0_mult_out_p_1_24), .P23(mult_0_mult_out_p_1_23), 
        .P22(mult_0_mult_out_p_1_22), .P21(mult_0_mult_out_p_1_21), .P20(mult_0_mult_out_p_1_20), 
        .P19(mult_0_mult_out_p_1_19), .P18(mult_0_mult_out_p_1_18), .P17(mult_0_mult_out_p_1_17), 
        .P16(mult_0_mult_out_p_1_16), .P15(mult_0_mult_out_p_1_15), .P14(mult_0_mult_out_p_1_14), 
        .P13(mult_0_mult_out_p_1_13), .P12(mult_0_mult_out_p_1_12), .P11(mult_0_mult_out_p_1_11), 
        .P10(mult_0_mult_out_p_1_10), .P9(mult_0_mult_out_p_1_9), .P8(mult_0_mult_out_p_1_8), 
        .P7(mult_0_mult_out_p_1_7), .P6(mult_0_mult_out_p_1_6), .P5(mult_0_mult_out_p_1_5), 
        .P4(mult_0_mult_out_p_1_4), .P3(mult_0_mult_out_p_1_3), .P2(mult_0_mult_out_p_1_2), 
        .P1(mult_0_mult_out_p_1_1), .P0(mult_0_mult_out_p_1_0), .SIGNEDP(mult_0_mult_out_signedp_1));

    defparam dsp_mult_1.CLK3_DIV = "ENABLED" ;
    defparam dsp_mult_1.CLK2_DIV = "ENABLED" ;
    defparam dsp_mult_1.CLK1_DIV = "ENABLED" ;
    defparam dsp_mult_1.CLK0_DIV = "ENABLED" ;
//    defparam dsp_mult_1.HIGHSPEED_CLK = "NONE" ;
//    defparam dsp_mult_1.REG_INPUTC_RST = "RST0" ;
//    defparam dsp_mult_1.REG_INPUTC_CE = "CE0" ;
    defparam dsp_mult_1.REG_INPUTC_CLK = "NONE" ;
    defparam dsp_mult_1.SOURCEB_MODE = "B_SHIFT" ;
//    defparam dsp_mult_1.MULT_BYPASS = "DISABLED" ;
//    defparam dsp_mult_1.CAS_MATCH_REG = "FALSE" ;
    defparam dsp_mult_1.RESETMODE = "SYNC" ;
    defparam dsp_mult_1.GSR = "ENABLED" ;
//    defparam dsp_mult_1.REG_OUTPUT_RST = "RST0" ;
//    defparam dsp_mult_1.REG_OUTPUT_CE = "CE0" ;
    defparam dsp_mult_1.REG_OUTPUT_CLK = "NONE" ;
    defparam dsp_mult_1.REG_PIPELINE_RST = "RST0" ;
    defparam dsp_mult_1.REG_PIPELINE_CE = "CE0" ;
    defparam dsp_mult_1.REG_PIPELINE_CLK = "CLK0" ;
    defparam dsp_mult_1.REG_INPUTB_RST = "RST0" ;
    defparam dsp_mult_1.REG_INPUTB_CE = "CE0" ;
    defparam dsp_mult_1.REG_INPUTB_CLK = "CLK0" ;
    defparam dsp_mult_1.REG_INPUTA_RST = "RST0" ;
    defparam dsp_mult_1.REG_INPUTA_CE = "CE0" ;
    defparam dsp_mult_1.REG_INPUTA_CLK = "CLK0" ;
    MULT18X18D dsp_mult_1 (.A17(A[13]), .A16(A[12]), .A15(A[11]), .A14(A[10]), 
        .A13(A[9]), .A12(A[8]), .A11(A[7]), .A10(A[6]), .A9(A[5]), .A8(A[4]), 
        .A7(A[3]), .A6(A[2]), .A5(A[1]), .A4(A[0]), .A3(scuba_vlo), .A2(scuba_vlo), 
        .A1(scuba_vlo), .A0(scuba_vlo), .B17(B[31]), .B16(B[30]), .B15(B[29]), 
        .B14(B[28]), .B13(B[27]), .B12(B[26]), .B11(B[25]), .B10(B[24]), 
        .B9(B[23]), .B8(B[22]), .B7(B[21]), .B6(B[20]), .B5(B[19]), .B4(B[18]), 
        .B3(B[17]), .B2(B[16]), .B1(B[15]), .B0(B[14]), .C17(scuba_vlo), 
        .C16(scuba_vlo), .C15(scuba_vlo), .C14(scuba_vlo), .C13(scuba_vlo), 
        .C12(scuba_vlo), .C11(scuba_vlo), .C10(scuba_vlo), .C9(scuba_vlo), 
        .C8(scuba_vlo), .C7(scuba_vlo), .C6(scuba_vlo), .C5(scuba_vlo), 
        .C4(scuba_vlo), .C3(scuba_vlo), .C2(scuba_vlo), .C1(scuba_vlo), 
        .C0(scuba_vlo), .SIGNEDA(scuba_vlo), .SIGNEDB(SignB), .SOURCEA(scuba_vlo), 
        .SOURCEB(scuba_vlo), .CE0(CE0), .CE1(scuba_vhi), .CE2(scuba_vhi), 
        .CE3(scuba_vhi), .CLK0(CLK0), .CLK1(scuba_vlo), .CLK2(scuba_vlo), 
        .CLK3(scuba_vlo), .RST0(RST0), .RST1(scuba_vlo), .RST2(scuba_vlo), 
        .RST3(scuba_vlo), .SROA17(), .SROA16(), .SROA15(), .SROA14(), .SROA13(), 
        .SROA12(), .SROA11(), .SROA10(), .SROA9(), .SROA8(), .SROA7(), .SROA6(), 
        .SROA5(), .SROA4(), .SROA3(), .SROA2(), .SROA1(), .SROA0(), .SROB17(), 
        .SROB16(), .SROB15(), .SROB14(), .SROB13(), .SROB12(), .SROB11(), 
        .SROB10(), .SROB9(), .SROB8(), .SROB7(), .SROB6(), .SROB5(), .SROB4(), 
        .SROB3(), .SROB2(), .SROB1(), .SROB0(), .ROA17(mult_0_mult_out_roa_2_17), 
        .ROA16(mult_0_mult_out_roa_2_16), .ROA15(mult_0_mult_out_roa_2_15), 
        .ROA14(mult_0_mult_out_roa_2_14), .ROA13(mult_0_mult_out_roa_2_13), 
        .ROA12(mult_0_mult_out_roa_2_12), .ROA11(mult_0_mult_out_roa_2_11), 
        .ROA10(mult_0_mult_out_roa_2_10), .ROA9(mult_0_mult_out_roa_2_9), 
        .ROA8(mult_0_mult_out_roa_2_8), .ROA7(mult_0_mult_out_roa_2_7), 
        .ROA6(mult_0_mult_out_roa_2_6), .ROA5(mult_0_mult_out_roa_2_5), 
        .ROA4(mult_0_mult_out_roa_2_4), .ROA3(mult_0_mult_out_roa_2_3), 
        .ROA2(mult_0_mult_out_roa_2_2), .ROA1(mult_0_mult_out_roa_2_1), 
        .ROA0(mult_0_mult_out_roa_2_0), .ROB17(mult_0_mult_out_rob_2_17), 
        .ROB16(mult_0_mult_out_rob_2_16), .ROB15(mult_0_mult_out_rob_2_15), 
        .ROB14(mult_0_mult_out_rob_2_14), .ROB13(mult_0_mult_out_rob_2_13), 
        .ROB12(mult_0_mult_out_rob_2_12), .ROB11(mult_0_mult_out_rob_2_11), 
        .ROB10(mult_0_mult_out_rob_2_10), .ROB9(mult_0_mult_out_rob_2_9), 
        .ROB8(mult_0_mult_out_rob_2_8), .ROB7(mult_0_mult_out_rob_2_7), 
        .ROB6(mult_0_mult_out_rob_2_6), .ROB5(mult_0_mult_out_rob_2_5), 
        .ROB4(mult_0_mult_out_rob_2_4), .ROB3(mult_0_mult_out_rob_2_3), 
        .ROB2(mult_0_mult_out_rob_2_2), .ROB1(mult_0_mult_out_rob_2_1), 
        .ROB0(mult_0_mult_out_rob_2_0), .ROC17(), .ROC16(), .ROC15(), .ROC14(), 
        .ROC13(), .ROC12(), .ROC11(), .ROC10(), .ROC9(), .ROC8(), .ROC7(), 
        .ROC6(), .ROC5(), .ROC4(), .ROC3(), .ROC2(), .ROC1(), .ROC0(), .P35(mult_0_mult_out_p_2_35), 
        .P34(mult_0_mult_out_p_2_34), .P33(mult_0_mult_out_p_2_33), .P32(mult_0_mult_out_p_2_32), 
        .P31(mult_0_mult_out_p_2_31), .P30(mult_0_mult_out_p_2_30), .P29(mult_0_mult_out_p_2_29), 
        .P28(mult_0_mult_out_p_2_28), .P27(mult_0_mult_out_p_2_27), .P26(mult_0_mult_out_p_2_26), 
        .P25(mult_0_mult_out_p_2_25), .P24(mult_0_mult_out_p_2_24), .P23(mult_0_mult_out_p_2_23), 
        .P22(mult_0_mult_out_p_2_22), .P21(mult_0_mult_out_p_2_21), .P20(mult_0_mult_out_p_2_20), 
        .P19(mult_0_mult_out_p_2_19), .P18(mult_0_mult_out_p_2_18), .P17(mult_0_mult_out_p_2_17), 
        .P16(mult_0_mult_out_p_2_16), .P15(mult_0_mult_out_p_2_15), .P14(mult_0_mult_out_p_2_14), 
        .P13(mult_0_mult_out_p_2_13), .P12(mult_0_mult_out_p_2_12), .P11(mult_0_mult_out_p_2_11), 
        .P10(mult_0_mult_out_p_2_10), .P9(mult_0_mult_out_p_2_9), .P8(mult_0_mult_out_p_2_8), 
        .P7(mult_0_mult_out_p_2_7), .P6(mult_0_mult_out_p_2_6), .P5(mult_0_mult_out_p_2_5), 
        .P4(mult_0_mult_out_p_2_4), .P3(mult_0_mult_out_p_2_3), .P2(mult_0_mult_out_p_2_2), 
        .P1(mult_0_mult_out_p_2_1), .P0(mult_0_mult_out_p_2_0), .SIGNEDP(mult_0_mult_out_signedp_2));

//    VHI scuba_vhi_inst (.Z(scuba_vhi));

//    VLO scuba_vlo_inst (.Z(scuba_vlo));


    defparam dsp_mult_0.CLK3_DIV = "ENABLED" ;
    defparam dsp_mult_0.CLK2_DIV = "ENABLED" ;
    defparam dsp_mult_0.CLK1_DIV = "ENABLED" ;
    defparam dsp_mult_0.CLK0_DIV = "ENABLED" ;
//    defparam dsp_mult_0.HIGHSPEED_CLK = "NONE" ;
//    defparam dsp_mult_0.REG_INPUTC_RST = "RST0" ;
//    defparam dsp_mult_0.REG_INPUTC_CE = "CE0" ;
    defparam dsp_mult_0.REG_INPUTC_CLK = "NONE" ;
    defparam dsp_mult_0.SOURCEB_MODE = "B_SHIFT" ;
//    defparam dsp_mult_0.MULT_BYPASS = "DISABLED" ;
//    defparam dsp_mult_0.CAS_MATCH_REG = "FALSE" ;
    defparam dsp_mult_0.RESETMODE = "SYNC" ;
    defparam dsp_mult_0.GSR = "ENABLED" ;
//    defparam dsp_mult_0.REG_OUTPUT_RST = "RST0" ;
//    defparam dsp_mult_0.REG_OUTPUT_CE = "CE0" ;
    defparam dsp_mult_0.REG_OUTPUT_CLK = "NONE" ;
    defparam dsp_mult_0.REG_PIPELINE_RST = "RST0" ;
    defparam dsp_mult_0.REG_PIPELINE_CE = "CE0" ;
    defparam dsp_mult_0.REG_PIPELINE_CLK = "CLK0" ;
    defparam dsp_mult_0.REG_INPUTB_RST = "RST0" ;
    defparam dsp_mult_0.REG_INPUTB_CE = "CE0" ;
    defparam dsp_mult_0.REG_INPUTB_CLK = "CLK0" ;
    defparam dsp_mult_0.REG_INPUTA_RST = "RST0" ;
    defparam dsp_mult_0.REG_INPUTA_CE = "CE0" ;
    defparam dsp_mult_0.REG_INPUTA_CLK = "CLK0" ;
    MULT18X18D dsp_mult_0 (.A17(A[31]), .A16(A[30]), .A15(A[29]), .A14(A[28]), 
        .A13(A[27]), .A12(A[26]), .A11(A[25]), .A10(A[24]), .A9(A[23]), 
        .A8(A[22]), .A7(A[21]), .A6(A[20]), .A5(A[19]), .A4(A[18]), .A3(A[17]), 
        .A2(A[16]), .A1(A[15]), .A0(A[14]), .B17(B[31]), .B16(B[30]), .B15(B[29]), 
        .B14(B[28]), .B13(B[27]), .B12(B[26]), .B11(B[25]), .B10(B[24]), 
        .B9(B[23]), .B8(B[22]), .B7(B[21]), .B6(B[20]), .B5(B[19]), .B4(B[18]), 
        .B3(B[17]), .B2(B[16]), .B1(B[15]), .B0(B[14]), .C17(scuba_vlo), 
        .C16(scuba_vlo), .C15(scuba_vlo), .C14(scuba_vlo), .C13(scuba_vlo), 
        .C12(scuba_vlo), .C11(scuba_vlo), .C10(scuba_vlo), .C9(scuba_vlo), 
        .C8(scuba_vlo), .C7(scuba_vlo), .C6(scuba_vlo), .C5(scuba_vlo), 
        .C4(scuba_vlo), .C3(scuba_vlo), .C2(scuba_vlo), .C1(scuba_vlo), 
        .C0(scuba_vlo), .SIGNEDA(SignA), .SIGNEDB(SignB), .SOURCEA(scuba_vlo), 
        .SOURCEB(scuba_vlo), .CE0(CE0), .CE1(scuba_vhi), .CE2(scuba_vhi), 
        .CE3(scuba_vhi), .CLK0(CLK0), .CLK1(scuba_vlo), .CLK2(scuba_vlo), 
        .CLK3(scuba_vlo), .RST0(RST0), .RST1(scuba_vlo), .RST2(scuba_vlo), 
        .RST3(scuba_vlo),  .SROA17(), .SROA16(), .SROA15(), .SROA14(), .SROA13(), 
        .SROA12(), .SROA11(), .SROA10(), .SROA9(), .SROA8(), .SROA7(), .SROA6(), 
        .SROA5(), .SROA4(), .SROA3(), .SROA2(), .SROA1(), .SROA0(), .SROB17(mult_shift_out_b_4_1_1_17), 
        .SROB16(mult_shift_out_b_4_1_1_16), .SROB15(mult_shift_out_b_4_1_1_15), 
        .SROB14(mult_shift_out_b_4_1_1_14), .SROB13(mult_shift_out_b_4_1_1_13), 
        .SROB12(mult_shift_out_b_4_1_1_12), .SROB11(mult_shift_out_b_4_1_1_11), 
        .SROB10(mult_shift_out_b_4_1_1_10), .SROB9(mult_shift_out_b_4_1_1_9), 
        .SROB8(mult_shift_out_b_4_1_1_8), .SROB7(mult_shift_out_b_4_1_1_7), 
        .SROB6(mult_shift_out_b_4_1_1_6), .SROB5(mult_shift_out_b_4_1_1_5), 
        .SROB4(mult_shift_out_b_4_1_1_4), .SROB3(mult_shift_out_b_4_1_1_3), 
        .SROB2(mult_shift_out_b_4_1_1_2), .SROB1(mult_shift_out_b_4_1_1_1), 
        .SROB0(mult_shift_out_b_4_1_1_0), .ROA17(mult_0_mult_out_roa_3_17), 
        .ROA16(mult_0_mult_out_roa_3_16), .ROA15(mult_0_mult_out_roa_3_15), 
        .ROA14(mult_0_mult_out_roa_3_14), .ROA13(mult_0_mult_out_roa_3_13), 
        .ROA12(mult_0_mult_out_roa_3_12), .ROA11(mult_0_mult_out_roa_3_11), 
        .ROA10(mult_0_mult_out_roa_3_10), .ROA9(mult_0_mult_out_roa_3_9), 
        .ROA8(mult_0_mult_out_roa_3_8), .ROA7(mult_0_mult_out_roa_3_7), 
        .ROA6(mult_0_mult_out_roa_3_6), .ROA5(mult_0_mult_out_roa_3_5), 
        .ROA4(mult_0_mult_out_roa_3_4), .ROA3(mult_0_mult_out_roa_3_3), 
        .ROA2(mult_0_mult_out_roa_3_2), .ROA1(mult_0_mult_out_roa_3_1), 
        .ROA0(mult_0_mult_out_roa_3_0), .ROB17(mult_0_mult_out_rob_3_17), 
        .ROB16(mult_0_mult_out_rob_3_16), .ROB15(mult_0_mult_out_rob_3_15), 
        .ROB14(mult_0_mult_out_rob_3_14), .ROB13(mult_0_mult_out_rob_3_13), 
        .ROB12(mult_0_mult_out_rob_3_12), .ROB11(mult_0_mult_out_rob_3_11), 
        .ROB10(mult_0_mult_out_rob_3_10), .ROB9(mult_0_mult_out_rob_3_9), 
        .ROB8(mult_0_mult_out_rob_3_8), .ROB7(mult_0_mult_out_rob_3_7), 
        .ROB6(mult_0_mult_out_rob_3_6), .ROB5(mult_0_mult_out_rob_3_5), 
        .ROB4(mult_0_mult_out_rob_3_4), .ROB3(mult_0_mult_out_rob_3_3), 
        .ROB2(mult_0_mult_out_rob_3_2), .ROB1(mult_0_mult_out_rob_3_1), 
        .ROB0(mult_0_mult_out_rob_3_0), .ROC17(), .ROC16(), .ROC15(), .ROC14(), 
        .ROC13(), .ROC12(), .ROC11(), .ROC10(), .ROC9(), .ROC8(), .ROC7(), 
        .ROC6(), .ROC5(), .ROC4(), .ROC3(), .ROC2(), .ROC1(), .ROC0(), .P35(mult_0_mult_out_p_3_35), 
        .P34(mult_0_mult_out_p_3_34), .P33(mult_0_mult_out_p_3_33), .P32(mult_0_mult_out_p_3_32), 
        .P31(mult_0_mult_out_p_3_31), .P30(mult_0_mult_out_p_3_30), .P29(mult_0_mult_out_p_3_29), 
        .P28(mult_0_mult_out_p_3_28), .P27(mult_0_mult_out_p_3_27), .P26(mult_0_mult_out_p_3_26), 
        .P25(mult_0_mult_out_p_3_25), .P24(mult_0_mult_out_p_3_24), .P23(mult_0_mult_out_p_3_23), 
        .P22(mult_0_mult_out_p_3_22), .P21(mult_0_mult_out_p_3_21), .P20(mult_0_mult_out_p_3_20), 
        .P19(mult_0_mult_out_p_3_19), .P18(mult_0_mult_out_p_3_18), .P17(mult_0_mult_out_p_3_17), 
        .P16(mult_0_mult_out_p_3_16), .P15(mult_0_mult_out_p_3_15), .P14(mult_0_mult_out_p_3_14), 
        .P13(mult_0_mult_out_p_3_13), .P12(mult_0_mult_out_p_3_12), .P11(mult_0_mult_out_p_3_11), 
        .P10(mult_0_mult_out_p_3_10), .P9(mult_0_mult_out_p_3_9), .P8(mult_0_mult_out_p_3_8), 
        .P7(mult_0_mult_out_p_3_7), .P6(mult_0_mult_out_p_3_6), .P5(mult_0_mult_out_p_3_5), 
        .P4(mult_0_mult_out_p_3_4), .P3(mult_0_mult_out_p_3_3), .P2(mult_0_mult_out_p_3_2), 
        .P1(mult_0_mult_out_p_3_1), .P0(mult_0_mult_out_p_3_0), .SIGNEDP(mult_0_mult_out_signedp_3));

    assign P[9] = mult_alu_output_r_1_0_17;
    assign P[8] = mult_alu_output_r_1_0_16;
    assign P[7] = mult_alu_output_r_1_0_15;
    assign P[6] = mult_alu_output_r_1_0_14;
    assign P[5] = mult_alu_output_r_1_0_13;
    assign P[4] = mult_alu_output_r_1_0_12;
    assign P[3] = mult_alu_output_r_1_0_11;
    assign P[2] = mult_alu_output_r_1_0_10;
    assign P[1] = mult_alu_output_r_1_0_9;
    assign P[0] = mult_alu_output_r_1_0_8;
    assign P[63] = mult_alu_output_r_2_1_53;
    assign P[62] = mult_alu_output_r_2_1_52;
    assign P[61] = mult_alu_output_r_2_1_51;
    assign P[60] = mult_alu_output_r_2_1_50;
    assign P[59] = mult_alu_output_r_2_1_49;
    assign P[58] = mult_alu_output_r_2_1_48;
    assign P[57] = mult_alu_output_r_2_1_47;
    assign P[56] = mult_alu_output_r_2_1_46;
    assign P[55] = mult_alu_output_r_2_1_45;
    assign P[54] = mult_alu_output_r_2_1_44;
    assign P[53] = mult_alu_output_r_2_1_43;
    assign P[52] = mult_alu_output_r_2_1_42;
    assign P[51] = mult_alu_output_r_2_1_41;
    assign P[50] = mult_alu_output_r_2_1_40;
    assign P[49] = mult_alu_output_r_2_1_39;
    assign P[48] = mult_alu_output_r_2_1_38;
    assign P[47] = mult_alu_output_r_2_1_37;
    assign P[46] = mult_alu_output_r_2_1_36;
    assign P[45] = mult_alu_output_r_2_1_35;
    assign P[44] = mult_alu_output_r_2_1_34;
    assign P[43] = mult_alu_output_r_2_1_33;
    assign P[42] = mult_alu_output_r_2_1_32;
    assign P[41] = mult_alu_output_r_2_1_31;
    assign P[40] = mult_alu_output_r_2_1_30;
    assign P[39] = mult_alu_output_r_2_1_29;
    assign P[38] = mult_alu_output_r_2_1_28;
    assign P[37] = mult_alu_output_r_2_1_27;
    assign P[36] = mult_alu_output_r_2_1_26;
    assign P[35] = mult_alu_output_r_2_1_25;
    assign P[34] = mult_alu_output_r_2_1_24;
    assign P[33] = mult_alu_output_r_2_1_23;
    assign P[32] = mult_alu_output_r_2_1_22;
    assign P[31] = mult_alu_output_r_2_1_21;
    assign P[30] = mult_alu_output_r_2_1_20;
    assign P[29] = mult_alu_output_r_2_1_19;
    assign P[28] = mult_alu_output_r_2_1_18;
    assign P[27] = mult_alu_output_r_2_1_17;
    assign P[26] = mult_alu_output_r_2_1_16;
    assign P[25] = mult_alu_output_r_2_1_15;
    assign P[24] = mult_alu_output_r_2_1_14;
    assign P[23] = mult_alu_output_r_2_1_13;
    assign P[22] = mult_alu_output_r_2_1_12;
    assign P[21] = mult_alu_output_r_2_1_11;
    assign P[20] = mult_alu_output_r_2_1_10;
    assign P[19] = mult_alu_output_r_2_1_9;
    assign P[18] = mult_alu_output_r_2_1_8;
    assign P[17] = mult_alu_output_r_2_1_7;
    assign P[16] = mult_alu_output_r_2_1_6;
    assign P[15] = mult_alu_output_r_2_1_5;
    assign P[14] = mult_alu_output_r_2_1_4;
    assign P[13] = mult_alu_output_r_2_1_3;
    assign P[12] = mult_alu_output_r_2_1_2;
    assign P[11] = mult_alu_output_r_2_1_1;
    assign P[10] = mult_alu_output_r_2_1_0;


endmodule
