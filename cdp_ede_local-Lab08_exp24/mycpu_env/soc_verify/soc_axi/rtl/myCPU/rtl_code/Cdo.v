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
module Cdo
(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
    
    input  wire       flush_i,                                  
    input  wire       branch_flush_i,                           
    input  wire       now_clk_pre_cache_req_i,                  
    input  wire       cache_rdata_ok_i,                         
    input  wire       cache_buffer_rdata_ok_i,                  
    input  wire       now_wait_data_ok_i,                       
    
    output wire [1:0]      wait_ce_ok_num_o,
    output wire error_o,
    output  wire ce_cs_eq_zero_o,
    output wire  inst_rdata_ce_o
   
);

/***************************************input variable define(输入变量定义)**************************************/
  

/***************************************output variable define(输出变量定义)**************************************/
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
wire [1:0]next_inst_rdata_ce_we;
wire [1:0] ce_cs;//10表示写，01表示使用过啦             
/****************************************input decode(输入解码)***************************************/
    
        
        
/****************************************output code(输出解码)***************************************/
/*******************************complete logical function (逻辑功能实现)*******************************/

  

CdoSq  CdoSq_it(
   .clk                 ( clk   ) ,
   .rst_n               ( rst_n ) ,
                        
   .inst_rdata_ce_we_i  (next_inst_rdata_ce_we) ,//10表示写，01表示使用过啦
   
   .ce_cs_o             (ce_cs),                    
   .inst_rdata_ce_o     (inst_rdata_ce_o) 
   
);
assign wait_ce_ok_num_o=ce_cs;

CdoCb CdoCb_item(
    
     .ce_cs_i                   (ce_cs                   ),       
     .flush_i                   (flush_i                 ),
     .branch_flush_i            (branch_flush_i          ),
     .now_clk_pre_cache_req_i   (now_clk_pre_cache_req_i ),
     .cache_rdata_ok_i          (cache_rdata_ok_i        ),
     .cache_buffer_rdata_ok_i   (cache_buffer_rdata_ok_i ),
     .now_wait_data_ok_i        (now_wait_data_ok_i      ),
       
     .error_o                   (error_o),  
     .ce_cs_eq_zero_o            (ce_cs_eq_zero_o),                                                   
     .next_inst_rdata_ce_we_o   ( next_inst_rdata_ce_we)  
   
);
    

endmodule
























