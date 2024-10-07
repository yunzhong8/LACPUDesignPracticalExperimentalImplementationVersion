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
    
    //数据域
    input  wire data_sram_data_ok_i,
    input  wire [`ExToMemBusWidth]pre_to_ibus         ,
    input  wire [`MemDataWidth]mem_rdata_i,
    
    output wire [`MemForwardBusWidth]forward_obus,
    output wire [`MemToExBusWidth]to_ex_obus     ,
    output wire [`MemToWbBusWidth]to_next_obus          
);

/***************************************input variable define(输入变量定义)**************************************/

/***************************************output variable define(输出变量定义)**************************************/
wire [`LineMemForwardBusWidth]line2_forward_obus,line1_forward_obus;
wire line2_to_pre_obus,line1_to_pre_obus;
wire [`LineMemToWbBusWidth]line2_to_next_obus,line1_to_next_obus;
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//ExMEM
wire line2_now_valid,line1_now_valid;

wire  [`ExToMemBusWidth] em_to_mem_bus ;
//MEM
wire [`LineExToMemBusWidth]line2_em_to_mem_bus,line1_em_to_mem_bus;
wire line2_now_to_next_valid,line1_now_to_next_valid;
wire  line2_now_allowin,line1_now_allowin;
//data_ram读出取消
wire next_data_ram_rdata_ce_we;
wire next_data_ram_rdata_ce;
wire now_data_ram_rdata_ce;
//读ok
wire data_sram_data_ok;

/****************************************input decode(输入解码)***************************************/


/****************************************output code(输出解码)***************************************/
assign to_ex_obus = {line2_to_pre_obus,line1_to_pre_obus}  ;
assign to_next_obus = {line2_to_next_obus,line1_to_next_obus} ;
assign forward_obus = {line2_forward_obus,line1_forward_obus};
/****************************************output code(内部解码)***************************************/
assign {line2_em_to_mem_bus,line1_em_to_mem_bus} = em_to_mem_bus;

/*******************************complete logical function (逻辑功能实现)*******************************/
 assign next_data_ram_rdata_ce_we =( line1_now_to_next_valid_o && excep_flush_i && (!data_sram_data_ok_i)) || (now_data_ram_rdata_ce && data_sram_data_ok_i);
 assign next_data_ram_rdata_ce =  line1_now_to_next_valid_o && excep_flush_i && (!data_sram_data_ok_i) ? 1'b1 : 1'b0;   
 EX_MEM EXMEMI(
        .rst_n(rst_n),
        .clk(clk),
        //握手
        .line1_pre_to_now_valid_i(line1_pre_to_now_valid_i),
        .line2_pre_to_now_valid_i(line2_pre_to_now_valid_i),
        .now_allowin_i(now_allowin_o),
        
        .line1_now_valid_o(line1_now_valid),
        .line2_now_valid_o(line2_now_valid),
        
        .excep_flush_i(excep_flush_i),
        //数据域
        .data_ram_rdata_ce_we_i(next_data_ram_rdata_ce_we),
        .data_ram_rdata_ce_i(next_data_ram_rdata_ce),
        .pre_to_ibus(pre_to_ibus),
        
        .data_ram_rdata_ce_o(now_data_ram_rdata_ce),
        .to_mem_obus(em_to_mem_bus)
    );
    
//访问外部数据存储器
    MEM MEMI1(
         //握手
        .wb_allowin_i(next_allowin_i),
        .mem_valid_i(line1_now_valid),
        
        .mem_allowin_o(line1_now_allowin),
        .mem_to_wb_valid_o(line1_now_to_next_valid),
        //冲刷
        .excep_flush_i(excep_flush_i),
        
        //数据域
        .data_sram_data_ok_i(data_sram_data_ok_i),
        .exmem_to_ibus(line1_em_to_mem_bus),
        .mem_rdata_i(mem_rdata_i),
        
        .forward_obus(line1_forward_obus),
        .to_ex_obus(line1_to_pre_obus),
        .to_memwb_obus(line1_to_next_obus)
    );
//访问外部数据存储器
    MEM MEMI2(
         //握手                                               
        .wb_allowin_i       (next_allowin_i),                                
        .mem_valid_i        (line2_now_valid),                      
                                                            
        .mem_allowin_o      (line2_now_allowin),                  
        .mem_to_wb_valid_o  (line2_now_to_next_valid),   
        //冲刷   
        .excep_flush_i      (excep_flush_i),                      
                                                            
        //数据域              
        .data_sram_data_ok_i(data_sram_data_ok),                                 
        .exmem_to_ibus      (line2_em_to_mem_bus),               
        .mem_rdata_i        (mem_rdata_i),                      
                                                            
        .forward_obus       (line2_forward_obus),                  
        .to_ex_obus         (line2_to_pre_obus),                      
        .to_memwb_obus      (line2_to_next_obus)                  
                         
                         
    );
    //
    assign data_sram_data_ok = (!now_data_ram_rdata_ce) && data_sram_data_ok_i;
    assign now_allowin_o  = line2_now_allowin && line1_now_allowin;
    assign line1_now_to_next_valid_o = now_allowin_o && line1_now_to_next_valid;
    assign line2_now_to_next_valid_o = now_allowin_o && line2_now_to_next_valid;
    
endmodule
