/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
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
bug: 如果使用了位宽进行阶段，应该避免这种情况 [2:0]i=[2:0]j+1,因为[2:0]j+1的位宽实际是[3:0]
bug: 循环队列的空和满太难判断了，我还是队列长度进行判断吧，因为我的出队和入队的长度是不固定的
bug:队列允许输入判断错误，应该设设置成<队长最大值-2是允许输入
\*************/
//`include "DefineModuleBus.h"
`include "define.v"
module IF_ID(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
     //控制本阶段id组合逻辑运算完的数据是否可以锁存起来，供给exe使用
    input wire line1_pre_to_now_valid_i,//if_id输出的表示，if阶段的数据可以输出到id阶段
    input wire line2_pre_to_now_valid_i,//if_id输出的表示，if阶段的数据可以输出到id阶段
    //id阶段的状态机
    input wire now_allowin_i,//id组合逻辑传入，表示id阶段当前数据已经运算完了
    //
    output wire error_o,
    
    output wire allowin_o,
    output wire line1_now_valid_o,//输出下一个状态
    output wire line2_now_valid_o,
    //冲刷信号
    input wire branch_flush_i,//冲刷流水信号
    input wire excep_flush_i,
    //发射暂停信号
    input wire double_valid_inst_lunch_flag_i ,
    input wire single_valid_inst_lunch_flag_i ,
    input wire zero_valid_inst_lunch_flag_i   ,
    
    
    
    
    
    //数据域
    input  wire  [`IdToNextBusWidth] pre_to_ibus,
    
    output wire  [`IdToNextBusWidth]to_id_obus         
);

/***************************************input variable define(输入变量定义)**************************************/
/***************************************output variable define(输出变量定义)**************************************/
/***************************************parameter define(常量定义)**************************************/






/***************************************inner variable define(内部变量定义)**************************************/
//队列空间设置为8
reg [`LineIdToNextBusWidth] inst_data_queue[`LAUNCH_QUEUE_WIDTEH];
reg inst_valid_queue[`LAUNCH_QUEUE_WIDTEH];
reg [`LAUNCH_QUEUE_POINTER_WIDTEH]queue_head;
reg [`LAUNCH_QUEUE_POINTER_WIDTEH]queue_tail;

