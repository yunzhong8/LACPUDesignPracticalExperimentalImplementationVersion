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
//`include "DefineModuleBus.h"
`include "define.v"
`include "define.v"
module CdoSq
(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
     input  wire [1:0]inst_rdata_ce_we_i,//10表示写，01表示使用过啦
    //队列写使能
    output  wire [1:0]                     ce_cs_o,
    output  wire inst_rdata_ce_o
   
);

/***************************************input variable define(输入变量定义)**************************************/


/***************************************output variable define(输出变量定义)**************************************/
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/

/****************************************input decode(输入解码)***************************************/

        
/****************************************output code(输出解码)***************************************/
/*******************************complete logical function (逻辑功能实现)*******************************/

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
            if(inst_rdata_ce_we_i == 2'b10)begin//要清理一次，共要清理1次
                ce_ns = Clear1;
            end else if(inst_rdata_ce_we_i == 2'b11) begin
                ce_ns = Clear2;    
            end else if(inst_rdata_ce_we_i == 2'b01) begin
                ce_ns = Reset;
            end else begin
                ce_ns = Reset;
            end
        end
        Clear1:begin
            if(inst_rdata_ce_we_i == 2'b10)begin//再要清理一次，共要清理2次
                ce_ns = Clear2;
            end else if(inst_rdata_ce_we_i == 2'b01) begin//表示清理过一次回到原态
                ce_ns = Reset;    
            end else begin
                ce_ns = Clear1;
            end   
        end
        Clear2:begin
            if(inst_rdata_ce_we_i == 2'b10)begin
                 ce_ns = Clear2;
            end else if (inst_rdata_ce_we_i == 2'b01)  begin//当前清理完成，还只要再清理一次即可
                ce_ns = Clear1;
            end else begin
                ce_ns = Clear2;
            end   
        end
        default:ce_ns = Reset;
    endcase
end
  assign ce_cs_o = ce_cs;
  
   assign inst_rdata_ce_o = ce_cs== Reset  ? 1'b0 : 
                            ce_cs== Clear1 ? 1'b1:
                            ce_cs== Clear2 ? 1'b1: 1'b0;
endmodule
























