`include "DefineModuleBus.h"
module Reg_File(
               input wire                           rf_in_rstL,
               input wire                           rf_in_clk,
               //输入
               input wire  [`RegsReadIbusWidth] read_ibus,
               input wire  [`RegsWriteBusWidth] write_ibus,
               output wire [`RegsReadObusWidth] read_obus    
                   
    );
 //功能：寄存器组，可以实现两个端口同时读，一个端口写，读写可以同时进行，读将是待写入的数据
 
 
 /***************************************input variable define(输入变量定义)**************************************/
 //读端口1 
         wire                      rf_in_re1           ; //1号端口读使能信号 
         wire [`RegsAddrWidth]     rf_in_raddr1        ;// 1号端口读地址 
    //读端口2
         wire                      rf_in_re2           ;//2号端口读使能信号 
         wire [`RegsAddrWidth]     rf_in_raddr2        ;// 2号端口读地址 
    //写端口 
         wire                      rf_in_we1            ;//写使能信号
         wire [`RegsAddrWidth]     rf_in_waddr1         ; //写地址
         wire [`RegsDataWidth]     rf_in_wdata1         ;//写数据
         
 //读端口3 
         wire                      rf_in_re3           ; //1号端口读使能信号 
         wire [`RegsAddrWidth]     rf_in_raddr3        ;// 1号端口读地址 
    //读端口4
         wire                      rf_in_re4           ; //2号端口读使能信号 
         wire [`RegsAddrWidth]     rf_in_raddr4        ;// 2号端口读地址 
    //写端口 
         wire                    rf_in_we2            ;//写使能信号
         wire [`RegsAddrWidth]     rf_in_waddr2         ; //写地址
         wire [`RegsDataWidth]     rf_in_wdata2         ;//写数据
  
         
         
       
/***************************************output variable define(输出变量定义)**************************************/
//输出
           reg [`RegsDataWidth]         rf_out_rdata1       ;// 1号端口读数据 
           reg [`RegsDataWidth]         rf_out_rdata2       ; // 2号端口读数据 
           reg [`RegsDataWidth]         rf_out_rdata3       ; // 3号端口读数据 
           reg [`RegsDataWidth]         rf_out_rdata4       ; // 4号端口读数据       
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//存储器组变量定义
	reg[`RegsDataWidth]Regs[0:`RegsNum-1];
	integer i;
//    initial begin
//        for(i=0;i<32;i=i+1) Regs[i] = 0;   // 仿真使用，因为仿真中未初始化的reg初值为X (其实可综合)
//    end
	