reg  [`LAUNCH_QUEUE_LEN_WIDTH]queue_len;//15
wire [`LAUNCH_QUEUE_LEN_WIDTH]next_queue_len;
wire [`LAUNCH_QUEUE_LEN_WIDTH]next_sub_queue_len;
wire [`LAUNCH_QUEUE_LEN_WIDTH]next_add_sub_queue_len;
wire [`LAUNCH_QUEUE_LEN_WIDTH]queue_len_add_tow,queue_len_add_one,queue_len_sub_tow,queue_len_sub_one;

wire double_write;
wire signle_write;
wire zero_write;
assign double_write = line1_pre_to_now_valid_i&line2_pre_to_now_valid_i;
assign signle_write = (line1_pre_to_now_valid_i&~line2_pre_to_now_valid_i)|(~line1_pre_to_now_valid_i&line2_pre_to_now_valid_i);
assign zero_write = ~line1_pre_to_now_valid_i&~line2_pre_to_now_valid_i;

/***************************************inner variable define(错误状态)**************************************/

wire error;

              
assign error = queue_len>`LAUNCH_QUEUE_LEN;

assign error_o =error;
/****************************************input decode(输入解码)***************************************/
/****************************************output code(输出解码)***************************************/
/*******************************complete logical function (逻辑功能实现)*******************************/
//队头
//上级流水输入一次写对头就+1
//当前队列允许输入
//规定前一级发过来的数据,如果有效则line1必定有效,line2不清楚
always@(posedge clk)begin
    if(rst_n == `RstEnable||excep_flush_i|| branch_flush_i)begin
        queue_head<=`LAUNCH_QUEUE_POINTER_LEN'd0;
    end else if(line2_pre_to_now_valid_i&line1_pre_to_now_valid_i&allowin_o)begin
        queue_head <= queue_head +`LAUNCH_QUEUE_POINTER_LEN'd2;
    end else if(line1_pre_to_now_valid_i&allowin_o)begin 
        queue_head <= queue_head +`LAUNCH_QUEUE_POINTER_LEN'd1;
    end else begin
        queue_head <= queue_head;
    end
end

//队尾
//如果组合逻辑allowin则队尾部移动2个
//如果是当发射则队尾移动一个单位
always@(posedge clk)begin
    if(rst_n == `RstEnable||excep_flush_i|| branch_flush_i)begin
        queue_tail<=`LAUNCH_QUEUE_POINTER_LEN'd0;   
    end else if(single_valid_inst_lunch_flag_i)begin 
        queue_tail <= queue_tail +`LAUNCH_QUEUE_POINTER_LEN'd1;
    end else if(double_valid_inst_lunch_flag_i)begin
        queue_tail <= queue_tail +`LAUNCH_QUEUE_POINTER_LEN'd2;
    end else begin
        queue_tail <= queue_tail;
    end
end
//队列
//如果冲刷信号来的时候,队列数据全部无效,队列valid也全部无效
wire [`LAUNCH_QUEUE_POINTER_WIDTEH]wirte_addr1= queue_head;//line1的取指写入
wire [`LAUNCH_QUEUE_POINTER_WIDTEH]wirte_addr2= queue_head+1;//line2的取指写入
wire [`LAUNCH_QUEUE_POINTER_WIDTEH]clear_addr1 = queue_tail;//line1的清理
wire [`LAUNCH_QUEUE_POINTER_WIDTEH]clear_addr2 = queue_tail+1;//line2的清理

wire [`LAUNCH_QUEUE_POINTER_WIDTEH]launch_addr1;//line1的发射地址
wire [`LAUNCH_QUEUE_POINTER_WIDTEH]launch_addr2;//line2的发射地址
generate 
    genvar i ;
    for(i=0;i<`LAUNCH_QUEUE_LEN;i=i+1) begin : data_loop
        always@(posedge clk)begin
            if(rst_n == `RstEnable||excep_flush_i|| branch_flush_i)begin
                inst_data_queue[i]<=`LineIdToNextBusLen'd0;
            end else if(i==wirte_addr1 && line1_pre_to_now_valid_i && allowin_o)begin 
               inst_data_queue[i]  <=pre_to_ibus[`LineIdToNextBusWidth];
            end else if(i==wirte_addr2 &&line2_pre_to_now_valid_i && allowin_o)begin 
               inst_data_queue[i]<=pre_to_ibus[`IdToNextBusLen-1 :`LineIdToNextBusLen];
            end else begin
                inst_data_queue[i] <= inst_data_queue[i];
            end
        end
        
        always@(posedge clk)begin
            if(rst_n == `RstEnable ||excep_flush_i|| branch_flush_i)begin
                inst_valid_queue[i]<= 1'd0;
            end else if(i==wirte_addr1 && line1_pre_to_now_valid_i && allowin_o)begin  
               inst_valid_queue[i]  <= line1_pre_to_now_valid_i;
            end else if(line2_pre_to_now_valid_i && allowin_o&&i==wirte_addr2)begin 
               inst_valid_queue[i]  <= line2_pre_to_now_valid_i;
               //清空尾指令输出过的数据
            end else if((single_valid_inst_lunch_flag_i|double_valid_inst_lunch_flag_i) && i==clear_addr1)begin
                inst_valid_queue[i]  <= 1'b0;
             end else if(double_valid_inst_lunch_flag_i && i==clear_addr2)begin
                inst_valid_queue[i]  <= 1'b0;
            end else begin
                inst_valid_queue[i] <= inst_valid_queue[i];
            end
        end 
  end 
endgenerate 
assign launch_addr1 = queue_tail;
assign launch_addr2 = queue_tail + `LAUNCH_QUEUE_POINTER_LEN'd1;
assign to_id_obus        = {inst_data_queue[ launch_addr2],inst_data_queue[launch_addr1]};
assign line1_now_valid_o = inst_valid_queue[launch_addr1];
assign line2_now_valid_o = `DOUBLE_LAUNCH ? inst_valid_queue[launch_addr2] : 1'b0;//(单双发射)
//assign line2_now_valid_o = 1'b0;//单发射

//两种情况
//当前队列还要两个空空间
//当前空间<2个,但是同时收到了组合的allowin
//收到组合的lunch_stall是不允许的,因为可能上一级发过来两个数据
//assign allowin_o = (queue_tail+2 == queue_head) ? (double_valid_inst_lunch_flag_i ? 1'b1:1'b0) :1'b1;
//assign wirte_state = line1_pre_to_now_valid_i &line2_pre_to_now_valid_i?2'b10:line1_pre_to_now_valid_i &line2_pre_to_now_valid_i
assign queue_len_add_tow=queue_len+`LAUNCH_QUEUE_POINTER_LEN'd2;
assign queue_len_add_one=queue_len+`LAUNCH_QUEUE_POINTER_LEN'd1;
assign queue_len_sub_tow=queue_len-`LAUNCH_QUEUE_POINTER_LEN'd2;
assign queue_len_sub_one=queue_len-`LAUNCH_QUEUE_POINTER_LEN'd1;

//加减后的长度
assign next_add_sub_queue_len = double_write ? (double_valid_inst_lunch_flag_i   ? queue_len :
                                         single_valid_inst_lunch_flag_i  ? queue_len_add_one:queue_len_add_tow):
                        signle_write ? (double_valid_inst_lunch_flag_i   ? queue_len_sub_one :
                                         single_valid_inst_lunch_flag_i   ? queue_len:queue_len_add_one):    
                                       (double_valid_inst_lunch_flag_i   ? queue_len_sub_tow :
                                         single_valid_inst_lunch_flag_i  ? queue_len_sub_one:queue_len);   
//只有减的长度
assign next_sub_queue_len =   double_valid_inst_lunch_flag_i ?    queue_len_sub_tow  :
                               single_valid_inst_lunch_flag_i ?  queue_len_sub_one :queue_len;
                               
//如果允许上级写入则用加减后的结果，不允许只能减                               
assign next_queue_len = allowin_o ?  next_add_sub_queue_len :next_sub_queue_len;
always@(posedge clk)begin
    if(rst_n == `RstEnable||excep_flush_i|| branch_flush_i)begin
        queue_len<=`LAUNCH_QUEUE_LEN_LEN'd0;
   end else begin
         queue_len<=next_queue_len;
   end      
end
//assign allowin_o =  next_add_sub_queue_len >4'd8 ? 1'b0 : 1'b1;
//当前buffer容量:为7/8时，会出现，下级没发射，上级输入了两条，导致buffer溢出
assign allowin_o =  queue_len >`LAUNCH_QUEUE_ALLOWIN_CRITICAL_VALUE ? 1'b0 : 1'b1;

endmodule
