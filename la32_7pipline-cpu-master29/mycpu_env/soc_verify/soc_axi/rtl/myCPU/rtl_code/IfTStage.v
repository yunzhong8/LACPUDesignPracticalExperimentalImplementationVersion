
/*
*作者：zzq
*创建时间：2023-04-22
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*实现mmu的翻译和获取到cache访问的指令
*/
/*************\
bug:
\*************/
`include "DefineModuleBus.h"
module IfTStage(
    input  wire                       clk                           ,
    input  wire                       rst_n                         ,
    //握手                                                                      
    input  wire                       next_allowin_i                ,                        
    input  wire                       line1_pre_to_now_valid_i      ,    
    //input  wire                       line2_pre_to_now_valid_i      ,
                                                                              
    output  wire                      line1_now_to_next_valid_o     ,          
    output  wire                      line2_now_to_next_valid_o     ,          
    output  wire                      now_allowin_o                 ,                        
    //冲刷                                                 
    input wire                        excep_flush_i                 , 
    
    output wire                       uncache_pre_error_flush_o     ,
    //错误`
        output wire                         error_o,   
                                                            
    //数据域                     
    input  wire                       inst_sram_data_ok_i           ,     
    input  wire [63:0]                inst_sram_rdata_i             ,  
    input  wire [`CacheDisposeInstNumWidth] cache_dispose_inst_num_i,
                          
    input  wire [`IfToNextBusWidth]       pre_to_ibus                   ,
    input  wire [`IfToNextSignleBusWidth] pre_to_next_signle_ibus       ,
    input  wire                           now_clk_pre_inst_ram_req_i    ,//当前时钟，上一流水级是否对inst_cach发过请求 
    
    
    output wire  [`PucWbusWidth]        to_puc_obus,                  
    output wire [`PcBranchBusWidth]   to_preif_obus,                 
    output wire [`IfToICacheBusWidth] to_icache_obus                ,   
    output wire [`IftToNextBusWidth]   to_next_obus           
);

/***************************************input variable define(输入变量定义)**************************************/

wire [19:0]p_tag_i;
wire uncache_i;
wire inst_ram_req_i;
wire cache_refill_valid_i;

/***************************************output variable define(输出变量定义)**************************************/
wire [`PcWidth]branch_flush_pc_o;
wire branch_flush_o;

wire                        puc_we_o   ;
wire [`PucAddrWidth]        puc_waddr_o;
wire                        puc_wdata_o;

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//握手
    wire              now_allowin;
    wire              line2_now_to_next_valid,line1_now_to_next_valid;
    wire              line2_now_allowin,line1_now_allowin;
    wire              line2_now_valid,line1_now_valid;
//数据
    wire [`IfToNextBusWidth]  now_line1_data_bus;    
    
    wire [`DoubleInstWidth]       line2_now_inst,line1_now_inst;
    wire [`LineIdToPreBusWidth]   line2_now_to_pre_obus,line1_now_to_pre_obus;
    wire [`IfToNextBusWidth]      now_data_bus;
    wire                          now_uncache;//当前阶段指令是uncache指令
    wire [`PcBranchBusWidth]      line1_now_to_preif_obus;
    wire [`IfToNextSignleBusWidth]to_now_signle_data_bus;
//跳转信号
    wire              line2_branch_flush,line1_branch_flush;
    wire [`PcWidth]   line2_branch_pc,line1_branch_pc;
// 其他级输入信号
    wire [64:0] inst_buffer_rdata;    
//
wire  inst_buffer_we;
wire  [64:0]inst_buffer_wdata;
wire [64:0]inst_buffer_rdata;

//指令取消
wire [1:0]ce_cs;
wire  [1:0]next_inst_rdata_ce_we;
wire now_inst_rdata_ce;
//if
wire inst_sram_data_ok;
//指令缓存                                    
wire inst_buffer_data_ok;              
wire [63:0]inst_buffer_rinst; 
//当前指令向inst_ram发过请求
wire inst_ram_req;

 wire ce_cs_eq_zero;
 wire ce_cs_eq_one;
 wire ce_cs_eq_two;
 

//pcu更新
wire puc_we;




/****************************************input decode(逻辑错误定义)***************************************/
wire error1,error2,error3,error4,error5,error6,error7,error8;
//if2级指令是否是要等待cache_data_o
wire   now_wait_data_ok;
assign now_wait_data_ok= line1_now_valid&inst_ram_req_i&~inst_buffer_data_ok;

//目前流水中有几条指令要等待data_ok
wire [1:0] pipline_inst_num;
assign pipline_inst_num = now_wait_data_ok&now_clk_pre_inst_ram_req_i ?2'd2:
                         now_wait_data_ok|now_clk_pre_inst_ram_req_i?2'b1:2'b0;
