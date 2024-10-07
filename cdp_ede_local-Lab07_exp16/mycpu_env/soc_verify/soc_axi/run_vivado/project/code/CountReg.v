/*
*作者：zzq
*创建时间：2023-04-18
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

`include "DefineLoogLenWidth.h"
module CountReg(
    input  wire  clk      ,
    input  wire  rst_n    ,
    output wire  [63:0]countreg_rdata_o   
);

/***************************************input variable define(输入变量定义)**************************************/

/***************************************output variable define(输出变量定义)**************************************/

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
reg [63:0]count_reg;
/****************************************input decode(输入解码)***************************************/


/****************************************output code(输出解码)***************************************/
    assign countreg_rdata_o = count_reg;
/*******************************complete logical function (逻辑功能实现)*******************************/
    always @(posedge clk)begin
        if(rst_n == `RstEnable)begin
            count_reg <= 64'd0;
        end else begin
            count_reg <= count_reg + 64'd1;
        end
    end
endmodule
