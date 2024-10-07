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
`include "DefineModuleBus.h"
module Queue
#(parameter DataLen= 31)
(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
    //队列写使能
    input wire  we_i,
    //队列写数据
    input wire  [DataLen:0]wdata_i,
    //队列读出数据被使用完了
    input wire  used_i,
    //队列满信号
    output wire full_o,
    //队列读数据
    output wire [DataLen:0]rdata_o,
    output wire rdata_valid_o 
   
);

/***************************************input variable define(输入变量定义)**************************************/
/***************************************output variable define(输出变量定义)**************************************/
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//队列空间设置为8
reg [DataLen:0] data_queue[7:0];
reg valid_queue[7:0];
reg [2:0]queue_head;
reg [2:0]queue_tail;

/****************************************input decode(输入解码)***************************************/
/****************************************output code(输出解码)***************************************/
/*******************************complete logical function (逻辑功能实现)*******************************/
//队头
//上级流水输入一次写对头就+1
//当前队列允许输入
//规定前一级发过来的数据,如果有效则line1必定有效,line2不清楚
always@(posedge clk)begin
    if(rst_n == `RstEnable)begin
        queue_head<=4'd0;
    end else if(we_i)begin 
        queue_head <= queue_head +4'd1;
    end else begin
        queue_head <= queue_head;
    end
end

//队尾
//如果组合逻辑allowin则队尾部移动2个
//如果是当发射则队尾移动一个单位
always@(posedge clk)begin
    if(rst_n == `RstEnable)begin
        queue_tail<=4'd0;   
    end else if(used_i)begin 
        queue_tail <= queue_tail +4'd1;
    end else begin
        queue_tail <= queue_tail;
    end
end
//队列
//如果冲刷信号来的时候,队列数据全部无效,队列valid也全部无效
generate 
    genvar i ;
    for(i=0;i<8;i=i+1) begin : data_loop
        always@(posedge clk)begin
            if(rst_n == `RstEnable)begin
                data_queue[i]<= 0;
            end else if(i==queue_head & we_i)begin 
                data_queue[i]  <=wdata_i;
            end else if(used_i & i==queue_tail)begin
                 data_queue[i]  <=0;
            end else begin
                data_queue[i] <= data_queue[i];
            end
        end
        
        always@(posedge clk)begin
            if(rst_n == `RstEnable )begin
                valid_queue[i]<= 1'd0;
            end else if(i==queue_head &we_i)begin  
                valid_queue[i]  <= 1'b1;
               //清空尾指令输出过的数据
            end else if(used_i & i==queue_tail)begin
                valid_queue[i]  <= 1'b0;
            end else begin
                valid_queue[i] <= valid_queue[i];
            end
        end 
  end 
endgenerate 
assign rdata_valid_o = valid_queue[queue_tail];
assign  rdata_o      = data_queue[queue_tail];
//两种情况
assign full_o = (queue_tail+1 == queue_head) ? 1'b0:1'b1;

endmodule
