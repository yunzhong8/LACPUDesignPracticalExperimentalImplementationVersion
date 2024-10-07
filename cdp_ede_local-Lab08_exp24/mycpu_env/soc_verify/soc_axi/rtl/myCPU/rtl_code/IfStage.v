/*
*作者：zzq
*创建时间：2023-04-22
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*当前时钟周期是跳转信号的时候，如果当前流水正好要流向下一级，这设置now_to_valid=0，if 不是则设在preif_if中now_valid=0
*/
/*************\
bug:
缓存id阶段的冲刷信号是本机不允许输入，不是看下级是否允许输入:
\*************/
//`include "DefineModuleBus.h"
`include "define.v"
module IfStage(
    input   wire                        clk                          ,
    input   wire                        rst_n                        ,
    //握手                                                                        
    input   wire                        next_allowin_i               ,                        
    input   wire                        pre_to_now_valid_i           ,   
              
                                                                               
    output  wire                        line1_now_to_next_valid_o    ,          
          
    output  wire                        now_allowin_o                ,                        
    //冲刷                                                                        
    input   wire                        excep_flush_i                , 
    input   wire                        other_flush_i                ,
                            
    //错误`
     //   output wire                         error_o,                                                     
    //数据域                                          
    input  wire [`PreifToNextBusWidth]  pre_to_ibus                  ,
       
  
    
    input  wire [`MmuToIfBusWidth]      mmu_to_ibus                  ,//地址翻译结果
    input  wire [`PrToIfBusWidth]       pr_to_ibus                   ,//分支预测结果
    input  wire                            pre_uncache_i,
    output wire [`PucAddrWidth]                      puc_raddr_o,

    output wire                         if_now_clk_ram_req_o         ,                                                                   
    output wire [`IfToPreBusWidth]      to_pre_obus                  , //顺序执行的地址
    output wire [`IfToMmuBusWidth]      to_mmu_obus                  ,//传给mmu的虚拟地址  
    output wire [`IfToNextSignleBusWidth]   to_next_signle_data_obus     ,//传给下一级的单独使用数据   
    output wire [`IfToNextBusWidth]     to_next_obus                  //传给下一级的两个组合逻辑的数据          
);

/***************************************input variable define(输入变量定义)**************************************/

/***************************************output variable define(输出变量定义)**************************************/

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//preif_if
wire now_valid;
wire [`PreifToNextBusWidth]pre_to_bus;

//跳转冲刷
wire branch_flush;
//缓存分支预测器的结果
wire pr_buffer_we;
wire [`PrToIfDataBusWidth]pr_data;
wire [`PrToIfDataBusWidth]pr_to_if_data;
/****************************************input decode(输入解码)***************************************/
/****************************************output code(输出解码)***************************************/
/*******************************complete logical function (逻辑功能实现)*******************************/
 
       
 //PC缓存
    Preif_IF Preif_IFI(
        //时钟信号
        .rst_n (rst_n),
        .clk  (clk),
        //握手信号
        .preif_to_if_valid_i(pre_to_now_valid_i),
        .if_allowin_i(now_allowin_o),
        .if_valid_o(now_valid),
        //冲刷信号
        .excep_flush_i(excep_flush_i),
        .banch_flush_i(branch_flush),
        
        //上级传入的数据域
        .preif_to_ibus (pre_to_ibus ),     
        .to_if_obus (pre_to_bus),
        
        //其他流水级/模块传入数据缓存
        .pr_we_i(pr_buffer_we),
        .pr_data_i(pr_to_ibus[`PrToIfDataBusWidth]),
        
        .pr_data_o  (pr_data)   
        
        );
    

    IF IFI(
        //握手
        .next_allowin_i(next_allowin_i),
        .now_valid_i(now_valid),
        
        .now_allowin_o(now_allowin_o),
        .line1_now_to_next_valid_o(line1_now_to_next_valid_o),
        .line2_now_to_next_valid_o(line2_now_to_next_valid_o),
        
        //冲刷信号
        .excep_flush_i(excep_flush_i),
        .branch_flush_i(other_flush_i),
        
        //上下级数据域
        .pre_to_ibus(pre_to_bus),
        .pre_uncache_i(pre_uncache_i),
        
        .if_now_clk_ram_req_o(if_now_clk_ram_req_o),
        .to_preif_obus(to_pre_obus),
        .to_next_obus(to_next_obus),
        .to_next_signle_data_obus(to_next_signle_data_obus),
        
        //其他流水线信息
        //.interrupt_en_i(interrupt_en_i),//中断使能
       
        .puc_raddr_o(puc_raddr_o),
        .mmu_to_ibus(mmu_to_ibus),
        .pr_data_i (pr_to_if_data),
               
        .to_mmu_obus(to_mmu_obus)
       
        
        );
        
//缓存其他流水级传入信号（错了是当前级不允许输入则要缓存，不是下一级允许输入）
    assign branch_flush = other_flush_i&~now_allowin_o;
    //分支预测        
        //要缓存分支预测传入的数据使能信号     
        assign pr_buffer_we = pr_to_ibus[`PrToIfDataBusLen] &~ now_allowin_o;
        //缓存数据数据域
        assign pr_to_if_data =  pr_to_ibus[`PrToIfDataBusLen] ? pr_to_ibus[`PrToIfDataBusWidth] : pr_data;
       
endmodule
