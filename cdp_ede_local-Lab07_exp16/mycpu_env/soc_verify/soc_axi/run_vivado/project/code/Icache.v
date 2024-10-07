/*
*作者：zzq
*创建时间：2023-04-21
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*实现8路4组的双端口读，单端口写的全相连icache,直接输入标记字段pc进行访问
*/
/*************\
bug:
\*************/
`include "DefineModuleBus.h"
module Icache(
    input  wire             rst_n              ,
    input  wire             clk               ,
    
    
    input  wire [`ICacheReadIbusWidth] read_ibus,
    input  wire [`ICacheWriteIbusWidth] write_ibus,
    output wire [`ICacheReadObusWidth] read_obus
    
    
    
   
    
    
 );

/***************************************input variable define(输入变量定义)**************************************/

  wire             re1_i             ;                                                         
  wire  [`PcWidth]   raddr1_i        ;                                                         
  wire             re2_i             ;                                                         
  wire  [`PcWidth]   raddr2_i        ;                                                         
                                                                                                              
  wire                        we_i              ;                                                      
  wire  [`PcWidth]            wpcdata_i           ;//写入pc ,作为cached的标记字段                                                  
  wire  [`InstWidth]          winstdata_i           ;//写入指令 ，作为cached的数据字段                                                
                                                           


/***************************************output variable define(输出变量定义)**************************************/                                                        
 wire              rt1_o            ;                                                   
 wire  [`InstWidth]  rdata1_o       ;                                                   
 wire              rt2_o            ;                                                   
 wire  [`InstWidth]  rdata2_o       ;                                                   
                                                                 








/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/

    //4组
   
    wire ic0_rt1,ic0_rt2;
    wire [31:0]ic0_rdata1,ic0_rdata2;
    
    
    wire ic1_rt1,ic1_rt2;
    wire [31:0]ic1_rdata1,ic1_rdata2;
    
   
    wire ic2_rt1,ic2_rt2;
    wire [31:0]ic2_rdata1,ic2_rdata2;
    
    
    wire ic3_rt1,ic3_rt2;
    wire [31:0]ic3_rdata1,ic3_rdata2;
    //cache地址
    reg [`ICacheAddrWidth]wpoint_reg;
    wire [`ICacheIndexWidth]      index;//索引
    wire [2:0]offset;//块内偏移地址
/****************************************input decode(输入解码)***************************************/
                                                        
     assign {re2_i,raddr2_i,re1_i,raddr1_i} = read_ibus;
     assign {we_i,wpcdata_i,winstdata_i} = write_ibus;                                                                                                             
                                                                                                                

