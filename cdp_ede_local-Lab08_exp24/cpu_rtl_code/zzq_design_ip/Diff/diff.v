/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：实现7一个队列,这是一个只支持一个写，一个读队列
问题：队列的的关键元素是什么，我需要根据这个这元素设置输入输出
*队尾移动
lunch允许输入
    
lunch:发射了两条指令,则移动两个
lunch:发射了两条空指令,则不移动
lunch:发射了一条指令,则移动一个
队头移动
当前阶段允许输入
输入两条有效指令则队头移动2
输入一条有效指令则队头移动1
输入0条有效指令,则不移动
*/
/*************\
bug:
\*************/
//`include "DefineModuleBus.h"
`include "define.v"
module diff
(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
    //队列写使能
    input wire  [`WbToDiffBusWidth]wb_to_ibus
   
);

/***************************************input variable define(输入变量定义)**************************************/
wire [`LineWbToDiffBusWidth]line2_to_diff_bus,line1_to_diff_bus;
wire                  line1_valid_diff ;                      
wire [`PcWidth]       line1_pc_diff;                
wire [`InstWidth]     line1_inst_diff;            
wire                   line1_regs_we_diff;     
wire [`RegsAddrWidth] line1_regs_waddr_diff;  
wire [`RegsDataWidth] line1_regs_wdata_diff;  

wire                  line2_valid_diff ;        
wire [`PcWidth]       line2_pc_diff;            
wire [`InstWidth]     line2_inst_diff;          
wire                  line2_regs_we_diff;       
wire [`RegsAddrWidth] line2_regs_waddr_diff;    
wire [`RegsDataWidth] line2_regs_wdata_diff;    

/***************************************output variable define(输出变量定义)**************************************/
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/

/****************************************input decode(输入解码)***************************************/
assign {line2_to_diff_bus,line1_to_diff_bus} = wb_to_ibus;
assign {
        line1_regs_we_diff,line1_regs_waddr_diff,line1_regs_wdata_diff,
        line1_inst_diff,line1_pc_diff,line1_valid_diff
        } = line1_to_diff_bus;
 assign {
        line2_regs_we_diff,line2_regs_waddr_diff,line2_regs_wdata_diff,
        line2_inst_diff,line2_pc_diff,line2_valid_diff
        } = line2_to_diff_bus;       
        
        
/****************************************output code(输出解码)***************************************/
/*******************************complete logical function (逻辑功能实现)*******************************/
integer handle_whole,handle_simply;

initial
    begin
        //r方式，被读的文件，用于获取激励信号输入值
       // handle1= $fopen("D:/Documents/Hardware_verlog/Teacher_example/txt/51.txt","r");
        //w方式，被写入的文件，用于写入系统函数的输出值
        if(`record_right_trace)begin
            handle_simply= $fopen(`RIGHT_TRACE_WRITE_FILE,"w");
            handle_whole = $fopen(`Test_TRACE_WRITE_FILE_WHOLE ,"w");
        end else begin
            handle_simply= $fopen(`Test_TRACE_WRITE_FILE,"w");
            handle_whole = $fopen(`Test_TRACE_WRITE_FILE_WHOLE ,"w");
            
        end

end
always @(posedge clk)begin    
    if(`simply_trace_record_open)begin
//        if (line1_regs_we_diff & ~line2_regs_we_diff)begin
////            $display("%h %h %h %h\n", line1_regs_we_diff,line1_pc_diff,line1_regs_waddr_diff,line1_regs_wdata_diff  
              
////                                                                               );
//        end  
        
        if (line1_regs_we_diff&line2_regs_we_diff)begin
            $fwrite(handle_simply,"%h %h %h %h\n%h %h %h %h\n", line1_regs_we_diff,line1_pc_diff,line1_regs_waddr_diff,line1_regs_wdata_diff,
                                                                            line2_regs_we_diff,line2_pc_diff,line2_regs_waddr_diff,line2_regs_wdata_diff
                                                                               );
        end else if (line1_regs_we_diff & ~line2_regs_we_diff)begin
            $fwrite(handle_simply,"%h %h %h %h\n", line1_regs_we_diff,line1_pc_diff,line1_regs_waddr_diff,line1_regs_wdata_diff          
                                                                               );
        end else if (~line1_regs_we_diff & line2_regs_we_diff)begin
            $fwrite(handle_simply,"%h %h %h %h\n",                               
                                                      line2_regs_we_diff,line2_pc_diff,line2_regs_waddr_diff,line2_regs_wdata_diff           
                                                                               );
        end
    end
    
        if(`whole_trace_record_open)begin
             if (line1_valid_diff&line2_valid_diff)begin
                 $fwrite(handle_whole,"%h\t%h\t%h\t%h\t%h\t\n%h\t%h\t%h\t%h\t%h\t\n",line1_pc_diff,line1_inst_diff,
                                                                             line1_regs_we_diff,line1_regs_waddr_diff,line1_regs_wdata_diff,
                                                                             line2_pc_diff,line2_inst_diff,                                
                                                                             line2_regs_we_diff,line2_regs_waddr_diff,line2_regs_wdata_diff
                                                                                );
             end else if (line1_valid_diff & ~line2_valid_diff)begin
                 $fwrite(handle_whole,"%h\t%h\t%h\t%h\t%h\t\n",line1_pc_diff,line1_inst_diff,
                                                           line1_regs_we_diff,line1_regs_waddr_diff,line1_regs_wdata_diff           
                                                                                    );
             end else if (~line1_valid_diff & line2_valid_diff)begin
                 $fwrite(handle_whole,"%h\t%h\t%h\t%h\t%h\t\n",line2_pc_diff,line2_inst_diff,                                
                                                           line2_regs_we_diff,line2_regs_waddr_diff,line2_regs_wdata_diff           
                                                                                    );
             end
        end 
  
    
       
end

endmodule
























