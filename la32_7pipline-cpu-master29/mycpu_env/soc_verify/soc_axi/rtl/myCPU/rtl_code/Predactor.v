`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/07 20:07:06
// Design Name: 
// Module Name: Predactor_Btb
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
// hit,和branch_pc要往下传递，方便id阶段返回修正btb表
//////////////////////////////////////////////////////////////////////////////////
`include "DefineLoogLenWidth.h"

module Predactor(
input  wire                    rst_n        ,
input  wire                    clk          ,
//预测pc
input  wire  [`PcWidth]        pc_i         ,

input  wire                    if_allowin_i ,
//预测结果
output wire [`PrToIfBusWidth]  to_if_obus   ,
//预测器更新
input wire  [`PtoWbusWidth]    id_to_ibus

    );
    
 /***************************************input variable define(输入变量定义)**************************************/

wire [`PhtWbusWidth]  pht_wbus_i ;
wire [`BtbWbusWidth]  btb_wbus_i ;
/***************************************output variable define(输出变量定义)**************************************/
 //pht预测
 //预测结果是否有效(该信号只用告诉if阶段地址已经预测完成了,如果if没有完成,则保存预测地址)
 reg predict_valid_o ;
 //预测是否跳转
 //1为命中，0为没有命中则使用pc+4
 wire branch_o ;
 //跳转预测状态
 wire [1:0]pht_rdata_o ;
 
 //btb预测
 //btb地址表是否命中,btb没有命中则使用顺序地址
 wire btb_hit_o;
 //btb地址预测的跳转地址
 wire [`PcWidth]btb_branch_pc_o;





/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
wire [`PcWidth] btb_branch_pc;
/****************************************input decode(输入解码)***************************************/
assign {pht_wbus_i,btb_wbus_i} = id_to_ibus;
/****************************************output decode(输出解码)***************************************/
assign to_if_obus = {predict_valid_o,branch_o,pht_rdata_o,btb_hit_o,btb_branch_pc_o};

/*******************************complete logical function (逻辑功能实现)*******************************/
//跳转方向预测状态机表pht
Predactor_Pht Predactor_Pht_item(
     .rst_n (rst_n)         ,
     .clk   (clk)           ,

     .w_ibus(pht_wbus_i)    ,
 
     .raddr_i (pc_i[12:3])  ,
     .rdata_o (pht_rdata_o)


    );




//地址预测表btb
Predactor_Btb Predactor_Btb_item(
        .rst_n           (rst_n)         ,
        .clk             (clk)           ,
        
        .pc_i            (pc_i)          ,
        
        .w_ibus          (btb_wbus_i)    ,
        .hit_o           (btb_hit_o)     ,
        .btb_branch_pc_o (btb_branch_pc)
    );
    
   
    //因为preif阶段会进行+4 
   assign btb_branch_pc_o = btb_branch_pc;  
    //00表示强not take,01表示弱not take, 10表示弱take,11表示强take
    
    
    //[1]=0表示不跳转,[1]==1表示跳转 
    assign branch_o = pht_rdata_o[1];
    
always @(posedge clk)begin
    if(rst_n==`RstEnable)begin
        predict_valid_o <= 1'b0;
    end else if(if_allowin_i)begin
        predict_valid_o <= 1'b1;
    end else begin
        predict_valid_o <= 1'b0;
    end
end    
    

    

endmodule

