/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：实现7一个队列,这是一个只支持一个写，一个读队列
问题：队列的的关键元素是什么，我需要根据这个这元素设置输入输出
*队尾移动
lunch允许输入
    
lunch:发射了两条指令,则移动两个
lunch:发射了两条空指令,则不移动
lunch:发射了一条指令,则移动一个
队头移动
当前阶段允许输入
输入两条有效指令则队头移动2
输入一条有效指令则队头移动1
输入0条有效指令,则不移动
*/
/*************\
bug:
\*************/
`include "DefineModuleBus.h"
module Error
(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
    //接受错误使能
    input wire inst_cache_error_i,
    input wire data_cache_error_i,
    input wire if_error_i,
    input wire ift_error_i,
    input wire id_error_i,
    input wire launch_error_i,
    input wire ex_error_i,
    input wire mm_error_i,
    input wire mem_error_i,
    input wire wb_error_i ,
    
    //发错错误
    output wire cpu_inner_error_o
   
);

/***************************************input variable define(输入变量定义)**************************************/
  wire error_i;
  assign error_i= inst_cache_error_i|data_cache_error_i|if_error_i|ift_error_i|id_error_i|launch_error_i|ex_error_i|mm_error_i|mem_error_i|wb_error_i;

/***************************************output variable define(输出变量定义)**************************************/
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
reg error_reg;
/****************************************input decode(输入解码)***************************************/

/****************************************output code(输出解码)***************************************/
assign cpu_inner_error_o = error_reg;
/*******************************complete logical function (逻辑功能实现)*******************************/
always @(posedge clk )begin
    if(rst_n == `RstEnable)begin
        error_reg <=1'b0;
    end  else if (error_i)begin
         error_reg <=1'b1;
    end else begin
         error_reg <=error_reg;
    end 
end 


endmodule
























