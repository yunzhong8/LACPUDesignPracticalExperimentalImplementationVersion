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
//`include "DefineModuleBus.h"
`include "define.v"
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
    output  wire now_valid_o,
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
wire now_cache_rdata_ce;
//读出数据缓存
//wire [1:0] ce_cs;
wire [1:0]wait_ce_ok_num;
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

  wire ce_cs_eq_zero;
  //wire ce_sub_one_en;

/***************************************inner variable define(错误状态)**************************************/

wire error1,error2,cdo_error;
wire [1:0]pipline_inst_num;
wire now_wait_data_ok;
//id级指令是否是要等待cache_data_o

//因为携带例外信息的指令是不会向cache发地址请求的
assign now_wait_data_ok= line1_now_valid&now_sent_mem_req&~cache_buffer_rdata_ok;

assign pipline_inst_num = now_wait_data_ok&now_clk_pre_cache_req_i ?2'd2:
                         now_wait_data_ok|now_clk_pre_cache_req_i?2'b1:2'b0;
//CPU中等待cache_data_ok的指令数目
//如果和cache处理的指令数相同，说明没有问题
wire [`CacheDisposeInstNumWidth]now_wait_data_ok_inst_num;
assign now_wait_data_ok_inst_num = wait_ce_ok_num + pipline_inst_num;

              //缓存data_ok,和data_ok_i不可能同时存在
assign error1 =cache_buffer_rdata_ok&cache_rdata_ok_i ;
      
assign error2 =now_wait_data_ok_inst_num!=cache_dispose_inst_num_i;

 assign  error_o = error1|error2|cdo_error;
/****************************************input decode(输入解码)***************************************/


/****************************************output code(输出解码)***************************************/
assign to_pre_obus =   {line1_to_pre_obus,line1_to_pre_obus}   ;
assign to_next_obus = {line2_to_next_obus,line1_to_next_obus} ;
assign forward_obus = {line2_forward_obus,line1_forward_obus} ;
/****************************************output code(内部解码)***************************************/
assign {line2_pre_bus,line1_pre_to_bus} = pre_to_bus;

/*******************************complete logical function (逻辑功能实现)*******************************/
assign {cache_buffer_rdata_ok,cache_buffer_rdata_data} = cache_buffer_rdata;
  
   Cdo Cdo_item(
           .clk                      ( clk    )                       ,
           .rst_n                    ( rst_n  )                       ,
                                                                      
           .flush_i                  ( excep_flush_i )                        ,
           .branch_flush_i           ( 0 )                            ,
           .now_clk_pre_cache_req_i  ( now_clk_pre_cache_req_i )   ,             
           .cache_rdata_ok_i         ( cache_rdata_ok_i )          ,      
           .cache_buffer_rdata_ok_i  ( cache_buffer_rdata_ok)           ,    
           .now_wait_data_ok_i       ( now_wait_data_ok)              , 
           
           .error_o                  (cdo_error),
           .wait_ce_ok_num_o         ( wait_ce_ok_num),                                                          
           .ce_cs_eq_zero_o          ( ce_cs_eq_zero)                 ,        
           .inst_rdata_ce_o          ( now_cache_rdata_ce)             
   
);
                                  
 assign cache_buffer_we     = ce_cs_eq_zero&(~excep_flush_i)&cache_buffer_rdata_ok&(~next_allowin_i) ? 1'b0:1'b1;
 assign cache_buffer_wdata  = ce_cs_eq_zero&(~excep_flush_i)&cache_rdata_ok_i&(~next_allowin_i)?{cache_rdata_ok_i,cache_rdata_i}:{1'b0,32'd0};
  
  
 
  
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
    
    assign now_valid_o  = line1_now_valid|line2_now_valid;
    assign now_allowin_o  = ~ce_cs_eq_zero&now_clk_pre_cache_req_i ?1'b0:line2_now_allowin && line1_now_allowin;
    assign line1_now_to_next_valid_o = now_allowin_o && line1_now_to_next_valid;
    assign line2_now_to_next_valid_o = now_allowin_o && line2_now_to_next_valid;
    
endmodule
