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
module CdoCb
(
    
     input  wire [1:0]ce_cs_i,//10表示写，01表示使用过啦
     input  wire flush_i,
     input  wire branch_flush_i,
     input  wire now_clk_pre_cache_req_i,
     input  wire cache_rdata_ok_i,
     input  wire cache_buffer_rdata_ok_i,
     input  wire now_wait_data_ok_i,
    //队列写使能
    output  wire error_o,
    output  wire ce_cs_eq_zero_o,
    output  wire [1:0]next_inst_rdata_ce_we_o
   
);

/***************************************input variable define(输入变量定义)**************************************/


/***************************************output variable define(输出变量定义)**************************************/
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
wire ce_cs_eq_zero; 
wire ce_cs_eq_one;  
wire ce_cs_eq_two; 
wire error1,error2,error3,error4;
//有要清理的的data_ok，不可能存在存在data_ok
assign error1 = ~ce_cs_eq_zero&cache_buffer_rdata_ok_i ;
assign error2 =(ce_cs_eq_one| ce_cs_eq_two)&now_wait_data_ok_i ;
              //ce=2if不可能有有效
assign error3 = ce_cs_eq_two&now_clk_pre_cache_req_i;
//本机没有要等待要清理的data_ok,本级不需要等待data_ok，但收到了data_ok就是不合理的             
assign error4 =cache_rdata_ok_i&~now_wait_data_ok_i&ce_cs_eq_zero;

assign error_o =error1|error2|error3|error4;
/****************************************input decode(输入解码)***************************************/

        
/****************************************output code(输出解码)***************************************/
/*******************************complete logical function (逻辑功能实现)*******************************/
//指令取消
  //当if级的数据有效，且now_inst在preif级发过inst_ram_req请求，且当前阶段指令没有被读出的时候(buffer_ok=0,data_ok=0)，本时钟周期接受到了冲刷，要缓存一次清空信号，
  //当if级的清空信号被用过之后(当前时钟：ce=1,data_ok_i=1)，需要设在清空信号=0,
  //存在if级数据无效，但if级接受到data_ok，
  //data_ok ,buffer_ok
  //1，1(清理次数+2)
  //1,0（清理次数+1）
  //0,1(清理次数-1)
  //0,0(清理次数保持不变)
      assign ce_cs_eq_zero = ce_cs_i==2'b00;
      assign ce_cs_eq_one  = ce_cs_i==2'b01;
      assign ce_cs_eq_two  = ce_cs_i==2'b10;
      
      //有branch_flush表示当前阶段的指令收到cache返回的data，所以只要冲刷if阶段的data_ok
      assign next_inst_rdata_ce_we_o =  ( (
                                            ce_cs_eq_zero & (
                                                                flush_i& (
                                                                            now_wait_data_ok_i&( 
                                                                                                now_clk_pre_cache_req_i  &cache_rdata_ok_i 
                                                                                                |~now_clk_pre_cache_req_i&~cache_rdata_ok_i
                                                                                             ) 
                                                                            |(~now_wait_data_ok_i)&now_clk_pre_cache_req_i 
                                                                       )            
                                                            )
                                        )
                                        |(ce_cs_eq_one&flush_i&(now_wait_data_ok_i|now_clk_pre_cache_req_i)&~cache_rdata_ok_i) 
                                      ) ? 2'b10:
                                    
                                      (ce_cs_eq_zero& flush_i&(now_wait_data_ok_i&now_clk_pre_cache_req_i)&(~cache_buffer_rdata_ok_i&~cache_rdata_ok_i)//当前阶段没有要冲刷的，收到例外冲刷，没有收到data_ok,且if,id都有效，则+2
                                      ) ? 2'b11:
                                      
                                      ( (ce_cs_eq_one &( (flush_i&(~now_wait_data_ok_i&~now_clk_pre_cache_req_i)&cache_rdata_ok_i)//有一条要冲刷，收到冲刷信号，只有if,id都为空指令，收到data_ok就-1
                                                         |((~flush_i)&cache_rdata_ok_i) //有一条要冲刷，只有没有接受到冲刷信号（当前阶段必定为空，所以不可能有branch_flush）,收到data_ok_i就-1
                                                       )
                                        )   
                                        |(ce_cs_eq_two&cache_rdata_ok_i)//有两条要冲刷则if,id必定为空，所以接收到data_ok_i就-1
                                      ) ?2'b01:2'b00;
                                      
                                      

assign ce_cs_eq_zero_o=ce_cs_eq_zero;
endmodule
























