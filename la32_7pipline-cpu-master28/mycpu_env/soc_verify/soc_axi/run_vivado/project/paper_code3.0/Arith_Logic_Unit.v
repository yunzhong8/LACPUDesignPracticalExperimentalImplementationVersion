/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：oper1/oper2<====>x/y,x被除数，除数数
*
*/
/*************\
bug:
\*************/
`include "DefineModuleBus.h"
`include "DefineAluOp.h"
module Arith_Logic_Unit(
    input  wire [`AluOperWidth] x       ,   // 源操作数x, rj，oper1
    input  wire [`AluOperWidth] y       ,   // 源操作数y, rk,oper2
    input  wire [`AluOpWidth] aluop   ,   // alu op
    input  wire [31:0]quotient_i,      
    input  wire [31:0]remainder_i,     
    input  wire div_complete_i,        
    
    output wire complete_o,//alu 运算完成
    output wire       div_en_o            ,
    output wire       div_sign_o          ,
    output wire [31:0]divisor_o           ,
    output wire [31:0]dividend_o          ,
    
    
    
    
    
    output wire [`AluOperWidth] alu_rl_o,            // 运算结果 result
    output wire [`AluOperWidth]alu_rh_o 
    

);

/***************************************input variable define(输入变量定义)**************************************/

/***************************************output variable define(输出变量定义)**************************************/

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
reg [`AluOperWidth] rl;
reg [`AluOperWidth] rh;
wire [63:0]x_sign,y_sign,x_zero,y_zero;

wire mul_sign;
wire [63:0]mul_result;
/****************************************input decode(输入解码)***************************************/

/****************************************output code(输出解码)***************************************/
assign {alu_rh_o,alu_rl_o} = {rh,rl};

/*******************************complete logical function (逻辑功能实现)*******************************/
    assign x_sign ={{32{x[31]}},x};
    assign y_sign ={ {32{y[31]}} , y };
    
    assign x_zero ={32'h0,x};
    assign y_zero ={32'h0,y};
    
    always @(*)begin                // 本写法最简单明了 (还可优化，加减比较都可通过加法器解决)
//        r = 0;
        case(aluop)
            `SllAluOp: {rh,rl} = (x << y[4:0]);                     // 0sll, sllv
            `SrlAluOp: {rh,rl} = (x >> y[4:0]);                     // 1srl, srlv
            `SraAluOp: {rh,rl} = ($signed(x) >>> y[4:0]);           // 2sra, srav   
            // (verilog变量默认无符号数, $signed()强制转换为有符号数, ">>>"算术右移运算符)
            
            `AddAluOp: {rh,rl} = x + y;                             // 3add发生溢出，默认将进位删除了，只保留32位，而不是多出一位33位
            `SubAluOp: {rh,rl} = x - y;                             // 4sub

            `AndAluOp: {rh,rl} =  (x & y);                          // 5and
            `OrAluOp : {rh,rl} =  (x | y);                          // 6or
            `XorAluOp: {rh,rl}=  (x ^ y);                          // 7xor
            `NorAluOp: {rh,rl} = ~(x | y);                          // 8nor

            `SltAluOp : {rh,rl} = ($signed(x) < $signed(y))? 1 : 0; //9slt
            `SltuAluOp: {rh,rl} = (x < y)? 1 : 0;                   //10sltu

            `LuiAluOp: {rh,rl} = {y[15:0], 16'h0000};               //11 lui
            `MulAluOp: {rh,rl} = mul_result;  //mul
            `MuluAluOp:{rh,rl} = mul_result;
            
            `DivAluOp:  {rh,rl}  = {quotient_i,remainder_i};
            `ModAluOp:  {rh,rl}  = {quotient_i,remainder_i};
            `DivuAluOp: {rh,rl}  = {quotient_i,remainder_i};
            `ModuAluOp: {rh,rl}  = {quotient_i,remainder_i};
          
            default: {rh,rl} = 0;
        endcase
    end
    
    //其他指令都是一个时钟周期完成的
    //如果是div类型指令就要等div_complete_i信号
    assign complete_o =  div_en_o ? div_complete_i : 1'b1;
    
    assign div_en_o    = (aluop == `DivAluOp) || (aluop == `ModAluOp) || (aluop == `DivuAluOp) || (aluop == `ModuAluOp) ? 1'b1 : 1'b0;                                                     
    assign div_sign_o  = (aluop == `DivAluOp) || (aluop == `ModAluOp) ? 1'b1 : 1'b0;                                                                                                             
    //被除数
    assign dividend_o  = x;  
    //除数
    assign divisor_o   = y;                                                                                                                                                                  
                                                                                                                                                                    
   
    assign mul_sign = (aluop == `MulAluOp) ? 1'b1 : 1'b0;
    
     wallace_mul wallace_mul_item (
      .sign(mul_sign),
      .x(x),
      .y(y),
      .r(mul_result)
     );
     
    
    
    
     
endmodule


