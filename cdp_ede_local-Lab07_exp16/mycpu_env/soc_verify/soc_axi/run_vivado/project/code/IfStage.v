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
\*************/
//`include xxx.h
module IfStage(
    input  wire  clk      ,
    input  wire  rst_n    ,
    //握手                                                 
    input  wire next_allowin_i  ,                        
    input  wire pre_to_now_valid_i    ,   
              
                                                         
    output  wire line1_now_to_next_valid_o    ,          
    output  wire line2_now_to_next_valid_o    ,          
    output  wire now_allowin_o  ,                        
    //冲刷                                                 
    input wire excep_flush_i, 
    input wire banch_flush_i,
    //中断使能
    input wire interrupt_en_i,                           
                                                         
    //数据域                     
    input  wire inst_sram_data_ok_i,                           
    input  wire [`PreifToIfBusWidth]pre_to_ibus         ,
    input  wire [`IdToIfBusWidth]next_to_ibus,   
    input  wire [`InstWidth]inst_sram_rdata_i,   
    input  wire [`ICacheReadObusWidth]icache_to_ibus,
    
                                                         
    output wire [`IfToPreifBusWidth]to_pre_obus,        
    output wire [`IfToICacheBusWidth]to_icache_obus     ,    
    output wire [`IfToIdBusWidth]to_next_obus           
);

/***************************************input variable define(输入变量定义)**************************************/
wire cache_we_i;
/***************************************output variable define(输出变量定义)**************************************/

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//
wire inst_rdata_buffer_we;
wire [`InstRdataBufferBusWidth]inst_rdata_buffer;
wire [`InstRdataBufferBusWidth]pi_to_if_inst_rdata_buffer;
//preif_if
wire now_valid;
wire [`PreifToIfBusWidth]pi_to_if_bus;
//指令取消
wire [1:0]next_inst_rdata_ce_we;
wire now_inst_rdata_ce;
//if
wire inst_sram_data_ok;
//跳转冲刷信号
wire banch_flush;
//指令缓存                                    
wire inst_rdata_buffer_ok;              
wire [`PcWidth]inst_rdata_buffer_rdata; 

/****************************************input decode(输入解码)***************************************/
assign {icache_iowe_useless_i,cache_we_i,branch_flush_i} = next_to_ibus;

/****************************************output code(输出解码)***************************************/

/*******************************complete logical function (逻辑功能实现)*******************************/
 
  //指令取消
  //当if级的数据有效，且当前阶段指令没有被读出的时候(buffer_ok=0,data_ok=0)，本时钟周期接受到啦冲刷，要缓存一次清空信号，
  //当if级的清空信号被用过之后(当前时钟：ce=1,data_ok_i=1)，需要设在清空信号=0,
  //存在if级数据无效，但if级接受到data_ok，
  //data_ok ,buffer_ok
  //1,0（ce状态不变）
  //0,1(ce张断不变)
  //0,0(ce要+1)不存在1，1
        assign next_inst_rdata_ce_we = (now_valid && ((excep_flush_i||banch_flush) && (!inst_sram_data_ok_i && !inst_rdata_buffer_ok)) ) ? 2'b10: 
                                       (now_inst_rdata_ce && inst_sram_data_ok_i) ? 2'b01:2'b00;
       
 //PC缓存
    Preif_IF Preif_IFI(
        .rst_n (rst_n),
        .clk  (clk),
        //握手信号
        .preif_to_if_valid_i(pre_to_now_valid_i),
        .if_allowin_i(now_allowin_o),
        .if_valid_o(now_valid),
        //冲刷信号
        .excep_flush_i(excep_flush_i),
        .banch_flush_i(banch_flush),
        
        //数据域
        .preif_to_ibus (pre_to_ibus ),
        //指令缓存
        .inst_rdata_buffer_we_i(inst_rdata_buffer_we),
        .inst_rdata_buffer_i(inst_rdata_buffer),
        //指令取消
        .inst_rdata_ce_we_i(next_inst_rdata_ce_we),
        
        
        //指令缓存读出数据
        .inst_rdata_buffer_o(pi_to_if_inst_rdata_buffer),
        //当前读出指令取消
        .inst_rdata_ce_o(now_inst_rdata_ce),
        .to_if_obus (pi_to_if_bus)
        );
     //访问指令rom
     assign inst_rdata_buffer_rdata = pi_to_if_inst_rdata_buffer[31:0];
     assign inst_rdata_buffer_ok = pi_to_if_inst_rdata_buffer[32];
    IF IFI(
        //握手
        .id_allowin_i(next_allowin_i),
        .if_valid_i(now_valid),
        
        .if_allowin_o(now_allowin_o),
        .line1_if_to_id_valid_o(line1_now_to_next_valid_o),
        .line2_if_to_id_valid_o(line2_now_to_next_valid_o),
        .excep_flush_i(excep_flush_i),
        
        
        //数据域
        .inst_sram_data_ok_i       (inst_sram_data_ok),
        .pi_to_ibus(pi_to_if_bus),
        //.inst_rdata_buffer_i(pi_to_if_inst_rdata_buffer),
        .inst_rdata_buffer_ok_i(inst_rdata_buffer_ok),
        .inst_rdata_buffer_rdata_i(inst_rdata_buffer_rdata),
        .cache_we_i (cache_we_i),
        .icache_iowe_useless_i(icache_iowe_useless_i),
        .interrupt_en_i(interrupt_en_i),//中断使能
        .ram_inst1_i(inst_sram_rdata_i),
        .icache_to_ibus( icache_to_ibus),  
        
        .to_preif_obus(to_pre_obus),
        .to_icache_obus(to_icache_obus),
        .to_id_obus(to_next_obus)
        );
        //如果当前时钟周期接受到跳转冲刷信号，但是if数据还没准备好，即准备好最早是下一个时钟周期，则要设置下一个时钟周期if级的数据为无效才行
        assign  banch_flush = (!now_allowin_o) && banch_flush_i;
        //当inst_ram读出数据，但是id阶段不允许写入，要锁存一次读出数据，但只能锁存一次
        assign inst_sram_data_ok = (!now_inst_rdata_ce) && inst_sram_data_ok_i;//如果本周期inst_rdata无效，则当前inst_ram读出数据无效，要等待下一次的inst_ram读出数据
        
        //本处的地址ok应该使用经过ce处理的地址ok才行,buffer的数据使用完要清理掉，当当前buffer数据有效且本级要写入下一级的时候，则清理掉buffer中数据
        //缓存区写1：当前输入data_ok,下级不允许输入，
        //buffer_ok,data_ok,exp_flush的先后顺序关系：存在：buffer_ok=1,,此时来了data_ok=1,exp_flush,此时冲刷buffer_ok,
        assign inst_rdata_buffer_we = inst_sram_data_ok && (!next_allowin_i) || (next_allowin_i && inst_rdata_buffer_ok);
        assign inst_rdata_buffer    = inst_sram_data_ok && (!next_allowin_i) ? {inst_sram_data_ok_i,inst_sram_rdata_i} : {1'b0,inst_sram_rdata_i};
       
        
       
endmodule
