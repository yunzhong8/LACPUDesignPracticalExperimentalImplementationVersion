/*
*作者：zzq
*创建时间：2023-04-22
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
module MemStage(
    //时钟
    input  wire  clk      ,
    input  wire  rst_n    ,
    //握手
    input  wire next_allowin_i  ,
    input  wire line1_pre_to_now_valid_i    ,
    input  wire line2_pre_to_now_valid_i    ,
    
    output  wire line1_now_to_next_valid_o    ,
    output  wire line2_now_to_next_valid_o    ,
    output  wire now_allowin_o  ,
    //冲刷
    input wire excep_flush_i,
     //错误`
        output wire                         error_o,   
    
    //数据域
    input  wire cache_rdata_ok_i,
    input  wire [`MmToNextBusWidth]pre_to_ibus         ,
    input  wire now_clk_pre_cache_req_i,
    input wire [`CacheDisposeInstNumWidth]cache_dispose_inst_num_i,
    input  wire [`MemDataWidth]cache_rdata_i,
    
    output wire [19:0]inst_cacop_op_addr_tag_o    ,  
    output wire [19:0]data_cacop_op_addr_tag_o    ,  
    output wire                       store_buffer_ce_o             ,
    output wire [`MemForwardBusWidth]forward_obus,
    output wire [`MemToPreBusWidth]to_pre_obus     ,
    output wire [`MemToCacheBusWidth]          to_cache_obus ,
    output wire [`MemToNextBusWidth]to_next_obus        
);

/***************************************input variable define(输入变量定义)**************************************/

/***************************************output variable define(输出变量定义)**************************************/
wire [`LineMemForwardBusWidth]line2_forward_obus,line1_forward_obus;
wire line2_to_pre_obus,line1_to_pre_obus;
wire [`LineMemToNextBusWidth]line2_to_next_obus,line1_to_next_obus;
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//ExMEM
wire line2_now_valid,line1_now_valid;

wire  [`MmToNextBusWidth] pre_to_bus ;
//MEM
wire [`LineMmToNextBusWidth]line2_pre_to_bus,line1_pre_to_bus;
wire line2_now_to_next_valid,line1_now_to_next_valid;
wire  line2_now_allowin,line1_now_allowin;
//data_ram读出取消
wire  [1:0]next_cache_rdata_ce_we;
wire now_cache_rdata_ce;
//读出数据缓存
wire [1:0] ce_cs;
wire         cache_buffer_we;
wire  [32:0]cache_buffer_wdata;
wire [32:0]cache_buffer_rdata;
wire       cache_buffer_rdata_ok;              
wire [`MemDataWidth]cache_buffer_rdata_data; 
wire [`MemDataWidth]cache_rdata;

//本机指令是否发过cache请求
wire now_sent_mem_req;

//读ok
wire cache_rdata_ok;

  wire branch_flush_o = 1'b0;
  wire ce_cs_eq_zero;
  wire ce_cs_eq_one;
  wire ce_cs_eq_two;
  //wire ce_sub_one_en;

/***************************************inner variable define(错误状态)**************************************/

wire error1,error2,error3,error4,error5,error6,error7,error8;

//id级指令是否是要等待cache_data_o
wire now_wait_data_ok;
//因为携带例外信息的指令是不会向cache发地址请求的
assign now_wait_data_ok= line1_now_valid&now_sent_mem_req&~cache_buffer_rdata_ok;
wire [1:0]pipline_inst_num;
assign pipline_inst_num = now_wait_data_ok&now_clk_pre_cache_req_i ?2'd2:
                         now_wait_data_ok|now_clk_pre_cache_req_i?2'b1:2'b0;
