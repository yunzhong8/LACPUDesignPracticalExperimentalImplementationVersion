// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
// Date        : Wed Jul 19 09:24:50 2023
// Host        : nb running 64-bit Ubuntu 22.04.2 LTS
// Command     : write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ clk_pll_sim_netlist.v
// Design      : clk_pll
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7a200tfbg676-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* NotValidForBitStream *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix
   (cpu_clk,
    sys_clk,
    clk_60,
    clk_70,
    clk_80,
    clk_90,
    clk_in1);
  output cpu_clk;
  output sys_clk;
  output clk_60;
  output clk_70;
  output clk_80;
  output clk_90;
  input clk_in1;

  wire clk_60;
  wire clk_70;
  wire clk_80;
  wire clk_90;
  (* IBUF_LOW_PWR *) wire clk_in1;
  wire cpu_clk;
  wire sys_clk;

  decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_clk_pll_clk_wiz inst
       (.clk_60(clk_60),
        .clk_70(clk_70),
        .clk_80(clk_80),
        .clk_90(clk_90),
        .clk_in1(clk_in1),
        .cpu_clk(cpu_clk),
        .sys_clk(sys_clk));
endmodule

module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_clk_pll_clk_wiz
   (cpu_clk,
    sys_clk,
    clk_60,
    clk_70,
    clk_80,
    clk_90,
    clk_in1);
  output cpu_clk;
  output sys_clk;
  output clk_60;
  output clk_70;
  output clk_80;
  output clk_90;
  input clk_in1;

  wire clk_60;
  wire clk_60_clk_pll;
  wire clk_70;
  wire clk_70_clk_pll;
  wire clk_80;
  wire clk_80_clk_pll;
  wire clk_90;
  wire clk_90_clk_pll;
  wire clk_in1;
  wire clk_in1_clk_pll;
  wire clkfbout_buf_clk_pll;
  wire clkfbout_clk_pll;
  wire cpu_clk;
  wire cpu_clk_clk_pll;
  wire sys_clk;
  wire sys_clk_clk_pll;
  wire NLW_plle2_adv_inst_DRDY_UNCONNECTED;
  wire NLW_plle2_adv_inst_LOCKED_UNCONNECTED;
  wire [15:0]NLW_plle2_adv_inst_DO_UNCONNECTED;

  (* BOX_TYPE = "PRIMITIVE" *) 
  BUFG clkf_buf
       (.I(clkfbout_clk_pll),
        .O(clkfbout_buf_clk_pll));
  (* BOX_TYPE = "PRIMITIVE" *) 
  (* CAPACITANCE = "DONT_CARE" *) 
  (* IBUF_DELAY_VALUE = "0" *) 
  (* IFD_DELAY_VALUE = "AUTO" *) 
  IBUF #(
    .IOSTANDARD("DEFAULT")) 
    clkin1_ibufg
       (.I(clk_in1),
        .O(clk_in1_clk_pll));
  (* BOX_TYPE = "PRIMITIVE" *) 
  BUFG clkout1_buf
       (.I(cpu_clk_clk_pll),
        .O(cpu_clk));
  (* BOX_TYPE = "PRIMITIVE" *) 
  BUFG clkout2_buf
       (.I(sys_clk_clk_pll),
        .O(sys_clk));
  (* BOX_TYPE = "PRIMITIVE" *) 
  BUFG clkout3_buf
       (.I(clk_60_clk_pll),
        .O(clk_60));
  (* BOX_TYPE = "PRIMITIVE" *) 
  BUFG clkout4_buf
       (.I(clk_70_clk_pll),
        .O(clk_70));
  (* BOX_TYPE = "PRIMITIVE" *) 
  BUFG clkout5_buf
       (.I(clk_80_clk_pll),
        .O(clk_80));
  (* BOX_TYPE = "PRIMITIVE" *) 
  BUFG clkout6_buf
       (.I(clk_90_clk_pll),
        .O(clk_90));
  (* BOX_TYPE = "PRIMITIVE" *) 
  PLLE2_ADV #(
    .BANDWIDTH("OPTIMIZED"),
    .CLKFBOUT_MULT(13),
    .CLKFBOUT_PHASE(0.000000),
    .CLKIN1_PERIOD(10.000000),
    .CLKIN2_PERIOD(0.000000),
    .CLKOUT0_DIVIDE(20),
    .CLKOUT0_DUTY_CYCLE(0.500000),
    .CLKOUT0_PHASE(0.000000),
    .CLKOUT1_DIVIDE(13),
    .CLKOUT1_DUTY_CYCLE(0.500000),
    .CLKOUT1_PHASE(0.000000),
    .CLKOUT2_DIVIDE(22),
    .CLKOUT2_DUTY_CYCLE(0.500000),
    .CLKOUT2_PHASE(0.000000),
    .CLKOUT3_DIVIDE(19),
    .CLKOUT3_DUTY_CYCLE(0.500000),
    .CLKOUT3_PHASE(0.000000),
    .CLKOUT4_DIVIDE(16),
    .CLKOUT4_DUTY_CYCLE(0.500000),
    .CLKOUT4_PHASE(0.000000),
    .CLKOUT5_DIVIDE(14),
    .CLKOUT5_DUTY_CYCLE(0.500000),
    .CLKOUT5_PHASE(0.000000),
    .COMPENSATION("ZHOLD"),
    .DIVCLK_DIVIDE(1),
    .IS_CLKINSEL_INVERTED(1'b0),
    .IS_PWRDWN_INVERTED(1'b0),
    .IS_RST_INVERTED(1'b0),
    .REF_JITTER1(0.010000),
    .REF_JITTER2(0.010000),
    .STARTUP_WAIT("FALSE")) 
    plle2_adv_inst
       (.CLKFBIN(clkfbout_buf_clk_pll),
        .CLKFBOUT(clkfbout_clk_pll),
        .CLKIN1(clk_in1_clk_pll),
        .CLKIN2(1'b0),
        .CLKINSEL(1'b1),
        .CLKOUT0(cpu_clk_clk_pll),
        .CLKOUT1(sys_clk_clk_pll),
        .CLKOUT2(clk_60_clk_pll),
        .CLKOUT3(clk_70_clk_pll),
        .CLKOUT4(clk_80_clk_pll),
        .CLKOUT5(clk_90_clk_pll),
        .DADDR({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .DCLK(1'b0),
        .DEN(1'b0),
        .DI({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .DO(NLW_plle2_adv_inst_DO_UNCONNECTED[15:0]),
        .DRDY(NLW_plle2_adv_inst_DRDY_UNCONNECTED),
        .DWE(1'b0),
        .LOCKED(NLW_plle2_adv_inst_LOCKED_UNCONNECTED),
        .PWRDWN(1'b0),
        .RST(1'b0));
endmodule
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule
`endif
