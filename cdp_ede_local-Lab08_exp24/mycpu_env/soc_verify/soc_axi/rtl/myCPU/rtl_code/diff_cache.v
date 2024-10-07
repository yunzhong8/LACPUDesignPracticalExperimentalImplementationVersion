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
module diff_cache
(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
    output wire error_o,
    input wire re_i,
    input wire [31:0]rram_addr_i,
    input wire [3:0]cs_i,
  
    //队列写使能
    input wire  cs_eq_writeback    ,
    input wire [31:0]writeback_waddr,
    input wire [127:0]writeback_wdata,
    
     
    input wire diff_cache_en_i                               ,
    input wire [`CacheIndexWidth] diff_cache_rindex_i       ,
    input wire [31:0]diff_cache_raddr_i,
    input wire [299:0] diff_cache_rdata_i                     ,
    input wire diff_cache_wway_i                             ,
    input wire [`CacheIndexWidth]diff_cache_w_index_i        ,
    input wire [1:0]diff_cache_wtype_i                       ,
    input wire [3:0]diff_search_offset_i                     ,
    input wire [149:0]diff_cache_wdata_i 
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
   
);

/***************************************input variable define(输入变量定义)**************************************/

   wire [127:0] w_data  ,way0_rdata ,way1_rdata               ;//写回的128bit数据
   wire [19:0]  w_tag ,wb_tag ;
   wire [3:0]wb_offset;
   wire [7:0]wb_index;
   assign {wb_tag,wb_index,wb_offset} = writeback_waddr;
   wire [20:0]way0_tagv_rdata,  way1_tagv_rdata             ;
   wire         w_v     ,way0_v  ,way1_v                ;
   wire         w_d     ,way0_d  ,way1_d              ;  
   wire [149:0]        cache_way0_rdata,cache_way1_rdata;

/***************************************output variable define(输出变量定义)**************************************/
/***************************************parameter define(常量定义)**************************************/
assign {{w_v,w_tag},w_data,w_d} =diff_cache_wdata_i;
assign {cache_way1_rdata,cache_way0_rdata} = diff_cache_rdata_i;
assign {way0_d,way0_tagv_rdata,way0_rdata} =cache_way0_rdata;
assign {way1_d,way1_tagv_rdata,way1_rdata} =cache_way1_rdata;
/***************************************inner variable define(内部变量定义)**************************************/

/****************************************input decode(输入解码)***************************************/
    
        
        
/****************************************output code(输出解码)***************************************/
wire error;
assign error = 1'b0;
//assign error = cs_eq_writeback&writeback_waddr==32'h1c002150;
reg [7:0]count;
always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        count<=0;
    end 
    else if(error|count!=0)begin
        count<=count+1;
    end 
end 
assign error_o = count==8'hff;
//assign error_o = line1_diff_load_en_i&line1_diff_ls_vaddr_i==32'h1c00215c;
/*******************************complete logical function (逻辑功能实现)*******************************/
integer handle_whole;

initial
    begin
        //r方式，被读的文件，用于获取激励信号输入值
       // handle1= $fopen("D:/Documents/Hardware_verlog/Teacher_example/txt/51.txt","r");
        //w方式，被写入的文件，用于写入系统函数的输出值
       
            handle_whole = $fopen(`Test_TRACE_WRITE_FILE_WHOLE_CACHE ,"w");
            
       
end
reg count_r;
always@ (posedge clk)begin
        if(rst_n == `RstEnable)begin
            count_r<=1'b0;
        end else if(diff_cache_en_i&diff_cache_wtype_i==2'b00)begin
            count_r<=1'b1;
        end else begin
            count_r<=1'b0;
        end 
end 

always @(posedge clk)begin    
        if(`dcache_trace_record_open)begin
            if(diff_cache_en_i&diff_cache_wtype_i==2'b00&&cs_i!=4'b0100)begin
//                $fwrite(handle_whole,"读cache查找表: 读地址：%h\t  way0_d：%h\t  way0_v：%h\t way0_tag：%h\t way0_rdata:%h\t\n",diff_cache_rindex_i,way0_d,way0_tagv_rdata[20],way0_tagv_rdata[19:0],way0_rdata);
//                $fwrite(handle_whole,"\t\t\tway1_d：%h\t  way1_v：%h\t way1_tagv：%h\t   way1_rdata:%h\t\n",way1_d,way1_tagv_rdata[20],way1_tagv_rdata[19:0],way1_rdata);
            end else if(diff_cache_en_i&diff_cache_wtype_i==2'b01)begin
                $fwrite(handle_whole,$time,"部分写cache查找表:写入wayid:%h\t 写入行地址：%h\t写入字地址：%h\t  写入数据：%h\t 脏位：%h\t\n\n\n",diff_cache_wway_i,diff_cache_w_index_i,diff_search_offset_i,w_data[32:0],w_d);
            end else if(diff_cache_en_i&diff_cache_wtype_i==2'b10)begin
//                $fwrite(handle_whole,"全写cache查找表:写入wayid:%h\t  写入行地址：%h\t 写入字地址：%h\t 写入数据有效位：%h\t 写入数据页号：%h\t 写入128位数据：%h\t 脏位：%h\t\n\n\n",diff_cache_wway_i,diff_cache_w_index_i,diff_search_offset_i,w_v,w_tag,w_data,w_d);//7
            end 
            if(count_r)begin
//                 $fwrite(handle_whole,"读cache查找表:完整地址：%h\t \n\n\n",diff_cache_raddr_i);
            end 
    
//            if(`whole_trace_record_open)begin
//                  if(re_i)begin
//                     $fwrite(handle_whole,"读入的cache块:%h\t\n",rram_addr_i);
////                     $display("重置例外状态:%h\t%h\t\n",writeback_waddr,writeback_wdata);
//                 end
                 
                 if(cs_eq_writeback)begin
                     $fwrite(handle_whole,"替换出去的cache块:替换出的页号：%h\t 替换出的行号：%h\t 替换出的字地址：%h\t %h\t\n\n\n",wb_tag,wb_index,wb_offset,writeback_wdata);
//                     $display("重置例外状态:%h\t%h\t\n",writeback_waddr,writeback_wdata);
                 end
            
         end
  
     
       
end

endmodule
























