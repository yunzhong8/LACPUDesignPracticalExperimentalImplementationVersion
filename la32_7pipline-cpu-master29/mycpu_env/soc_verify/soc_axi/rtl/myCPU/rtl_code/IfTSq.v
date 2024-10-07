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
module IfTSq(
    input  wire                           clk                       ,
    input  wire                           rst_n                     ,
    //握手
    input wire                            line1_pre_to_now_valid_i  ,
   
    input wire                            now_allowin_i             ,
    
    output reg                            line1_now_valid_o         ,//输出下一个状态
    output reg                            line2_now_valid_o         ,
    //冲刷信号
    input wire                            excep_flush_i             ,
    input wire                            branch_flush_i             ,
    
    //数据域
    input  wire [`IfToNextSignleBusWidth] pre_to_signle_data_ibus   ,
    input  wire [`IfToNextBusWidth]       pre_to_ibus               ,
    //指令缓存
    input  wire                           inst_rdata_buffer_we_i    ,
    input  wire [64:0]                    inst_rdata_buffer_i       ,
    //指令取消
    input  wire [1:0]                     inst_rdata_ce_we_i        ,//10表示写，01表示使用过啦
    
    output wire [1:0]                     ce_cs_o,
    output reg  [64:0]                    inst_rdata_buffer_o       ,
    output wire                           inst_rdata_ce_o           ,
    output reg  [`IfToNextSignleBusWidth] to_now_signle_data_obus   ,
    output reg  [`IfToNextBusWidth]       to_now_obus
);

/***************************************input variable define(输入变量定义)**************************************/
wire  [`PcWidth] pc1_i;
wire  [`PcWidth] pc2_i;

wire line1_excpet_en_i ;                          
wire [`ExceptionTypeWidth]line1_excep_type_i;     
                                             
                                             
wire line2_excpet_en_i ;                          
wire [`ExceptionTypeWidth]line2_excep_type_i;     
                                           
wire inst_ram_req_i;                              

/***************************************output variable define(输出变量定义)**************************************/
reg  [`PcWidth]  pc1_o;
reg  [`PcWidth]  pc2_o;
reg line1_excpet_en_o ;
reg [`ExceptionTypeWidth]line1_excep_type_o;


reg line2_excpet_en_o ;
reg [`ExceptionTypeWidth]line2_excep_type_o;

reg inst_ram_req_o;


/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/

/****************************************input decode(输入解码)***************************************/


/****************************************output code(输出解码)***************************************/

/*******************************complete logical function (逻辑功能实现)*******************************/
 //数据信号
 //双数据
   always@(posedge clk)begin
        if(rst_n == `RstEnable)begin
            //to_now_obus <= `IfToNextBusLen'h0;
            to_now_obus <= 0;
        end else if(line1_pre_to_now_valid_i && now_allowin_i) begin//if id阶段完成计算即allowIn=1,并且if阶段打算流入数据即valid=1，则在时钟上升沿时候写入数据
            to_now_obus <= pre_to_ibus;
        end else begin//暂停流水
            to_now_obus <= to_now_obus;
        end
   end
  //单数据 
    always@(posedge clk)begin
    if(rst_n == `RstEnable)begin
        to_now_signle_data_obus <= `IfToNextSignleBusLen'b0;
    end else if(line1_pre_to_now_valid_i && now_allowin_i) begin//if id阶段完成计算即allowIn=1,并且if阶段打算流入数据即valid=1，则在时钟上升沿时候写入数据
        to_now_signle_data_obus <= pre_to_signle_data_ibus;
    end else begin//暂停流水
        to_now_signle_data_obus <= to_now_signle_data_obus;
        end
end
   
   
    
 //流水线1握手
 always@(posedge clk)begin
        if(rst_n == `RstEnable  ||excep_flush_i||branch_flush_i)begin
            line1_now_valid_o <= 1'b0;
        end else if(now_allowin_i)begin
            line1_now_valid_o <= line1_pre_to_now_valid_i;
        end else begin
            line1_now_valid_o <= line1_now_valid_o;
        end
 end

 
 
 
  //inst_ram缓存
  always@(posedge clk)begin
        if(rst_n == `RstEnable )begin
            inst_rdata_buffer_o <= 64'd0;
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
