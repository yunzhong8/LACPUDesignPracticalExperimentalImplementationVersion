`timescale 1ns / 1ps
/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：预测uncache属性，地址截取从pc的[16:12]因为不同页的uncache属性极有可能不一样，同一个页的一般一样，不使用饱和计数器机制，因为uncache属性不会像跳转指令一样出现反复跳转的情况
*
*/
/*************\
bug:
\*************/
//`include "DefineLoogLenWidth.h"
`include "define.v"
module Predactor_PUC(
input  wire                    rst_n        ,
input  wire                    clk          ,
//预测pc
input  wire   [`PucAddrWidth]raddr_i,
output wire   uncache_o,
input wire   [`PucWbusWidth] wbus_i
    );
    
 /***************************************input variable define(输入变量定义)**************************************/


/***************************************output variable define(输出变量定义)**************************************/
 wire  we_i;
 wire  [`PucAddrWidth]waddr_i;
 wire  wdata_i;
 






/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
reg [0:0]PUC_REG[0:31];//2^5
integer i;
/****************************************input decode(输入解码)***************************************/
assign { we_i,waddr_i, wdata_i} = wbus_i;
/****************************************output decode(输出解码)***************************************/


/*******************************complete logical function (逻辑功能实现)*******************************/

 always @(posedge clk)begin
    if(rst_n==`RstEnable)begin
        for(i=0;i<32;i=i+1) PUC_REG[i] <= 32'h1;
    end else if(we_i)begin
        PUC_REG[waddr_i] <=wdata_i;
    end else begin
        for(i=0;i<32;i=i+1) PUC_REG[i] <=  PUC_REG[i];
    end 
 end   
 
assign uncache_o = we_i&(waddr_i==raddr_i)? wdata_i:PUC_REG[raddr_i];
    

endmodule

