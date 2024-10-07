// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
// Date        : Wed Jul 19 14:14:21 2023
// Host        : nb running 64-bit Ubuntu 22.04.2 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/ysyx/weihui/la32_7pipline-cpu-master/mycpu_env/soc_verify/soc_axi/rtl/xilinx_ip/clk_pll/clk_pll_stub.v
// Design      : clk_pll
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg676-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module clk_pll(cpu_clk, sys_clk, clk_60, clk_70, clk_80, clk_90, 
  clk_in1)
/* synthesis syn_black_box black_box_pad_pin="cpu_clk,sys_clk,clk_60,clk_70,clk_80,clk_90,clk_in1" */;
  output cpu_clk;
  output sys_clk;
  output clk_60;
  output clk_70;
  output clk_80;
  output clk_90;
  input clk_in1;
endmodule