/****************************************output code(输出解码)***************************************/
assign read_obus = {rt2_o,rdata2_o,rt1_o ,rdata1_o};
/*******************************complete logical function (逻辑功能实现)*******************************/

    //д�������
    
    //写指针寄存器器，指针每次指向空位置
    always @(posedge clk)begin
        if(rst_n==`RstEnable)begin
            wpoint_reg <= 6'd0;
        end else if( we_i )begin
            wpoint_reg <= wpoint_reg +`ICacheAddrLen'd1 ;
        end else begin
            wpoint_reg <= wpoint_reg;
        end
    end  
    
    assign  offset = wpoint_reg[2:0];
    assign  index  =   ( wpoint_reg[`ICacheAddrLen-1:`ICacheAddrLen-2]==2'b00)?`ICacheIndexLen'b0001:
                       ( wpoint_reg[`ICacheAddrLen-1:`ICacheAddrLen-2]==2'b01)?`ICacheIndexLen'b0010:
                       ( wpoint_reg[`ICacheAddrLen-1:`ICacheAddrLen-2]==2'b10)?`ICacheIndexLen'b0100:
                       ( wpoint_reg[`ICacheAddrLen-1:`ICacheAddrLen-2]==2'b11)?`ICacheIndexLen'b1000:`ICacheIndexLen'b0000;
    
    IcacheGroup Group0(
       .rst_n         ( rst_n       )   ,
       .clk           ( clk        )   ,
       .re1_i         ( re1_i      )   ,
       .raddr1_i      ( raddr1_i   )   ,
       .re2_i         ( re2_i       )   ,
       .raddr2_i      ( raddr2_i   )   ,
       
       .we_i          ( index[0]&we_i     )   ,
       .waddr_i       ( offset )   ,
       .wpcdata_i     ( wpcdata_i    )   ,
       .winstdata_i   ( winstdata_i    )   ,
//       .              (      
       .rt1_o         ( ic0_rt1    )   ,
       .rdata1_o      ( ic0_rdata1 )   ,
       .rt2_o         ( ic0_rt2    )   ,
       .rdata2_o      ( ic0_rdata2 )              
    );
    IcacheGroup Group1(
       .rst_n          ( rst_n       )   ,
       .clk           ( clk        )   ,
       .re1_i         ( re1_i      )   ,
       .raddr1_i      ( raddr1_i   )   ,
       .re2_i          ( re2_i      )   ,
       .raddr2_i      ( raddr2_i   )   ,
       .we_i          ( index[1]&we_i     )   ,
       .waddr_i       ( offset    )   ,
       .wpcdata_i     ( wpcdata_i     )   ,
       .winstdata_i   ( winstdata_i   )   ,
//       .              (      
       .rt1_o         ( ic1_rt1    )   ,
       .rdata1_o      ( ic1_rdata1 )   ,
       .rt2_o         ( ic1_rt2    )   ,
       .rdata2_o      ( ic1_rdata2 )              
    );
    IcacheGroup Group2(
       .rst_n          ( rst_n       )   ,
       .clk           ( clk        )   ,
       .re1_i           ( re1_i      )   ,
       .raddr1_i      ( raddr1_i   )   ,
       .re2_i          ( re2_i      )   ,
       .raddr2_i      ( raddr2_i   )   ,
       .we_i          ( index[2]&we_i     )   ,
       .waddr_i       ( offset )   ,
       .wpcdata_i     ( wpcdata_i      )   ,
       .winstdata_i   ( winstdata_i    )   ,
  
       .rt1_o         ( ic2_rt1    )   ,
       .rdata1_o      ( ic2_rdata1 )   ,
       .rt2_o         ( ic2_rt2    )   ,
       .rdata2_o      ( ic2_rdata2 )              
    );
    IcacheGroup Group3(
       .rst_n          ( rst_n       )   ,
       .clk           ( clk        )   ,
       .re1_i         ( re1_i      )   ,
       .raddr1_i      ( raddr1_i   )   ,
       .re2_i         ( re2_i      )   ,
       .raddr2_i      ( raddr2_i   )   ,
       .we_i          ( index[3]&we_i     )   ,
       .waddr_i       ( offset    )   ,
       .wpcdata_i     ( wpcdata_i      )   ,
       .winstdata_i   ( winstdata_i    )   ,
      
       .rt1_o         ( ic3_rt1    )   ,
       .rdata1_o      ( ic3_rdata1 )   ,
       .rt2_o         ( ic3_rt2    )   ,
       .rdata2_o      ( ic3_rdata2 )              
    );
    //读端口1
    //读命中
    assign  rt1_o=ic0_rt1|ic1_rt1|ic2_rt1|ic3_rt1;
    assign rdata1_o=ic0_rt1?ic0_rdata1:
                    ic1_rt1?ic1_rdata1:
                    ic2_rt1?ic2_rdata1:
                    ic3_rt1?ic3_rdata1:32'h0000_0000;
    //读端口2
    //读命中
    assign  rt2_o=ic0_rt2|ic1_rt2|ic2_rt2|ic3_rt2;                
    assign rdata2_o=ic0_rt2?ic0_rdata2:
                    ic1_rt2?ic1_rdata2:
                    ic2_rt2?ic2_rdata2:
                    ic3_rt2?ic3_rdata2:32'h0000_0000;
endmodule
