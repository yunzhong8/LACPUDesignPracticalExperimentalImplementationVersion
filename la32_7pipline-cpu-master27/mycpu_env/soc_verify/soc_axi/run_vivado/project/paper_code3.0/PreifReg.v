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
module PreifReg(
    input  wire  clk      ,
    input  wire  rst_n    ,
    input  wire excep_flush_i,
    
    input wire [`PcBufferBusWidth]inst_pc_buffer_i,
    output reg [`PcBufferBusWidth] inst_pc_buffer_o
    );
     always@(posedge clk)begin
        if(rst_n == `RstEnable || excep_flush_i)begin
            inst_pc_buffer_o <= `PcBufferBusLen'd0;
        end else begin
            inst_pc_buffer_o <= inst_pc_buffer_i;
        end
    end
endmodule