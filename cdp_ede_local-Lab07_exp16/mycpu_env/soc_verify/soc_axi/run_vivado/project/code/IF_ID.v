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
module IF_ID(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
     //控制本阶段id组合逻辑运算完的数据是否可以锁存起来，供给exe使用
    input wire line1_pre_to_now_valid_i,//if_id输出的表示，if阶段的数据可以输出到id阶段
    input wire line2_pre_to_now_valid_i,//if_id输出的表示，if阶段的数据可以输出到id阶段
    //id阶段的状态机
    input wire now_allowin_i,//id组合逻辑传入，表示id阶段当前数据已经运算完了
    
    
    output reg line1_now_valid_o,//输出下一个状态
    output reg line2_now_valid_o,
    //冲刷信号
    input wire branch_flush_i,//冲刷流水信号
    input wire excep_flush_i,
    //发射暂停信号
    input wire lunch_stall_i,
    input wire [`IfToIdBusWidth]lunch_stall_if_to_id_ibus,
    //数据域
    input  wire  [`IfToIdBusWidth] pre_to_ibus,
    
    output reg  [`IfToIdBusWidth]to_id_obus         
);

/***************************************input variable define(输入变量定义)**************************************/
/***************************************output variable define(输出变量定义)**************************************/
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/

/****************************************input decode(输入解码)***************************************/
/****************************************output code(输出解码)***************************************/
/*******************************complete logical function (逻辑功能实现)*******************************/
 //流水线1
 always@(posedge clk)begin
        if(rst_n == `RstEnable || branch_flush_i ||excep_flush_i)begin
            line1_now_valid_o <= 1'b0;
        end else if(now_allowin_i)begin
            line1_now_valid_o <= line1_pre_to_now_valid_i;
        end else begin
            line1_now_valid_o <= line1_now_valid_o;
        end
    end
//流水线2
 always@(posedge clk)begin
        if(rst_n == `RstEnable || branch_flush_i ||excep_flush_i||lunch_stall_i)begin
            line2_now_valid_o <= 1'b0;
        end else if(now_allowin_i)begin
            line2_now_valid_o <= line2_pre_to_now_valid_i;
        end else begin
            line2_now_valid_o <= line2_now_valid_o;
        end
    end


always@(posedge clk)begin
    if(rst_n == `RstEnable)begin
        to_id_obus <= `IfToIdBusLen'h0;
    end else if(lunch_stall_i) begin
        to_id_obus <= lunch_stall_if_to_id_ibus;
    end else if((line1_pre_to_now_valid_i || line2_pre_to_now_valid_i)&& now_allowin_i) begin//if id阶段完成计算即allowIn=1,并且if阶段打算流入数据即valid=1，则在时钟上升沿时候写入数据
        to_id_obus <= pre_to_ibus;
    end else begin//暂停流水
        to_id_obus <= to_id_obus;
        end
end




endmodule