//CPU中等待cache_data_ok的指令数目
//如果和cache处理的指令数相同，说明没有问题
wire [`CacheDisposeInstNumWidth]now_wait_data_ok_inst_num;
assign now_wait_data_ok_inst_num = ce_cs + pipline_inst_num;

               //有要清理的的data_ok，不可能存在存c在data_ok
assign error1 = ~ce_cs_eq_zero&cache_buffer_rdata_ok ;
              //缓存data_ok,和data_ok_i不可能同时存在
assign error2 =cache_buffer_rdata_ok&cache_rdata_ok_i ;
              //ce=1的时候本级不可能有效
assign error3 =(ce_cs_eq_one| ce_cs_eq_two)&now_wait_data_ok ;
              //ce=2if不可能有有效
assign error4 = ce_cs_eq_two&now_clk_pre_cache_req_i;

assign error5 =cache_rdata_ok_i&~now_wait_data_ok&ce_cs_eq_zero;

assign error6 =now_wait_data_ok_inst_num!=cache_dispose_inst_num_i;

 assign  error_o = error1|error2|error3|error4|error5|error6;
/****************************************input decode(输入解码)***************************************/


/****************************************output code(输出解码)***************************************/
assign to_pre_obus =   {line1_to_pre_obus,line1_to_pre_obus}   ;
assign to_next_obus = {line2_to_next_obus,line1_to_next_obus} ;
assign forward_obus = {line2_forward_obus,line1_forward_obus} ;
/****************************************output code(内部解码)***************************************/
assign {line2_pre_bus,line1_pre_to_bus} = pre_to_bus;

/*******************************complete logical function (逻辑功能实现)*******************************/
assign {cache_buffer_rdata_ok,cache_buffer_rdata_data} = cache_buffer_rdata;

 
  
  
  //指令取消
  //当if级的数据有效，且now_inst在preif级发过inst_ram_req请求，且当前阶段指令没有被读出的时候(buffer_ok=0,data_ok=0)，本时钟周期接受到了冲刷，要缓存一次清空信号，
  //当if级的清空信号被用过之后(当前时钟：ce=1,data_ok_i=1)，需要设在清空信号=0,
  //存在if级数据无效，但if级接受到data_ok，
  //data_ok ,buffer_ok
  //1，1(清理次数+2)
  //1,0（清理次数+1）
  //0,1(清理次数-1)
  //0,0(清理次数保持不变)

  
  assign ce_cs_eq_zero = ce_cs==2'b00;
  assign ce_cs_eq_one  = ce_cs==2'b01;
  assign ce_cs_eq_two  = ce_cs==2'b10;
//  assign ce_sub_one_en = (ce_cs_eq_one &( ((excep_flush_i&(~line1_now_valid&~now_clk_pre_cache_req_i))|(~excep_flush_i))//有一条要冲刷，收到冲刷信号，只有if,id都为空指令，收到data_ok就-1
//                                                     &cache_rdata_ok_i //有一条要冲刷，只有没有接受到冲刷信号（当前阶段必定为空，所以不可能有branch_flush）,收到data_ok_i就-1
//                                        )
//                                    )   ;
  //有branch_flush表示当前阶段的指令收到cache返回的data，所以只要冲刷if阶段的data_ok
  assign next_cache_rdata_ce_we =  ( (ce_cs_eq_zero & (excep_flush_i& (now_sent_mem_req&( now_clk_pre_cache_req_i&(cache_buffer_rdata_ok|cache_rdata_ok_i) 
                                                                                        | ~now_clk_pre_cache_req_i&(~cache_buffer_rdata_ok&~cache_rdata_ok_i) 
                                                                                       ) 
                                                                     |(~now_sent_mem_req)&now_clk_pre_cache_req_i&(~cache_buffer_rdata_ok&~cache_rdata_ok_i) 
                                                                     ) 
                                                      |(~excep_flush_i)&branch_flush_o&now_clk_pre_cache_req_i               
                                                      )
                                    )
                                    |(ce_cs_eq_one&excep_flush_i&(now_sent_mem_req|now_clk_pre_cache_req_i)&~cache_rdata_ok_i) 
                                  ) ? 2'b10:
                                
                                  (ce_cs_eq_zero& excep_flush_i&(now_sent_mem_req&now_clk_pre_cache_req_i)&(~cache_buffer_rdata_ok&~cache_rdata_ok_i)//当前阶段没有要冲刷的，收到例外冲刷，没有收到data_ok,且if,id都有效，则+2
                                  ) ? 2'b11:
                                  
                                  ( (ce_cs_eq_one &( (excep_flush_i&(~now_sent_mem_req&~now_clk_pre_cache_req_i)&cache_rdata_ok_i)//有一条要冲刷，收到冲刷信号，只有if,id都为空指令，收到data_ok就-1
                                                     |((~excep_flush_i)&cache_rdata_ok_i) //有一条要冲刷，只有没有接受到冲刷信号（当前阶段必定为空，所以不可能有branch_flush）,收到data_ok_i就-1
                                                   )
                                    )   
                                    |(ce_cs_eq_two&cache_rdata_ok_i)//有两条要冲刷则if,id必定为空，所以接收到data_ok_i就-1
                                  ) ?2'b01:2'b00;
                                  
                                  
 assign cache_buffer_we     = ce_cs_eq_zero&(~excep_flush_i)&(~branch_flush_o)&cache_buffer_rdata_ok&(~next_allowin_i) ? 1'b0:1'b1;
 assign cache_buffer_wdata  = ce_cs_eq_zero&(~excep_flush_i)&(~branch_flush_o)&cache_rdata_ok_i&(~next_allowin_i)?{cache_rdata_ok_i,cache_rdata_i}:{1'b0,32'd0};
  
  
  
  
  
  
  
  
  
 
  
  
 EX_MEM EXMEMI(
        .rst_n                    ( rst_n                     ),
        .clk                      ( clk                       ),
        //握手
        .line1_pre_to_now_valid_i ( line1_pre_to_now_valid_i  ),
        .line2_pre_to_now_valid_i ( line2_pre_to_now_valid_i  ),
        .now_allowin_i            ( now_allowin_o             ),
        
        .line1_now_valid_o        ( line1_now_valid           ),
        .line2_now_valid_o        ( line2_now_valid           ),
        
        .excep_flush_i            ( excep_flush_i             ),
        //数据域
        .pre_to_ibus              ( pre_to_ibus               ),
           
        .to_now_obus              ( pre_to_bus                ),
        
        //其他模块的数据域
        .cache_rdata_ce_we_i      ( next_cache_rdata_ce_we ),
        .ce_cs_o                  ( ce_cs                     ),
        .cache_ce_o               ( now_cache_rdata_ce     ),
        //缓存cache读出数据
        .cache_buffer_we_i        ( cache_buffer_we           ),
        .cache_buffer_wdata_i     ( cache_buffer_wdata        ),
        .cache_buffer_rdata_o     ( cache_buffer_rdata        )  
        
    );
    assign{line2_pre_to_bus,line1_pre_to_bus} =pre_to_bus;
    
//访问外部数据存储器
    MEM MEMI1(
         //握手
        .next_allowin_i        ( next_allowin_i          ) ,
        .now_valid_i           ( line1_now_valid         ) ,
        
        .now_allowin_o         ( line1_now_allowin       ) ,
        .now_to_next_valid_o    ( line1_now_to_next_valid ) ,
        //冲刷
        .excep_flush_i         ( excep_flush_i           ) ,
       
        //数据
        .data_sram_data_ok_i   ( cache_rdata_ok          ) ,
        .pre_to_ibus           ( line1_pre_to_bus        ) ,
        .mem_rdata_i           ( cache_rdata             ) ,
        
        .now_sent_mem_req_o     (now_sent_mem_req),
        .inst_cacop_op_addr_tag_o(inst_cacop_op_addr_tag_o),
        .data_cacop_op_addr_tag_o(data_cacop_op_addr_tag_o),
        .store_buffer_ce_o       (store_buffer_ce_o      ),
        .forward_obus          ( line1_forward_obus      ) ,
        .to_cache_obus         ( to_cache_obus           ) ,
        .to_pre_obus           ( line1_to_pre_obus       ) ,
     
        .to_next_obus          ( line1_to_next_obus      )
    );
//访问外部数据存储器
    MEM MEMI2(
         //握手                                               
        .next_allowin_i       ( next_allowin_i         ),                                
        .now_valid_i          ( line2_now_valid        ),                      
                                                                   
        .now_allowin_o        ( line2_now_allowin      ),                  
        .now_to_next_valid_o  ( line2_now_to_next_valid),   
        //冲刷   
        .excep_flush_i        ( excep_flush_i          ),                      
                                                             
        //数据域              
        .data_sram_data_ok_i  ( cache_rdata_ok         ),                                 
        .pre_to_ibus          ( line2_pre_to_bus       ),               
        .mem_rdata_i          ( cache_rdata            ),         
                 
                                                              
        .forward_obus         ( line2_forward_obus     ),                  
        .to_pre_obus          ( line2_to_pre_obus      ),                      
        .to_next_obus         ( line2_to_next_obus     )                  
                         
                         
    );
    //
    assign cache_rdata_ok = (!now_cache_rdata_ce) && cache_rdata_ok_i|cache_buffer_rdata_ok;
    assign cache_rdata    = cache_buffer_rdata_ok ? cache_buffer_rdata_data : cache_rdata_i;
    
    assign now_allowin_o  = ~ce_cs_eq_zero&now_clk_pre_cache_req_i ?1'b0:line2_now_allowin && line1_now_allowin;
    assign line1_now_to_next_valid_o = now_allowin_o && line1_now_to_next_valid;
    assign line2_now_to_next_valid_o = now_allowin_o && line2_now_to_next_valid;
    
endmodule
