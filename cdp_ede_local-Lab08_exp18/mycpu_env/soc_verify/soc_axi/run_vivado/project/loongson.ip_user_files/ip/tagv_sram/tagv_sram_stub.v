// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (lin64) Build 2708876 Wed Nov  6 21:39:14 MST 2019
// Date        : Mon May 22 18:41:05 2023
// Host        : nb running 64-bit Ubuntu 22.04.2 LTS
// Command     : write_verilog -force -mode synth_stub
//               /home/ysyx/zzq/Code/LoogArch/cdp_ede_local-Lab08_exp18/mycpu_env/soc_verify/soc_axi/run_vivado/project/loongson.runs/tagv_sram_synth_1/tagv_sram_stub.v
// Design      : tagv_sram
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg676-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module tagv_sram(clka, ena, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[7:0],dina[20:0],douta[20:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [7:0]addra;
  input [20:0]dina;
  output [20:0]douta;
endmodule