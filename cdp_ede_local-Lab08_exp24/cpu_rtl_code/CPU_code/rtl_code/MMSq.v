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
module MMSq(
    input  wire                        clk                       ,
    input  wire                        rst_n                     ,
    //握手
    input wire                         line1_pre_to_now_valid_i  ,
    input wire                         line2_pre_to_now_valid_i  ,
    input wire                         now_allowin_i             ,
    
    output reg                         line1_now_valid_o         ,//输出下一个状态
    output reg                         line2_now_valid_o         ,
    //冲刷信号
    input wire                         excep_flush_i             ,
    input wire                         banch_flush_i             ,
    
    //数据域
    input  wire [`ExToNextBusWidth]   pre_to_ibus               ,
    
    output reg   [`ExToNextBusWidth]  to_now_obus
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
   always@(posedge clk)begin
    if(rst_n == `RstEnable)begin
        to_now_obus <= 0;
    end else if((line1_pre_to_now_valid_i || line2_pre_to_now_valid_i)&& now_allowin_i) begin//if id阶段完成计算即allowIn=1,并且if阶段打算流入数据即valid=1，则在时钟上升沿时候写入数据
        to_now_obus <= pre_to_ibus;
    end else begin//暂停流水
        to_now_obus <= to_now_obus;
        end
end
    
 //流水线1握手
 always@(posedge clk)begin
        if(rst_n == `RstEnable  ||excep_flush_i)begin
            line1_now_valid_o <= 1'b0;
        end else if(now_allowin_i)begin
            line1_now_valid_o <= line1_pre_to_now_valid_i;
        end else begin
            line1_now_valid_o <= line1_now_valid_o;
        end
 end
//流水线2握手
 always@(posedge clk)begin
        if(rst_n == `RstEnable  ||excep_flush_i)begin
            line2_now_valid_o <= 1'b0;
        end else if(now_allowin_i)begin
            line2_now_valid_o <= line2_pre_to_now_valid_i;
        end else begin
            line2_now_valid_o <= line2_now_valid_o;
        end
  end
 

endmodule
