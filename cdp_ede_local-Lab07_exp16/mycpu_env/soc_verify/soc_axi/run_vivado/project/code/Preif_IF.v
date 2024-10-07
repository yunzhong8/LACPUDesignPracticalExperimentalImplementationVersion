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
module Preif_IF(
    input  wire  clk      ,
    input  wire  rst_n    ,
    //握手
    input wire preif_to_if_valid_i,
    input wire if_allowin_i,
    output reg if_valid_o,
    //冲刷信号
    input wire excep_flush_i,
    input wire banch_flush_i,
    
    //数据域
    input  wire [`PreifToIfBusWidth]    preif_to_ibus   ,
    //指令缓存
    input  wire inst_rdata_buffer_we_i,
    input  wire [`InstRdataBufferBusWidth]inst_rdata_buffer_i,
    //指令取消
    input  wire [1:0]inst_rdata_ce_we_i,//10表示写，01表示使用过啦
    
    output  reg [`InstRdataBufferBusWidth]inst_rdata_buffer_o,
    output  wire inst_rdata_ce_o,
    output wire  [`PreifToIfBusWidth]  to_if_obus
);

/***************************************input variable define(输入变量定义)**************************************/
wire  [`PcWidth] pc1_i;
wire  [`PcWidth] pc2_i;
/***************************************output variable define(输出变量定义)**************************************/
reg  [`PcWidth]  pc1_o;
reg  [`PcWidth]  pc2_o;
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/

/****************************************input decode(输入解码)***************************************/
assign {pc2_i,pc1_i} = preif_to_ibus;

/****************************************output code(输出解码)***************************************/
assign to_if_obus = {pc2_o,pc1_o};
/*******************************complete logical function (逻辑功能实现)*******************************/
 //pc1
    always@(posedge clk)begin
        if(rst_n==`RstEnable)begin
            pc1_o <= `PcLen'h1bff_fffc;
            pc2_o <= `PcLen'h1c00_0000;
        end else if(preif_to_if_valid_i&& if_allowin_i)begin           
            pc1_o <= pc1_i;
            pc2_o <= pc2_i;
        end else begin        
            pc1_o <= pc1_o;
            pc2_o <= pc2_o;
        end
        
    end
    //上下级握手
     always@(posedge clk)begin
        if(rst_n == `RstEnable || excep_flush_i||banch_flush_i)begin
            if_valid_o <= 1'b0;
        end else if(if_allowin_i)begin
            if_valid_o <= preif_to_if_valid_i;
        end else begin
             if_valid_o <= if_valid_o;
        end
    end
  //inst_ram缓存
  always@(posedge clk)begin
        if(rst_n == `RstEnable )begin
            inst_rdata_buffer_o <= `InstRdataBufferBusLen'd0;
        end else if (inst_rdata_buffer_we_i) begin
            inst_rdata_buffer_o <= inst_rdata_buffer_i;
        end else begin
            inst_rdata_buffer_o <= inst_rdata_buffer_o;
        end
  end
  
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
            if(inst_rdata_ce_we_i == 2'b10)begin
                ce_ns = Clear1;
            end else if(inst_rdata_ce_we_i == 2'b01) begin
                ce_ns = Reset;
            end else begin
                 ce_ns = Reset;
            end
        end
        Clear1:begin
            if(inst_rdata_ce_we_i == 2'b10)begin
                ce_ns = Clear2;
            end else if(inst_rdata_ce_we_i == 2'b01) begin
                ce_ns = Reset;
            end else begin
                ce_ns = Clear1;
            end   
        end
        Clear2:begin
            if(inst_rdata_ce_we_i == 2'b10)begin
                 ce_ns = Clear2;
            end else if (inst_rdata_ce_we_i == 2'b01)  begin
                ce_ns = Clear1;
            end else begin
                ce_ns = Clear2;
            end   
        end
        default:ce_ns = Reset;
    endcase
end
  
  
   assign inst_rdata_ce_o = ce_cs== Reset  ? 1'b0 : 
                            ce_cs== Clear1 ? 1'b1:
                            ce_cs== Clear2 ? 1'b1: 1'b0;
endmodule
