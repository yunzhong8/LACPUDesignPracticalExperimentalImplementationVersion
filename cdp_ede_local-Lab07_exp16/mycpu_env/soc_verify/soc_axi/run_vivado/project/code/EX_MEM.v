/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*
*/
/*************\
bug:
\*************/
`include "DefineModuleBus.h"
module EX_MEM(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
      //控制本阶段id组合逻辑运算完的数据是否可以锁存起来，供给exe使用
    input wire line1_pre_to_now_valid_i,//if_id输出的表示，if阶段的数据可以输出到id阶段
    input wire line2_pre_to_now_valid_i,//if_id输出的表示，if阶段的数据可以输出到id阶段
    input wire excep_flush_i,
   
    
    //id阶段的状态机
    input wire now_allowin_i,//id组合逻辑传入，表示id阶段当前数据已经运算完了
    output reg line1_now_valid_o,//输出下一个状态
    output reg line2_now_valid_o,//输出下一个状态
    
    //数据缓存，可以不设计，因为目前不存在mem阶段ready了，但是wb阶段不允许输入的情况
    //数据取消
    input  wire data_ram_rdata_ce_we_i,
    input  wire data_ram_rdata_ce_i,
    input  wire  [`ExToMemBusWidth]pre_to_ibus  ,
    
    output  reg data_ram_rdata_ce_o,
    output reg  [`ExToMemBusWidth]to_mem_obus       
);

/***************************************input variable define(输入变量定义)**************************************/

/***************************************output variable define(输出变量定义)**************************************/

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/

/****************************************input decode(输入解码)***************************************/


/****************************************output code(输出解码)***************************************/

/*******************************complete logical function (逻辑功能实现)*******************************/
always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        to_mem_obus <= `ExToMemBusLen'd0;
    end else if((line1_pre_to_now_valid_i||line2_pre_to_now_valid_i) && now_allowin_i) begin
        to_mem_obus <= pre_to_ibus;
    end else begin
        to_mem_obus <= to_mem_obus;
    end
end

always@(posedge clk)begin
        if(rst_n == `RstEnable ||excep_flush_i)begin
            line1_now_valid_o <= 1'b0;
        end else if(now_allowin_i)begin
           line1_now_valid_o <= line1_pre_to_now_valid_i;
        end else begin
             line1_now_valid_o <= line1_now_valid_o;
        end
 end
 
always@(posedge clk)begin
        if(rst_n == `RstEnable ||excep_flush_i)begin
            line2_now_valid_o <= 1'b0;
        end else if(now_allowin_i)begin
           line2_now_valid_o <= line2_pre_to_now_valid_i;
        end else begin
             line2_now_valid_o <= line2_now_valid_o;
        end
    end
    
 //指令读出数据无效
   always@(posedge clk)begin
        if(rst_n == `RstEnable )begin
            data_ram_rdata_ce_o <= 1'b0;
        end else if(data_ram_rdata_ce_we_i)begin
            data_ram_rdata_ce_o <= data_ram_rdata_ce_i;
        end else begin
            data_ram_rdata_ce_o <= data_ram_rdata_ce_o;
        end
   end
 //缓存一次读出数据
 
endmodule