/****************************************input decode(输入解码)***************************************/
assign {rf_in_re4,rf_in_raddr4,rf_in_re3,rf_in_raddr3,rf_in_re2,rf_in_raddr2,rf_in_re1,rf_in_raddr1} = read_ibus;
assign {rf_in_we2,rf_in_waddr2,rf_in_wdata2,rf_in_we1,rf_in_waddr1,rf_in_wdata1} = write_ibus;
/****************************************output code(输出解码)***************************************/
assign read_obus = {rf_out_rdata4,rf_out_rdata3 ,rf_out_rdata2,rf_out_rdata1};
/*******************************complete logical function (逻辑功能实现)*******************************/

 always @(posedge rf_in_clk) begin
        if(rf_in_rstL==`RstEnable)begin
            for(i=0;i<32;i=i+1) Regs[i] = 32'h0000_0000;
        end else begin//系统正常执行
                if( ( rf_in_we1 == `WriteEnable )&& ( rf_in_waddr1 !=`RegsAddrLen'h0)&&( rf_in_we2 == `WriteEnable )&& ( rf_in_waddr2 !=`RegsAddrLen'h0) )begin//如果写入信号有效且写入的不是$0寄存器
                       if(rf_in_waddr1!=rf_in_waddr2)begin//写地址不相同
                           Regs[rf_in_waddr1] <= rf_in_wdata1;
                           Regs[rf_in_waddr2] <= rf_in_wdata2;
                       end else begin//写地址相同
                           Regs[rf_in_waddr2] <= rf_in_wdata2;
                       end
                end else if (( rf_in_we1 == `WriteEnable )&& ( rf_in_waddr1 !=`RegsAddrLen'h0))begin//只有line1写使能
                    Regs[rf_in_waddr1] <= rf_in_wdata1;
                end else if (( rf_in_we2 == `WriteEnable )&& ( rf_in_waddr2 !=`RegsAddrLen'h0))begin//只有line2写使能
                    Regs[rf_in_waddr2] <= rf_in_wdata2;
                end else begin //没有写
                     for(i=0;i<32;i=i+1) Regs[i] = Regs[i];
                end  
         end
    end
 
 //$$$$$$$$$$$$$$$（1号端口读操作模块）$$0$$$$$$$$$$$$$$$$// 
 always @(*)begin
        if(rf_in_rstL == `RstEnable)begin//复位
            rf_out_rdata1<=`ZeroWord32B;
        end else if(rf_in_raddr1==`RegsAddrLen'h0) begin//如果读入的是$0寄存器
            rf_out_rdata1<=`ZeroWord32B;       
        end else  if( (rf_in_raddr1==rf_in_waddr1)&&(rf_in_we1 == `WriteEnable)&&(rf_in_re1 ==`ReadEnable) )begin //如果写有效，读有效，则读出数据是待写入口的数据
            rf_out_rdata1<=rf_in_wdata1;
        end else  if( (rf_in_raddr1==rf_in_waddr2)&&(rf_in_we2 == `WriteEnable)&&(rf_in_re1 ==`ReadEnable) )begin //如果写有效，读有效，则读出数据是待写入口的数据
            rf_out_rdata1<=rf_in_wdata2;
        end else begin //读
            rf_out_rdata1<=Regs[rf_in_raddr1];
        end                 
 end
//$$$$$$$$$$$$$$$（2号端口读操作模块）$$0$$$$$$$$$$$$$$$$// 
 always @(*)begin
        if( rf_in_rstL == `RstEnable )begin//复位
             rf_out_rdata2<=`ZeroWord32B; 
       end else  if(rf_in_raddr2==`RegsAddrLen'h0)begin//如果读入的是$0寄存器
             rf_out_rdata2<=`ZeroWord32B;
       end else  if( (rf_in_raddr2==rf_in_waddr1)&&(rf_in_we1 == `WriteEnable)&&(rf_in_re2 ==`ReadEnable) )begin//如果写有效，读有效，则读出数据是待写入口的数据
             rf_out_rdata2<=rf_in_wdata1;
       end else  if( (rf_in_raddr2==rf_in_waddr2)&&(rf_in_we2 == `WriteEnable)&&(rf_in_re2 ==`ReadEnable) )begin//如果写有效，读有效，则读出数据是待写入口的数据
             rf_out_rdata2<=rf_in_wdata2;
       end else begin //读
             rf_out_rdata2<=Regs[rf_in_raddr2];
       end
 end
 //$$$$$$$$$$$$$$$（3号端口读操作模块）$$0$$$$$$$$$$$$$$$$// 
 always @(*)begin
        if( rf_in_rstL == `RstEnable )begin//复位
             rf_out_rdata3<=`ZeroWord32B; 
       end else  if(rf_in_raddr3==`RegsAddrLen'h0)begin//如果读入的是$0寄存器
             rf_out_rdata3<=`ZeroWord32B;
       end else  if( (rf_in_raddr3==rf_in_waddr1)&&(rf_in_we1 == `WriteEnable)&&(rf_in_re3 ==`ReadEnable) )begin//如果写有效，读有效，则读出数据是待写入口的数据
             rf_out_rdata3<=rf_in_wdata1;
       end else  if( (rf_in_raddr3==rf_in_waddr2)&&(rf_in_we2 == `WriteEnable)&&(rf_in_re3 ==`ReadEnable) )begin//如果写有效，读有效，则读出数据是待写入口的数据
             rf_out_rdata3<=rf_in_wdata2;
       end else begin //读
             rf_out_rdata3<=Regs[rf_in_raddr3];
       end
 end
 //$$$$$$$$$$$$$$$（4号端口读操作模块）$$0$$$$$$$$$$$$$$$$// 
 always @(*)begin
        if( rf_in_rstL == `RstEnable )begin//复位
             rf_out_rdata4 <=`ZeroWord32B; 
       end else  if(rf_in_raddr4 ==` RegsAddrLen'h0)begin//如果读入的是$0寄存器
             rf_out_rdata4 <=`ZeroWord32B;
       end else  if( (rf_in_raddr4 == rf_in_waddr1)&&(rf_in_we1 == `WriteEnable)&&(rf_in_re4 ==`ReadEnable) )begin//如果写有效，读有效，则读出数据是待写入口的数据
             rf_out_rdata4 <= rf_in_wdata1;
       end else  if( (rf_in_raddr4 == rf_in_waddr2)&&(rf_in_we2 == `WriteEnable)&&(rf_in_re4 ==`ReadEnable) )begin//如果写有效，读有效，则读出数据是待写入口的数据
             rf_out_rdata4<=rf_in_wdata2;
       end else begin //读
             rf_out_rdata4<=Regs[rf_in_raddr4];
       end
 end
   
 
endmodule
 

