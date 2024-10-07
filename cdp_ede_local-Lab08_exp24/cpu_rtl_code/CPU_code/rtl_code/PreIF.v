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
1. 因为没考虑if阶段的allow,导致气泡插入，把下一条指令的inst没有保存，丢失了
2. if if阶段不允许输入，则pre_if应该保持原值，保证isnt_ram的读出数据可以持续两个时钟周期，
3. 例外使能信号和地址信号顺序反了，拼接错误
4. 取指例外，则valid=1,不发地址请求到外界，往下一级写入的是无执行效果的非空指令
5. now_clk有冲刷信号，则不发出指令存储器的读请求，往下一级写入的是空指令
6. 当取指令例外遇到到冲刷信号，则取指令例外无效
\*************/
//`include "DefineLoogLenWidth.h"
//`include "DefineModuleBus.h"
`include "define.v"
module PreIF(
    input wire                        rst_n               ,
    input wire                        next_allowin_i      ,
    output                            now_to_next_valid_o ,
    
    //冲刷信号由于我的例外跳转地址晚冲刷信号一个时钟周期所以，在冲刷的时钟周期不允许发出清楚
    input wire                        excep_flush_i       ,
    //CPU错误
    input wire cpu_error_i,

    input  wire  [`IfToPreBusWidth]   if_to_ibus          ,
    input  wire [`IftToPreifBusWidth]  ift_to_ibus          ,
    //跳转
    input  wire [`IdToPreifBusWidth]  id_to_ibus          ,
    input  wire interrupt_en_i,
    
    //例外返回
    input  wire [`CsrToPreifWidth]    csr_to_ibus         ,
    input  wire [`PcBufferBusWidth]   pcbuffer_to_ibus    ,
    input  wire                       inst_ram_addr_ok_i  ,
   
    output wire                       inst_sram_req_o     ,
    output wire [`PcWidth]            inst_sram_raddr_o   ,//指令的物理地址
    output wire [`PcBufferBusWidth]   to_pcbuffer_obus    ,   
    output wire [`PreifToNextBusWidth]to_next_obus       
    
);

/***************************************input variable define(输入变量定义)**************************************/
    wire branch_flag_i;
    wire [`PcWidth]branch_pc_i;
    
    wire [`PcWidth]excep_entry_pc_i;  
    wire [`PcWidth]ertn_pc_i       ;  
    wire [`PcWidth]tlb_inst_flush_entry_pc_i;
    wire tlb_inst_flush_en_i;
    wire excep_en_i; 
    wire ertn_en_i       ; 
    
    wire pc_buffer_we_i;
    wire [`PcWidth]pc_buffer_pc_i;
    wire order_we_i;
    wire [`PcWidth]order_pc_i;
    
    wire ift_we_i;
    wire [`PcWidth]ift_pc_i;
    
    //tlb
    wire line1_tlb_excpet_en_i;
    wire line1_tlb_adef_except_en_i;
    //
    wire stall_i;
    wire [`PcWidth]stall_pc_i;
    
/***************************************output variable define(输出变量定义)**************************************/
    wire [`PcWidth]pc1_o;
    wire [`PcWidth]pc2_o;
    //缓存
    wire pc_buffer_we_o;
    wire [`PcWidth]pc_buffer_wdata_o;
    //例外
    wire line1_excpet_en_o ;
    wire [`ExceptionTypeWidth]line1_excep_type_o;
   
    
    wire line2_excpet_en_o ;
    wire [`ExceptionTypeWidth]line2_excep_type_o;
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
wire now_ready_go ;
//例外
 wire line1_pc_adef;
 wire line2_pc_adef;
/****************************************input decode(输入解码)***************************************/
assign {branch_flag_i,branch_pc_i} = id_to_ibus;
assign {stall_i,stall_pc_i,tlb_inst_flush_en_i,tlb_inst_flush_entry_pc_i,excep_en_i,ertn_en_i,excep_entry_pc_i,ertn_pc_i} = csr_to_ibus;
assign {order_we_i,order_pc_i} = if_to_ibus;
assign {ift_we_i,ift_pc_i} = ift_to_ibus;
assign {pc_buffer_we_i,pc_buffer_pc_i} = pcbuffer_to_ibus;
/****************************************output code(输出解码)***************************************/
assign to_next_obus = {inst_sram_req_o,line2_excpet_en_o,line2_excep_type_o,pc2_o,
                                       line1_excpet_en_o,line1_excep_type_o,pc1_o};
