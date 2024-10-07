`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/07 18:43:25
// Design Name: 
// Module Name: Predactor_Pht
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "define.v"
module Predactor_Pht(
    input wire rst_n,
    input wire clk,
    
    //更新
    //更新使能
    input wire [`PhtWbusWidth]    w_ibus,
    
    //读地址
    input wire [`ScountAddrWidth]raddr_i,
    //读出饱和计数器的值
    output wire [`ScountStateWidth]rdata_o

  );
 /***************************************input variable define(输入变量定义)**************************************/   
 wire we_i;
//更新地址
 wire [`ScountAddrWidth]waddr_i;
//更新的状态
 wire [`ScountStateWidth]wdata_i;//状态转移由发出更新的端维护
 wire re;
 wire [`ScountStateWidth]rdata;
 /****************************************input decode(输入解码)***************************************/
 assign {we_i,waddr_i,wdata_i} =  w_ibus;
 
 /*******************************complete logical function (逻辑功能实现)*******************************/   
 //assign re = we_i &&(waddr_i==raddr_o) ? 1'b0 : 1'b1;
 assign rdata_o = rdata;
 pht_ram pht_ram_item (
  .clka(clk),    // input wire clka
  
  //饱和计数器写入
  .ena(1'b1),      // input wire ena
  .wea(we_i),      // input wire [0 : 0] wea
  .addra(waddr_i),  // input wire [9 : 0] addra
  .dina(wdata_i),    // input wire [2: 0] dina
  
  //饱和计数器读出
  .clkb(clk),    // input wire clkb
  .enb(1'b1),      // input wire enb
  .addrb(raddr_i),  // input wire [9 : 0] addrb
  .doutb(rdata)  // output wire [2 : 0] doutb
);
   
 
endmodule
