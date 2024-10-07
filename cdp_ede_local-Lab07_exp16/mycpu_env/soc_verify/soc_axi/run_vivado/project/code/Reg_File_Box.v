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
`include "DefineModuleBus.h"
module Reg_File_Box(
    input  wire  clk      ,
    input  wire  rst_n    ,

    input  wire [`IdToRfbBusWidth]   id_to_ibus         ,
    input  wire [`RegsWriteBusWidth] wb_to_regs_ibus     ,
    input  wire [`WbToCsrWidth]      wb_to_csr_ibus       ,
    input  wire [`ExcepToCsrWidth]   excep_to_csr_ibus,//例外使能了，要执行了
    
    input wire [7:0] hardware_interrupt_data_i,
    
    output wire [`CsrToPreifWidth]to_preif_obus,
    output wire [63:0] countreg_to_id_obus,
    output wire [`RfbToIdBusWidth]   to_id_obus   ,
    output wire [`CsrToWbWidth] to_wb_obus,
    output wire interrupt_en_o
   
         
);

/***************************************input variable define(输入变量定义)**************************************/
   
    wire [`RegsReadIbusWidth]id_to_regs_ibus;
/***************************************output variable define(输出变量定义)**************************************/
    wire [`RegsReadObusWidth]regs_to_id_obus;
    wire [`CsrToIdWidth]csr_to_id_obus;
    wire [`CsrToWbWidth]csr_to_wb_obus;
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/

/****************************************input decode(输入解码)***************************************/
assign id_to_regs_ibus = id_to_ibus;

/****************************************output code(输出解码)***************************************/
assign to_id_obus = {csr_to_id_obus,csr_to_id_obus,regs_to_id_obus};

/*******************************complete logical function (逻辑功能实现)*******************************/
         Reg_File RFI(
                   .rf_in_rstL   ( rst_n )        ,
                   .rf_in_clk    ( clk )          ,
                   
                   .read_ibus  (id_to_regs_ibus) ,
                   .write_ibus (wb_to_regs_ibus ),
                   .read_obus  (regs_to_id_obus) 
         );
         //访问
         Csr CsrI(
                .clk(clk),
                .rst_n(rst_n),
                .excep_to_ibus(excep_to_csr_ibus),
                .wb_to_ibus(wb_to_csr_ibus),
                .hardware_interrupt_data_i(hardware_interrupt_data_i),//外部硬件中断
                
                
                .to_id_obus(csr_to_id_obus),
                .to_wb_obus(to_wb_obus),
                .interrupt_en_o(interrupt_en_o),
                .to_preif_obus (to_preif_obus)
         );
         
         CountReg  CountRegI(
                .clk(clk),
                .rst_n(rst_n),
                .countreg_rdata_o (countreg_to_id_obus)
         
         );
endmodule