//取指令发生例外的时候，不用发出请求
//冲刷流水线时候不允许访问instram
assign inst_sram_req_o  = rst_n && next_allowin_i && (!excep_flush_i) && !line1_excpet_en_o &&~stall_i;
assign to_pcbuffer_obus = {pc_buffer_we_o,pc_buffer_wdata_o};
/*******************************complete logical function (逻辑功能实现)*******************************/
//assign pc1_o = excep_en_i     ? excep_entry_pc_i :          
//               ertn_en_i      ? ertn_pc_i        :
//               tlb_inst_flush_en_i ? tlb_inst_flush_entry_pc_i:
//               branch_flag_i  ? branch_pc_i : 
//               order_we_i     ? order_pc_i+32'd4  : 
//               pc_buffer_we_i ? pc_buffer_pc_i  : order_pc_i+32'd4;

//assign pc1_o = excep_en_i     ? excep_entry_pc_i :          
//               ertn_en_i      ? ertn_pc_i        :
//               tlb_inst_flush_en_i ? tlb_inst_flush_entry_pc_i:
//               branch_flag_i  ? branch_pc_i : 
//               order_we_i     ? order_pc_i+32'd4  : 
//               pc_buffer_we_i ? pc_buffer_pc_i  : order_pc_i+32'd4;



 assign pc1_o = 
               stall_i        ? stall_pc_i:
               excep_en_i     ? excep_entry_pc_i :          
               ertn_en_i      ? ertn_pc_i        :
               tlb_inst_flush_en_i ? tlb_inst_flush_entry_pc_i:
               branch_flag_i  ? branch_pc_i : 
               ift_we_i       ?ift_pc_i:            
               order_we_i     ?  order_pc_i+32'd4  : 
               pc_buffer_we_i ? pc_buffer_pc_i  : order_pc_i+32'd4;       
               
               
               

assign pc2_o = pc1_o +32'd4;
//例外
assign line1_excpet_en_o  = interrupt_en_i;
assign line1_excep_type_o[`IntEcode]                     = interrupt_en_i ? 1'b1 : 1'b0;//0
assign line1_excep_type_o[`IfPpiLocation:`PilLocation]     = 0;
//访问虚拟地址
assign inst_sram_raddr_o = pc1_o;


assign line2_excpet_en_o = 1'b0;
assign line2_excep_type_o = `ExceptionTypeLen 'd 0;

//pcbuffer写使能
//当if级不允许allowin即if级还没有等到数据的时候，preif是发不出req,但是这个跳转地址要锁存的，例外返回指令也会遇到这种情况
//当前发出读请求： if顺序执行没有收到地址ok就要所存地址，如果跳转执行？???
//无论当前有没有发出地址请求，只要
//总结：没发请求或者发啦请求addr_ok=1就要保存当前地址，发了请求，addr_ok则不需要保存地址空，因为这个数据会流往if级
assign pc_buffer_we_o =(!inst_sram_req_o) || (inst_sram_req_o && (!inst_ram_addr_ok_i));//当本时钟周期的pc没有获得addr_ok，就要开始锁存pc啦,当前发出了指令请求，没有收到addr——ok,才要维持这个数据
assign pc_buffer_wdata_o = pc1_o;

//握手信号
//取指异常，则可以直接流入下一级
//出现CPU错误就不允许继续取指令了
assign now_ready_go        = ~cpu_error_i&((inst_sram_req_o & inst_ram_addr_ok_i&~stall_i) || (line1_excpet_en_o)); //id阶段数据是否运算好了，1：是
assign now_to_next_valid_o = now_ready_go;//id阶段打算写入
            
endmodule