//CPU中等待cache_data_ok的指令数目
//如果和cache处理的指令数相同，说明没有问题
wire [`CacheDisposeInstNumWidth]now_wait_data_ok_inst_num;
assign now_wait_data_ok_inst_num = ce_cs + pipline_inst_num;

               //有要清理的的data_ok，不可能存在存在data_ok
assign error1 = ~ce_cs_eq_zero&inst_buffer_data_ok ;
              //缓存data_ok,和data_ok_i不可能同时存在
assign error2 = inst_buffer_data_ok&inst_sram_data_ok_i;
              //ce=1的时候本级不可能存在指令等待data_ok(可以存在效指令该指令是携带例外信息的）
assign error3 =(ce_cs_eq_one| ce_cs_eq_two)&now_wait_data_ok ;
              //ce=2if不可能有有效
assign error4 = ce_cs_eq_two&now_clk_pre_inst_ram_req_i;

              //本机没有要等待要清理的data_ok,本级不需要等待data_ok，但收到了data_ok就是不合理的             
assign error5 =inst_sram_data_ok_i&~now_wait_data_ok&ce_cs_eq_zero;
              //CPU等待data_ok数目不等于cache正在处理指令数就错
assign error6 =now_wait_data_ok_inst_num!=cache_dispose_inst_num_i;

 assign  error_o = error1|error2|error3|error4|error5|error6;
/****************************************input decode(输入解码)***************************************/
/****************************************output code(输出解码)***************************************/
assign now_allowin_o  = now_allowin;
assign to_preif_obus   = {branch_flush_o,branch_flush_pc_o}; 
assign to_icache_obus = {cache_refill_valid_i,uncache_i,p_tag_i};
assign uncache_pre_error_flush_o=branch_flush_o;
assign to_puc_obus = {puc_we_o,puc_waddr_o,puc_wdata_o}; 
/*******************************complete logical function (逻辑功能实现)*******************************/
 //
 assign  now_uncache = uncache_i;
 assign flush = excep_flush_i|branch_flush_o;
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
  
  //有branch_flush表示当前阶段的指令收到cache返回的data，所以只要冲刷if阶段的data_ok
  assign next_inst_rdata_ce_we =  ( (ce_cs_eq_zero & (flush& (now_wait_data_ok&( now_clk_pre_inst_ram_req_i&(inst_buffer_data_ok|inst_sram_data_ok_i) 
                                                                                        | ~now_clk_pre_inst_ram_req_i&(~inst_buffer_data_ok&~inst_sram_data_ok_i) 
                                                                                       ) 
                                                                     |(~now_wait_data_ok)&now_clk_pre_inst_ram_req_i&(~inst_buffer_data_ok&~inst_sram_data_ok_i) 
                                                                     )            
                                                      )
                                    )
                                    |(ce_cs_eq_one&flush&(now_wait_data_ok|now_clk_pre_inst_ram_req_i)&~inst_sram_data_ok_i) 
                                  ) ? 2'b10:
                                
                                  (ce_cs_eq_zero& flush&(now_wait_data_ok&now_clk_pre_inst_ram_req_i)&(~inst_buffer_data_ok&~inst_sram_data_ok_i)//当前阶段没有要冲刷的，收到例外冲刷，没有收到data_ok,且if,id都有效，则+2
                                  ) ? 2'b11:
                                  
                                  ( (ce_cs_eq_one &( (flush&(~now_wait_data_ok&~now_clk_pre_inst_ram_req_i)&inst_sram_data_ok_i)//有一条要冲刷，收到冲刷信号，只有if,id都为空指令，收到data_ok就-1
                                                     |((~flush)&inst_sram_data_ok_i) //有一条要冲刷，只有没有接受到冲刷信号（当前阶段必定为空，所以不可能有branch_flush）,收到data_ok_i就-1
                                                   )
                                    )   
                                    |(ce_cs_eq_two&inst_sram_data_ok_i)//有两条要冲刷则if,id必定为空，所以接收到data_ok_i就-1
                                  ) ?2'b01:2'b00;
                                  
                                  
 assign inst_buffer_we     = ce_cs_eq_zero&(~flush)&inst_buffer_data_ok&(~next_allowin_i) ? 1'b0:1'b1;
 assign inst_buffer_wdata  = ce_cs_eq_zero&(~flush)&inst_sram_data_ok_i&(~next_allowin_i)?{inst_sram_data_ok_i,inst_sram_rdata_i}:{1'b0,64'd0};
  
        
//88 84 80(id)
// 
 //PC缓存
    IfTSq IfTSq_item(
           //时钟信号
           .clk                         ( clk                      ),          
           .rst_n                       ( rst_n                    ),
           //握手信号                                                        
           .line1_pre_to_now_valid_i    ( line1_pre_to_now_valid_i ),
           //.line2_pre_to_now_valid_i    ( line2_pre_to_now_valid_i ),
           .now_allowin_i               ( now_allowin              ),
                                                                   
           .line1_now_valid_o           ( line1_now_valid          ),
           .line2_now_valid_o           ( line2_now_valid          ),
            //冲刷信号                                                         
           .excep_flush_i               ( excep_flush_i            ),
           .branch_flush_i               ( branch_flush_o            ),
           
           //上下级数据域
           .pre_to_signle_data_ibus     ( pre_to_next_signle_ibus  ),                                                        
           .pre_to_ibus                 ( pre_to_ibus              ),
                                                                   
           .to_now_signle_data_obus     ( to_now_signle_data_bus   ),
           .to_now_obus                 ( now_data_bus             ),
           //其他级数据域
                //cache读出数据缓存
           .inst_rdata_buffer_we_i      ( inst_buffer_we           ),
           .inst_rdata_buffer_i         ( inst_buffer_wdata        ),
         
           .inst_rdata_buffer_o         ( inst_buffer_rdata        ),
                //cache_data_ok取消缓存                                                        
           .inst_rdata_ce_we_i          ( next_inst_rdata_ce_we    ),
           .ce_cs_o                     ( ce_cs                    ), 
           .inst_rdata_ce_o             ( now_inst_rdata_ce        )
        
        );
        
     assign {inst_ram_req_i,cache_refill_valid_i,uncache_i,p_tag_i} = to_now_signle_data_bus;
     //访问指令rom
     assign inst_buffer_rinst    = inst_buffer_rdata[63:0];
     assign inst_buffer_data_ok  = inst_buffer_rdata[64];

   IfTCb IfTCb_item1(
         .rst_n                ( rst_n                     ),              
                               
         .next_allowin_i       ( next_allowin_i            ),
         .now_valid_i          ( line1_now_valid           ),
                               
         .now_allowin_o        ( line1_now_allowin         ),
         .now_to_next_valid_o  ( line1_now_to_next_valid   ),
         .line2_now_to_next_valid_o (line2_now_to_next_valid),
                              
         .excep_flush_i        ( excep_flush_i             ),
                               
         .pre_to_ibus          ( now_data_bus        ),
         .inst_data_i          ( line1_now_inst            ),
         .inst_sram_data_ok_i  ( inst_sram_data_ok         ),
                              
         .puc_we_o               (puc_we),
         .puc_waddr_o            (puc_waddr_o),
         .puc_wdata_o            (puc_wdata_o),
                         
         .to_next_obus         ( to_next_obus              ),
         .to_preif_obus        ( line1_now_to_preif_obus   ),
         .to_pre_obus          ( line1_now_to_pre_obus     )
   
   );
    assign {line1_branch_flush,line1_branch_pc} =line1_now_to_preif_obus;             
    assign {line2_branch_flush,line2_branch_pc} = 0;
      //if当前指令没有流往下一级则，不允许将跳转冲刷信号发出去，防止，同一个指令的跳转信号持续多个时钟周期
      //如果line1跳转冲刷有效，则本级发出冲刷信号，
      //if line2是跳转冲刷有效且第二跳转指令有效，则本级发出跳转冲刷信号，因为第二条指令是会取出inst有值，但是valid=0的情况，
       assign {branch_flush_o,branch_flush_pc_o} = ~now_allowin ? {1'b0,32'd0} :
                                line1_branch_flush ? {1'b1,line1_branch_pc} :
                                line2_branch_flush ? {1'b1,line2_branch_pc} : {1'b0,32'd0}; 
       assign puc_we_o = now_allowin&puc_we;
       
        //该data_ok有效，则表示当前有效指令的数据到达了，
        assign inst_sram_data_ok = ((~now_inst_rdata_ce) & inst_sram_data_ok_i) | inst_buffer_data_ok ;
        
        assign line1_now_inst = inst_buffer_data_ok ? inst_buffer_rinst : inst_sram_rdata_i ;
        
         
        
        
        //握手
            assign now_allowin               = ~ce_cs_eq_zero&now_clk_pre_inst_ram_req_i?1'b0: line1_now_allowin;
            assign line1_now_to_next_valid_o = line1_now_to_next_valid;
            assign line2_now_to_next_valid_o = line2_now_to_next_valid;
       
endmodule

