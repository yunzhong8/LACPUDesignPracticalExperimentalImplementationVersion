/*
*作者：
*创建时间：
*email:
*github:
*输入：
*clk:除法器的时钟
*rst_n:复位信号，低电频表示复位
*y:被除数，位宽[31:0]
*x:除数,位宽[31:0]
*div:1表示除法，0表示取模
*div_signed:1表示有符号运算，0表示无符号运算
*输出：
*q：商，位宽[31:0],
*r: 余数，位宽[31:0]
*finished:除法完成信号，1表示完成，0表示还未完成
*模块功能：
*q=signed(y)/signed(x),q=unsigned(y)/unsigned(x),r=signed(y)%signed(x),r=unsigned(y)%unsigned(x)
*默认：一个数如果定义为有符号数，则该数是补码形式，在不使用$signed()情况下所有数都是无符号数，eg:$signed(4'hf)表示-1,4‘hf表示15
*/
/*************\
bug:
1. 负数转原码错误
2. 求出的结果要转为补码形式，我没有转所以错误
3. +0补码：0000_0000,-0补码：8000_0000，规定计算机中0的补码只能是0000_00000
\*************/
`include "DefineModuleBus.h"
module Div(
    input  wire  clk      ,
    input  wire  rst_n    ,

    input  wire  div_en_i,//除法使能
    input  wire  div_signed_i   ,//有无符号除
    input  wire [`AluOperWidth]  divisor_i      ,//除数
    input  wire [`AluOperWidth]  dividend_i     ,//被除数

    output wire [31:0]  quotient_o        ,//商 [63:32]
    output wire [31:0]  remainder_o      ,//余数[31:0]
    output reg   finished_o
);



/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
wire [`AluOperWidth]unsign_divisor,unsign_dividend;//无符号形式
wire divisor_sign ,dividend_sign;
wire quotient_sign,remainder_sign;
reg [5:0]count;//计数器
//运算过程中的商和余数  
reg [31:0]process_quotient ;
reg [31:0]process_remainder;


//除数扩展
wire [63:0]expend_unsign_divisor; 



/*******************************complete logical function (逻辑功能实现)*******************************/
//将有符号补码转成原码,负数将数值位[30:0]按位取反+1，同时设置符号位=0,原码的符号位=补码的[31]
wire [`AluOperWidth]negative_divsor_source_code   = {1'b0,~divisor_i[30:0]+1};
wire [`AluOperWidth]negative_dividend_source_code = {1'b0,~dividend_i[30:0]+1} ;
assign unsign_divisor  = div_signed_i ? (divisor_i[31]  ? {1'b0,negative_divsor_source_code[30:0] }  : divisor_i[31:0]) : divisor_i[31:0];
assign unsign_dividend = div_signed_i ? (dividend_i[31] ? {1'b0,negative_dividend_source_code[30:0]} : dividend_i     ) : dividend_i;
//获取除数和被除数符号
assign divisor_sign = divisor_i[31];
assign dividend_sign = dividend_i[31] ;
//计算商和余数的符号
//商的符号等于被除数异或除数，余数符号和被除数相同
assign quotient_sign  =  divisor_sign ^ dividend_sign;
assign remainder_sign = dividend_sign;
//
assign expend_unsign_divisor = unsign_divisor << count;

//周期计数
always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        count <= 6'd31;
    end else if ( div_en_i && count == 6'd63)begin
        count <= 6'd31;
    end else if (div_en_i)begin
        count <= count -6'd1;
    end else begin
        count <= count ;
    end
end

always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        process_quotient  <= 33'd0;
        process_remainder <= 32'd0;
        finished_o  <= 1'b0;
    end if (count == 6'd31 && div_en_i) begin//被除数和3左移32的除数比较
        if($unsigned(unsign_dividend) < $unsigned(expend_unsign_divisor))begin//被除数 < 左移32的除数
            process_quotient[count] <= 1'b0;//商的第32的权值=0，所以运算过程的商设在为33位，第0位为无效位
            process_remainder       <= unsign_dividend;//被除数值保持不变
            finished_o <= 1'b0;
        end else begin//被除数 >= 左移32的除数  
            process_quotient[count] <= 1'b1;//商的第32的权值=1
            process_remainder       <= unsign_dividend - expend_unsign_divisor ;//被除数值 = 被除数-左移32的除数
            finished_o <= 1'b0;
        end
    end else if(count > 6'd0 && div_en_i && count < 6'd31) begin
        if(process_remainder < expend_unsign_divisor)begin //用减过除数的被除数即余数和扩展的除数比较                 
            process_quotient[count] <= 1'b0;                               
            process_remainder       <= process_remainder;        
            finished_o <= 1'b0;                       
        end else begin                                               
            process_quotient[count] <= 1'b1;                                
            process_remainder       <= process_remainder - expend_unsign_divisor ;   
            finished_o <= 1'b0;   
        end                                                               
    end else if (count == 6'd0 && div_en_i)begin
        if(process_remainder < expend_unsign_divisor)begin                  
            process_quotient[count] <= 1'b0;                               
            process_remainder       <= process_remainder;    
            finished_o <= 1'b1;                           
        end else begin                                               
            process_quotient[count] <= 1'b1;                                
            process_remainder       <= process_remainder - expend_unsign_divisor ;    
            finished_o <= 1'b1;  
        end           
    end else begin
        finished_o <= 1'b0;
    end
end
//将商的绝对值根据符号转为补码形式
wire [`AluOperWidth]negative_quotient_complement_o = {quotient_sign,~process_quotient [30:0]+1};
wire [`AluOperWidth]negative_remainder_complement_o = {remainder_sign,~process_remainder[30:0]+1};
assign quotient_o  = div_signed_i ? ( quotient_sign && (process_quotient!=32'd0)   ? {quotient_sign,negative_quotient_complement_o [30:0]} :process_quotient) :process_quotient ;
assign remainder_o = div_signed_i ? ( remainder_sign && (process_remainder!=32'd0) ? {remainder_sign,negative_remainder_complement_o[30:0]} :process_remainder)  :process_remainder;

endmodule
