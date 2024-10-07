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
module SignProduce(
    input  wire  [`IdToSpBusWidth] id_to_ibus  ,
    output wire [`AluOpWidth]inst_aluop_o,
    output  wire [`SignWidth] inst_sign_o      
);
/***************************************parameter define(常量定义)**************************************/

/***************************************variable define(变量定义)**************************************/
wire [`OdToIspBusWidth]od_to_isp_obus;
/*******************************complete logical function (逻辑功能实现)*******************************/

    OpDecoder OpDecoder_i(
        .sp_to_ibus(id_to_ibus),
        .to_isp_obus(od_to_isp_obus)
    );

    IndetifyInstType IndetifyInstType_i(
        .od_to_ibus(od_to_isp_obus),
        .inst_aluop_o(inst_aluop_o),
        .inst_sign_o(inst_sign_o)
    );

endmodule
