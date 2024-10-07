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
1. cache_rdata_ce_we_i位宽是2写成1了
\*************/
//`include "DefineModuleBus.h"
`include "define.v"
module EX_MEM(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
      //控制本阶段id组合逻辑运算完的数据是否可以锁存起来，供给exe使用
    input wire line1_pre_to_now_valid_i,//if_id输出的表示，if阶段的数据可以输出到id阶段
    input wire line2_pre_to_now_valid_i,//if_id输出的表示，if阶段的数据可以输出到id阶段
   
    //id阶段的状态机
    input wire now_allowin_i,//id组合逻辑传入，表示id阶段当前数据已经运算完了
    output reg line1_now_valid_o,//输出下一个状态
    output reg line2_now_valid_o,//输出下一个状态
    
    input wire excep_flush_i,
    
    input  wire  [`MmToNextBusWidth]pre_to_ibus  ,
    output reg   [`MmToNextBusWidth]to_now_obus  ,  
    
     //数据缓存，可以不设计，因为目前不存在mem阶段ready了，但是wb阶段不允许输入的情况
   
    
    input  wire        cache_buffer_we_i,
    input  wire [32:0] cache_buffer_wdata_i,
    output wire [32:0] cache_buffer_rdata_o
      
        
);

/***************************************input variable define(输入变量定义)**************************************/

/***************************************output variable define(输出变量定义)**************************************/

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
reg [32:0] cache_buffer;
/****************************************input decode(输入解码)***************************************/


/****************************************output code(输出解码)***************************************/

/*******************************complete logical function (逻辑功能实现)*******************************/
always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        to_now_obus <= `ExToNextBusLen'd0;
    end else if((line1_pre_to_now_valid_i||line2_pre_to_now_valid_i) && now_allowin_i) begin
        to_now_obus <= pre_to_ibus;
    end else begin
        to_now_obus <= to_now_obus;
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
   
 
 //inst_ram缓存
  always@(posedge clk)begin
        if(rst_n == `RstEnable )begin
            cache_buffer <= 0;
        end else if (cache_buffer_we_i) begin
            cache_buffer <= cache_buffer_wdata_i;
        end else begin
            cache_buffer <= cache_buffer;
        end
  end
  assign cache_buffer_rdata_o = cache_buffer;
  
 
 
 

 
 
 
endmodule
