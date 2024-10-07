/*
*作者：zzq
*创建时间：2023-04-21
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*这是8行数据的cache组
*/
/*************\
bug:
\*************/
`include "DefineModuleBus.h"
module IcacheGroup(
    input  wire  clk      ,
    input  wire  rst_n    ,
    //读端口1
    input  wire             re1_i             ,//读使能
    input  wire [`PcWidth]    raddr1_i          ,//读地址
    //读端口2
    input  wire             re2_i             ,//读使能2
    input  wire  [`PcWidth]   raddr2_i          ,//读地址2
    //写端口
    input  wire             we_i              ,//写使能
    input  wire  [2:0]      waddr_i           ,//写地址
    input  wire  [`PcWidth]   wpcdata_i         ,//写pc（这是标记位，采用全标记）
    input  wire  [`InstWidth] winstdata_i       ,//写指令
    
    output reg              rt1_o             ,//读地址1命中
    output reg [`InstWidth]   rdata1_o          ,//读出数据1
    output reg              rt2_o             ,
    output reg [`InstWidth]   rdata2_o
);

/***************************************input variable define(输入变量定义)**************************************/

/***************************************output variable define(输出变量定义)**************************************/

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
    reg [31:0]AddrICache[7:0];
    reg [31:0]DataICache[7:0];
    integer i;
/****************************************input decode(输入解码)***************************************/


/****************************************output code(输出解码)***************************************/

/*******************************complete logical function (逻辑功能实现)*******************************/
    //cache组写入
    always @(posedge clk)begin
        if(rst_n==`RstEnable)begin
            for(i=0;i<8;i=i+1)begin
                AddrICache[i]=32'h0;
                DataICache[i]=32'h0;
            end
        end else if(we_i)begin
            {AddrICache[waddr_i],DataICache[waddr_i]}<={wpcdata_i,winstdata_i};
        end else begin
             for(i=0;i<8;i=i+1)begin
                AddrICache[i]=AddrICache[i];
                DataICache[i]=DataICache[i];
            end
        end
    end 
    //端口1读
    always@(*)begin
        if(rst_n==`RstEnable)begin
            rt1_o    <=1'b0    ;
            rdata1_o <=32'h0    ;
        end else if(re1_i) begin
            if (raddr1_i==wpcdata_i)begin
                rt1_o   <= 1'b1;
                rdata1_o<=winstdata_i;
            end else if (raddr1_i==AddrICache[0])begin
                rt1_o   <= 1'b1;
                rdata1_o<=DataICache[0];
            end else if (raddr1_i==AddrICache[1])begin
                rt1_o   <= 1'b1;
                rdata1_o<=DataICache[1];
            end else if (raddr1_i==AddrICache[2])begin
                rt1_o   <= 1'b1;
                rdata1_o<=DataICache[2];
            end else if (raddr1_i==AddrICache[3])begin
                rt1_o   <= 1'b1;
                rdata1_o<=DataICache[3];
            end else if (raddr1_i==AddrICache[4])begin
                rt1_o   <= 1'b1;
                rdata1_o<=DataICache[4];
            end else if (raddr1_i==AddrICache[5])begin
                rt1_o   <= 1'b1;
                rdata1_o<=DataICache[5];
            end else if (raddr1_i==AddrICache[6])begin
                rt1_o   <= 1'b1;
                rdata1_o<=DataICache[6];
            end else if (raddr1_i==AddrICache[7])begin
                rt1_o   <= 1'b1;
                rdata1_o<=DataICache[7];
            end else begin
                rt1_o   <= 1'b0;
                rdata1_o<=32'h0000_0000;
            end
       end else begin
           rt1_o   <= 1'b0;
           rdata1_o<=32'h0000_0000;
       end
   end
   //端口2读
   always@(*)begin
        if(rst_n==`RstEnable)begin
            rt2_o    <=1'b0    ;
            rdata2_o <=32'h0    ;
        end else  if(re2_i) begin//写优先
              if (raddr2_i== wpcdata_i)begin
                  rt2_o   <= 1'b1;
                  rdata2_o<=winstdata_i;
              end else if (raddr2_i==AddrICache[0])begin
                  rt2_o   <= 1'b1;
                  rdata2_o<=DataICache[0];
              end else if (raddr2_i==AddrICache[1])begin
                  rt2_o   <= 1'b1;
                  rdata2_o<=DataICache[1];
              end else if (raddr2_i==AddrICache[2])begin
                  rt2_o   <= 1'b1;
                  rdata2_o<=DataICache[2];
              end else if (raddr2_i==AddrICache[3])begin
                  rt2_o   <= 1'b1;
                  rdata2_o<=DataICache[3];
              end else if (raddr2_i==AddrICache[4])begin
                  rt2_o   <= 1'b1;
                  rdata2_o<=DataICache[4];
              end else if (raddr2_i==AddrICache[5])begin
                  rt2_o   <= 1'b1;
                  rdata2_o<=DataICache[5];
              end else if (raddr2_i==AddrICache[6])begin
                  rt2_o   <= 1'b1;
                  rdata2_o<=DataICache[6];
              end else if (raddr2_i==AddrICache[7])begin
                  rt2_o   <= 1'b1;
                  rdata2_o<=DataICache[7];
              end else begin
                  rt2_o   <= 1'b0;
                  rdata2_o<=32'h0000_0000;
              end
       end else begin
            rt2_o   <= 1'b0;
            rdata2_o<=32'h0000_0000;
      end
   end
endmodule


