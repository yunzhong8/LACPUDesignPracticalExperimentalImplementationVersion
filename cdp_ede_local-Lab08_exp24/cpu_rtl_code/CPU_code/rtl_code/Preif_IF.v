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
//`include "DefineModuleBus.h"
`include "define.v"
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
    input  wire [`PreifToNextBusWidth]    preif_to_ibus   ,
  
    //指令取消
    input  wire [1:0]inst_rdata_ce_we_i,//10表示写，01表示使用过啦
    //预测结果缓存
    input wire pr_we_i,
    input wire [`PrToIfDataBusWidth]pr_data_i,
    output reg [`PrToIfDataBusWidth]pr_data_o,
    
    output  reg [64:0]inst_rdata_buffer_o,
    output  wire inst_rdata_ce_o,
    output wire  [`PreifToNextBusWidth]  to_if_obus
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
assign {inst_ram_req_i,line2_excpet_en_i,line2_excep_type_i,pc2_i,line1_excpet_en_i,line1_excep_type_i,pc1_i} = preif_to_ibus;

/****************************************output code(输出解码)***************************************/
assign to_if_obus = {inst_ram_req_o,line2_excpet_en_o,line2_excep_type_o,pc2_o,line1_excpet_en_o,line1_excep_type_o,pc1_o};
/*******************************complete logical function (逻辑功能实现)*******************************/
 //pc1
    always@(posedge clk)begin
        if(rst_n==`RstEnable)begin
            if(`PerTestEn)begin
                 pc1_o <= `PerfTestLineOneIntitialAddr;
                 pc2_o <= `PerfTestLineTwoIntitialAddr;
            end else begin
                 pc1_o <= `FuncTestLineOneIntitialAddr;
                 pc2_o <= `FuncTestLineTwoIntitialAddr;
                
            end
           
            inst_ram_req_o       <= 1'b0        ;     
            line1_excpet_en_o    <= 1'b0    ;
            line1_excep_type_o   <= `ExceptionTypeLen'd0    ;
            line2_excpet_en_o    <= 1'b0    ;
            line2_excep_type_o   <= `ExceptionTypeLen'd0   ;
            
        end else if(preif_to_if_valid_i&& if_allowin_i)begin           
            pc1_o <= pc1_i;
            pc2_o <= pc2_i;
            inst_ram_req_o       <= inst_ram_req_i        ;
            line1_excpet_en_o    <= line1_excpet_en_i     ;
            line1_excep_type_o   <= line1_excep_type_i    ;
            line2_excpet_en_o    <= line2_excpet_en_i     ;
            line2_excep_type_o   <= line2_excep_type_i    ;
            
            
            
        end else begin        
            pc1_o <= pc1_o;
            pc2_o <= pc2_o;
            inst_ram_req_o       <= inst_ram_req_o        ;
            line1_excpet_en_o    <= line1_excpet_en_o     ;
            line1_excep_type_o   <= line1_excep_type_o    ;
            line2_excpet_en_o    <= line2_excpet_en_o     ;
            line2_excep_type_o   <= line2_excep_type_o    ;
            
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
  
 
 always @(posedge clk)begin
    if(rst_n == `RstEnable )begin
        pr_data_o <= `PrToIfDataBusLen'd0 ;
    end else if(pr_we_i)begin
        pr_data_o <= pr_data_i;
    end else begin
       pr_data_o <= pr_data_o;
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
            end else if(inst_rdata_ce_we_i == 2'b01) begin
                ce_ns = Reset;
            end else begin
                ce_ns = Reset;
            end
        end
        Clear1:begin
            if(inst_rdata_ce_we_i == 2'b10)begin//再要清理一次，共要清理2次
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
            end else if (inst_rdata_ce_we_i == 2'b01)  begin//当前清理完成，还只要再清理一次即可
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
