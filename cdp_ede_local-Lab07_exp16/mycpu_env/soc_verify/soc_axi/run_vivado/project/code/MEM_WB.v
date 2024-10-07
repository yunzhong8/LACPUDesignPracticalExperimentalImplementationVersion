/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*ea块功能：
*
*/
/*************\
bug:
\*************/
`include "DefineModuleBus.h"
module MEM_WB(
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


    input  wire  [`MemToWbBusWidth]pre_to_ibus  ,                                                
    output reg [`MemToWbBusWidth] to_wb_obus   
);

/***************************************input variable define(输入变量定义)**************************************/
wire [`PcWidth] pc_o;
wire [`InstWidth] inst_o;
/***************************************output variable define(输出变量定义)**************************************/

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/

/****************************************input decode(输入解码)***************************************/


/****************************************output code(输出解码)***************************************/
/*******************************complete logical function (逻辑功能实现)*******************************/
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        to_wb_obus <= `MemToWbBusLen'd0;
    end else if((line1_pre_to_now_valid_i||line2_pre_to_now_valid_i) && now_allowin_i) begin
        to_wb_obus <= pre_to_ibus;
    end else begin
        to_wb_obus <= to_wb_obus;
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

endmodule
