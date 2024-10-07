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
   
    //id阶段的状态机
    input wire now_allowin_i,//id组合逻辑传入，表示id阶段当前数据已经运算完了
    output reg line1_now_valid_o,//输出下一个状态
    output reg line2_now_valid_o,//输出下一个状态
    
    input wire excep_flush_i,
    
    input  wire  [`MmToNextBusWidth]pre_to_ibus  ,
    output reg   [`MmToNextBusWidth]to_now_obus  ,  
    
     //数据缓存，可以不设计，因为目前不存在mem阶段ready了，但是wb阶段不允许输入的情况
    //数据取消
    input  wire cache_rdata_ce_we_i,
    
    output wire [1:0]ce_cs_o,    
    output wire  cache_ce_o,
    
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
  //指令读出数据无效状态机
  parameter Reset = 2'b00;//不清里
  parameter Clear1 = 2'b01;//清理状态1
  parameter Clear2 = 2'b10;//清理状态2
  reg [1:0]ce_cs;//当前状态
  reg [1:0]ce_ns;//下一个状态
  
  always@(posedge clk)begin
        if(rst_n == `RstEnable )begin
            ce_cs <= Reset;
        end else begin 
            ce_cs <= ce_ns;
        end
  end
  //确定下一个状态
  always @ *begin
    case(ce_cs)
        Reset:begin
            if(cache_rdata_ce_we_i == 2'b10)begin//要清理一次，共要清理1次
                ce_ns = Clear1;
            end else if(cache_rdata_ce_we_i == 2'b11) begin
                ce_ns = Clear2;    
            end else if(cache_rdata_ce_we_i == 2'b01) begin
                ce_ns = Reset;
            end else begin
                ce_ns = Reset;
            end
        end
        Clear1:begin
            if(cache_rdata_ce_we_i == 2'b10)begin//再要清理一次，共要清理2次
                ce_ns = Clear2;
            end else if(cache_rdata_ce_we_i == 2'b01) begin//表示清理过一次回到原态
                ce_ns = Reset;    
            end else begin
                ce_ns = Clear1;
            end   
        end
        Clear2:begin
            if(cache_rdata_ce_we_i == 2'b10)begin
                 ce_ns = Clear2;
            end else if (cache_rdata_ce_we_i == 2'b01)  begin//当前清理完成，还只要再清理一次即可
                ce_ns = Clear1;
            end else begin
                ce_ns = Clear2;
            end   
        end
        default:ce_ns = Reset;
    endcase
end
  assign ce_cs_o = ce_cs;
  
   assign cache_ce_o = ce_cs== Reset  ? 1'b0 : 
                            ce_cs== Clear1 ? 1'b1:
                            ce_cs== Clear2 ? 1'b1: 1'b0;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
endmodule
