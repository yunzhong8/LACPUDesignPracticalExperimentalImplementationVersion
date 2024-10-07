/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：译码器，将16进制数字译码成1位表示一个数
*
*/
/*************\
bug:
1. `OdToIspBusWidth 忘记添加rd,rk,rj的译码结果
2. obus中rd_d被我写成rd_i难怪输出位宽不对
\*************/
`include "DefineModuleBus.h"
module OpDecoder(
    input  wire  [`IdToSpBusWidth]sp_to_ibus ,
    output wire  [`OdToIspBusWidth]to_isp_obus
    /*
    output  wire [63:0]      op_31_26_d_o  ,
    output  wire [15:0]      op_25_22_d_o  ,
    output  wire [3:0]       op_21_20_d_o  ,
    output  wire [31:0]      op_19_15_d_o
    */
);
/***************************************parameter define(常量定义)**************************************/

/***************************************variable define(变量定义)**************************************/

    wire [63:0]      op_31_26_d_o  ;
    wire [15:0]      op_25_22_d_o  ;
    wire [3:0]       op_21_20_d_o  ;
    wire [31:0]      op_19_15_d_o  ;
    
    wire [ 5:0] op_31_26_i;
    wire [ 3:0] op_25_22_i;
    wire [ 1:0] op_21_20_i;
    wire [ 4:0] op_19_15_i;
/*******************************内部变量**************************/
    wire [31:0]inst_i;
    wire [4:0]rk_i;
    wire [4:0]rd_i;
    wire [4:0]rj_i;
    wire [31:0]rd_d,rj_d,rk_d;
/*******************输入变量解压*******************/
    assign{rk_i,rj_i,rd_i,inst_i }= sp_to_ibus;

/*******************************complete logical function (逻辑功能实现)*******************************/
//截取op
assign op_31_26_i = inst_i[31:26];
assign op_25_22_i = inst_i[25:22];
assign op_21_20_i = inst_i[21:20];
assign op_19_15_i = inst_i[19:15];
//解码
decoder_6_64 u_dec0(.in(op_31_26_i ), .out(op_31_26_d_o ));
decoder_4_16 u_dec1(.in(op_25_22_i ), .out(op_25_22_d_o ));
decoder_2_4  u_dec2(.in(op_21_20_i ), .out(op_21_20_d_o ));
decoder_5_32 u_dec3(.in(op_19_15_i ), .out(op_19_15_d_o ));

decoder_5_32 u_dec4(.in(rd_i  ), .out(rd_d  ));
decoder_5_32 u_dec5(.in(rj_i  ), .out(rj_d  ));
decoder_5_32 u_dec6(.in(rk_i  ), .out(rk_d  ));

 assign to_isp_obus={rk_d,rj_d,rd_d,op_31_26_d_o,op_25_22_d_o,op_21_20_d_o,op_19_15_d_o,inst_i};
endmodule
