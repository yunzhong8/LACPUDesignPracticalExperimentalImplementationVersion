`timescale 1ns / 1ps
/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：实现的是一个2路组相联的cache,
*每一路的大小4KB
*使用的是随机替换的路策略
*读命中:需要两个时钟周期读出数据
*读未命中:需要至少5个时钟周期,最多:9个时钟周期
*写命中:2个时钟周期,(3实际使用了3个时钟周期),只是第3个时钟周期如果不是访存指令是不会阻塞CPU流水线的
*写未命中:2个时钟周期(实际使用最多时钟周期),只是在2~9过程中如果不出现访存指令是不会阻塞CPU流水
*规定:写外部aix的时候,部分写的时候,写的数据在w_data[31:0]位
*/
/*************\
bug:search_buffer
//uncache访问外界的是:访问外界的offset是查找地址的offset,cache部分要会回填,访问地址的offset=4'd0(改了load,忘记改store)
//miss状态,store uncache是要等外界允许写才能跳转到writeback,load不用等
//出现了store指令发出data_ok,下一个状态不是ridle的情况
//store采用了store_buffer的方式,则store指令进行写的时候,采用的应该是替换的miss_way_id,我用成默认0

responde信号只用响应，不能用于判断下一个状态，因为有第二阶段指令也可以响应，无第二阶段的指令也可以响应，是无法区分的，
应该用finish信号+当前是否有第二阶段的指令
\*************/
//写会外部需要检测当前是否是脏数据，我没检查，只要miss就写回
//设备地址只返回一次valid,导致错误
//实现
//`include "DefineModuleBus.h"
`include "define.v"
`include "temp_cache_sign.v"
module temp_cache(
 input  wire                         clk                ,
 input  wire                         resetn             ,
 input  wire                         valid_i              ,//访问请求信号req，1表示有请求
 input  wire                         op_i                 ,//访问类型，0：req,1:write,we信号
 input  wire [`CacheOffsetWidth]     offset_i             ,//pc[3:0]
 input  wire [`CacheIndexWidth]      index_i             ,//pc[11:4]
 input  wire [`CacheTagWidth]        tag_i                ,//p_pc[31:12]
 
 //cache维护指令
 input                               cacop_req_i,           
 input  [ 1:0]                       cacop_op_mode_i         ,  
 input  [ 7:0]                       cacop_op_addr_index_i   , //this signal from mem stage's va
 input  [19:0]                       cacop_op_addr_tag_i     , 
 input  [ 3:0]                       cacop_op_addr_offset_i  ,
 
 
 input  wire                         uncache_i          ,
 input  wire                         store_buffer_to_cache_or_ram_we_i  ,//表示将store中的值写入cache中
 input  wire                         clear_store_buffer_en_i  ,//表示清空store_buffe
 input  wire                         handling_access_cancle_i,
 input  wire                         cpu_mmu_finish_i,//表示在mmu那一级的指令可以流往译码级啦

 input  wire [`CacheWstrbWidth]      store_wstrb_i              ,//写字节使能
 input  wire [31:0]                  store_wdata_i              ,//cache写数据
                                                    
 output wire                         addr_ok_o            ,//输出已经接收地址ok
 output wire                         data_ok_o            ,//输出数据准备好啦
                                                        
 output wire                         axi_rd_req_o             ,//输出类AXI读请求
 output wire [2:0]                   axi_rd_type_o            ,//输出类AXI读请求类型
 output wire [31:0]                  axi_rd_addr_o            ,//输出类AXI读请求的起始地址
 input  wire                         axi_rd_rdy_i             ,//AXI转接桥输入可以读啦，read_ready
 
 input  wire                         axi_ret_valid_i           ,//axi转接桥输入读回数据read_data_valid
 input  wire                         axi_ret_last_i           ,//axi转接桥输入这是最后一个读回数据，为什么是两位的？？？？
 input  wire [31:0]                  axi_ret_data_i           ,//axi转接桥输入的读回数据
                                                        
 output wire                         axi_wr_req_o             ,//类AXI输出的写请求
 output wire [2:0]                   axi_wr_type_o            ,//类AXI输出的写请求类型
 output wire [31:0]                  axi_wr_addr_o            ,//类AXI输出的写地址
 output wire [3:0]                   axi_wr_wstrb_o           ,//写操作掩码
 output wire  [`CacheBurstDataWidth] axi_wr_data_o            ,//类AXI输出的写数据128bit       
 input  wire                         axi_wr_rdy_i             ,//AXI总线输入的写完成信号，可以接收写请求 
 
 //cache报错信息
 output wire     [`CacheDisposeInstNumWidth] wait_dispose_inst_num_o             ,
 output wire                       error_o,
 
 output wire                        cache_free_o             ,
 output wire      [3:0]             cs_o                     ,          
 output wire                        uncache_en_buffer_o      ,          
 output wire     [31:0]             search_addr_buffer_o     ,          
 output wire     [31:0]             exrt_axi_rdata_buffer0_o ,          
 output wire     [31:0]             exrt_axi_rdata_buffer1_o ,          
 output wire     [31:0]             exrt_axi_rdata_buffer2_o ,          
 output wire     [31:0]             exrt_axi_rdata_buffer3_o ,          
 output wire                        way0_cache_hit_o         ,          
 output wire                        way1_cache_hit_o         ,          
 output wire     [299:0]            search_buffer_o           ,          
 
 
 //差分测试端口
 output wire diff_cache_en_o                               ,
 output wire [`CacheIndexWidth] diff_cache_rindex_o        ,
 output wire [31:0]diff_cache_raddr_o,
 output wire [299:0] diff_cache_rdata_o                     ,
 output wire diff_cache_wway_o                             ,
 output wire [`CacheIndexWidth]diff_cache_w_index_o        ,
 output wire [1:0]diff_cache_wtype_o                       ,
 output wire [3:0]diff_search_offset_o                     ,
 output wire [149:0]diff_cache_wdata_o                      
 
                     
    );
    /***************************************input variable define(输入变量定义)**************************************/
  /***************************************output variable define(输出变量定义)**************************************/
//   wire [`CacheTagWidth]      wr_addr_tag_o   ;//cache写外部axi的标记字段p_pc[31:12]
//   wire [`CacheIndexWidth]    wr_addr_index_o ;//pc[11:4]
//   wire [`CacheOffsetWidth]   wr_addr_offset_o;//p_pc[31:12] 
//   wire [`CacheOffsetWidth]   rd_addr_offset_o;
  
  
  /***************************************parameter define(常量定义)**************************************/  
  parameter RIDLE      = 4'b0000;//0
  parameter READ       = 4'b0001;//1
  parameter LOOKUP     = 4'b0010;//2
  parameter WRITE      = 4'b0011;//3
  parameter MISS       = 4'b0100;//4
  parameter WRITEBACK  = 4'b0101;//5
  parameter REPLACE    = 4'b0110;//6
  parameter REFILL     = 4'b0111;//7
 
  parameter WRITEBLOCK = 4'b1000;//8写完要阻塞一个时钟周期才允许读      
  reg [3:0] r_cs;
  wire[3:0] r_ns;
  
  
   
  /***************************************inner variable define(内部变量定义)**************************************/ 
  //CPU输入缓存变量信息
     //缓存访问的第一部分信息
     wire       cpu_request_part1_queue_we;
     wire [15:0] cpu_request_part1_queue_wdata;
     wire [11:0]cpu_request_index_offest;
     
     //缓存访问的第2部分信息
     wire cpu_request_part2_queue_we;
     wire [21:0]cpu_request_part2_queue_wdata;
     wire [19:0]cpu_req_tag;
     
     
     //store指令缓存数据
      wire store_buffer_queue_we;
      wire [35:0]store_buffer_queue_wdata;
      wire store_buffer_queue_valid;
  //cache查找结果输出缓存
      wire cache_table_read_queue_we;//将cache table的读出数据写入queue
      wire [299:0]cache_table_read_queue_wdata;
      wire [299:0]cache_table_read_queue_rdata;
      wire cache_table_read_queue_valid;
      wire [149:0]cache_table_read_queue_rdata_way1,cache_table_read_queue_rdata_way0;
      wire handling_req_cache_rdata_dirty;
  //AXI输入缓存
     wire        axi_write_count_we      ; 
     reg  [1:0]  axi_write_count         ;//4个字 
     reg  [31:0] exrt_axi_rdata_buffer0,exrt_axi_rdata_buffer1,exrt_axi_rdata_buffer2,exrt_axi_rdata_buffer3;
     
  //cache接收到的请求
     wire cache_re    ; 
     wire cache_we    ;
     wire cache_coe   ;
     wire no_cache_req;
  
    
  
  //cache正在处理的访问请求的属性信息
    //cache维护指令信息
    wire handling_cacop_en;//当前正在处理cache维护指令
    wire [1:0]handling_cacop_op_mode;//当前处理的cache维护指令类型
    
    //基本信息
    wire handling_store_access;//当前正常处理store访问
    wire [31:0]handling_access_addr;//当前处理的访问地址
    wire handling_valid;
    
    wire handling_uncache;//当前处理的指令是cache属性
    
    //sotre信息
    wire [31:0]handling_store_wdata;
    wire [3:0]handling_store_wstrb;
    
    wire handling_req_finish;
    
  //cPU等待处理的请求
    wire having_stage_two_req;
    wire no_stage_two_req;
    wire having_store_stage_two_req;
    wire having_unstore_stage_two_req;
    wire stage_two_can_to_three;
    wire stage_two_cant_to_three;
  //cache处理的信号
    
    
    
     //CacheTable需要的变量
     
       wire cache_table_en;//cache查找表使能
     
       wire [7:0]cache_table_rindex;//cache查找表读地址
       wire [299:0] cache_table_rdata   ;//cache查找表读出数据
       
       wire [1:0]cache_table_wtype; //cache查找表写类型
       
        wire         cache_table_wway;//cache查找表的写way
       wire     [7:0]    cache_table_windex  ;//cache查找表的写行地址
       wire [3:0]cache_table_woffset;//cache查找表的写字地址
       wire [3:0] cache_table_wstr;//cache字节写使能
       
       //cache查找表存入的数据
       wire [19:0]  cache_table_wtag      ;//cache查找表的写tag
       wire         cache_table_wv                    ;
       wire         cache_table_wd                    ; 
       wire [31:0]  cache_table_wdata0                ;
       wire [127:0] cache_table_wdata                 ;//写回的128bit数据    
       wire [149:0] cache_table_wdatabus            ;//cache待写回数据(只写一路的，所以是150)
      
     
      
      wire axi_write_count_ce;
    
  
    
 /***************************************inner variable define(内部变量定义)**************************************/
    wire rcs_eq_ridle     ;    
    wire rcs_eq_read      ;    
    wire rcs_eq_lookup    ;    
    wire rcs_eq_miss      ;    
    wire rcs_eq_write     ;    
    wire rcs_eq_writeback ;    
    wire rcs_eq_replace   ;    
    wire rcs_eq_refill    ;    
    wire rcs_eq_writeblock;
    
    wire  [3:0]cs_eq_ridle_ns  ,
               cs_eq_read_ns      ,
               cs_eq_lookup_ns    ,
               cs_eq_miss_ns      ,
               cs_eq_write_ns     ,
               cs_eq_writeback_ns ,
               cs_eq_replace_ns   ,
               cs_eq_refill_ns    ,
               cs_eq_writeblock_ns ;
    
     
    
    //ridle
        wire ridle_handling_store_uncache,ridle_handling_store_cache;
        //响应ridle_can_respone_cacop_mode_zero
         wire ridle_can_respone_cacop_mode_zero,ridle_can_respone_cacop_mode_one,ridle_can_respone_cacop_mode_two;
         wire ridle_can_respone_ls;
         wire ridle_respone_load,ridle_respone_store;
   
    
    //read
    //响应
     wire read_can_respone_ls;
     wire read_respone_load,read_respone_store;
    
    //lookup阶段处理的指令类型
        wire lookup_handling_load_req_cancle,lookup_handling_store_req_cancle,lookup_handling_cacop_model_two_cancle;
        wire lookup_handling_load_req_uncache,lookup_handling_load_req_cache_hit,lookup_handling_load_req_cache_unhit;
        wire lookup_handling_cacop_model_two_no_hit,lookup_handling_cacop_model_two_hit;
        wire lookup_handling_store_req_uncache,lookup_handling_store_req_cache_hit,lookup_handling_store_req_cache_unhit;
    
    //响应
        wire lookup_no_write_cache_req_finish;
        wire lookup_can_respone_ls;
        wire lookup_respone_load,lookup_respone_store;
    
   
    //miis阶段处理的指令类型
        wire miss_handling_load_req_cache_unhit;
        wire miss_handling_cacop_model_two_hit;
        wire miss_handling_store_req_uncache,miss_handling_store_req_cache_unhit;
        
        
    
    //writeback处理指令类型
        wire wbe_handling_load_req_cache_unhit_dirty,wbe_handling_load_req_cache_unhit_undirty;
        wire wbe_handling_cacop_model_two_hit_dirty, wbe_handling_cacop_model_two_hit_undirty ;
        wire wbe_handling_store_req_uncache,wbe_handling_store_req_cache_unhit_dirty,wbe_handling_store_req_cache_unhit_undirty;
        
        //响应
        wire wbe_can_respone_ls;    
        wire wbe_respone_load,wbe_respone_store;
    
    
    
    //replace
        wire replace_handling_load_req_uncache, replace_handling_load_req_cache_unhit;
        wire replace_handling_store_req_cache_unhit;
    //refill
        wire refill_handling_load_req_uncache, refill_handling_load_req_cache_unhit;
        wire refill_handling_store_req_cache_unhit;
    
    //write_back_cache
    //处理指令
        wire wbc_handling_load_req_uncache, wbc_handling_load_req_cache_unhit;
        wire wbc_handling_store_req_cache_unhit;
        wire wbc_cacop_model_zero,wbc_cacop_model_one,wbc_cacop_model_two;
        
        //响应
        wire wbc_can_respone_ls;
        wire wbc_respone_load,wbc_respone_store;
    
    
    //write
        wire write_handling_store_req_cache;
        
       
    
   
    wire [`CacheTagWidth]         cache_rdata_way0_tag, cache_rdata_way1_tag;
    wire cache_rdata_way0_valid,cache_rdata_way1_valid;
   
 
     /***************************************inner variable define(错误状态)**************************************/

   wire error1,error2;
   wire stage_one_en ;
   wire stage_two_en;
   wire stage_three_en;
   reg[`CacheDisposeInstNumWidth] inst_num;
   always @(posedge clk)begin
        if(resetn == 1'b0)begin
            inst_num<=`CacheDisposeInstNumLen'b0;
        end else if(addr_ok_o&~data_ok_o)begin
            inst_num <= inst_num+`CacheDisposeInstNumLen'b1;
        end else if(addr_ok_o&data_ok_o)begin
            inst_num <= inst_num;
        end else if(~addr_ok_o&data_ok_o)begin
            inst_num <= inst_num-`CacheDisposeInstNumLen'b1;
        end else begin
            inst_num <= inst_num;
        end
   end
   

 
 //idle阶段不可能存在访问请求的data_ok没有发出去（即当前要处理的指令数不等于0）              
    assign error1 = rcs_eq_ridle & inst_num!=0 ;

//cache所能处理的指令数最大不超过2
    assign error2 =  inst_num>2; 
   
   
 assign error_o = error1|error2;  
 /***************************************inner variable define(逻辑实现)**************************************/   
 
    assign cache_re     = ~cacop_req_i&valid_i&~op_i;
    assign cache_we     = ~cacop_req_i&valid_i&op_i;
    assign cache_coe    = cacop_req_i;
    assign no_cache_req = ~cacop_req_i& ~valid_i; 
    
      //当前有阶段的指令 当前时钟要往cache_read_buffer写入数据
    //当前时钟cache_read_buffer非空
    assign  no_stage_two_req = ~(rcs_eq_lookup&cache_table_read_queue_we)&~(~rcs_eq_lookup&cache_table_read_queue_valid);
    assign having_stage_two_req = (rcs_eq_lookup&cache_table_read_queue_we)|(~rcs_eq_lookup&cache_table_read_queue_valid);
    //当storebuffer非空的时候说明这个阶段2的请求是store
    assign having_store_stage_two_req    = having_stage_two_req&store_buffer_queue_valid;
    assign having_unstore_stage_two_req  = having_stage_two_req&~store_buffer_queue_valid;
    assign stage_two_can_to_three        = having_stage_two_req&cpu_mmu_finish_i;
    assign stage_two_cant_to_three       = having_stage_two_req&~cpu_mmu_finish_i;
    
    
    assign cache_rdata_way0_tag   = cache_table_read_queue_rdata_way0[`Way0TagLocation];
    assign cache_rdata_way1_tag   = cache_table_read_queue_rdata_way1[`Way0TagLocation];
    assign cache_rdata_way0_valid = cache_table_read_queue_rdata_way0[`Way0VLocation];
    assign cache_rdata_way1_valid = cache_table_read_queue_rdata_way1[`Way0VLocation];
    assign cache_rdata_way0_dirty = cache_table_read_queue_rdata_way0[`Way0DLocation];
    assign cache_rdata_way1_dirty = cache_table_read_queue_rdata_way1[`Way0DLocation];
    
    assign way0_cache_hit =   cpu_req_tag == cache_rdata_way0_tag && cache_rdata_way0_valid;
    assign way1_cache_hit =   cpu_req_tag == cache_rdata_way1_tag && cache_rdata_way1_valid;
    assign cache_hit = way0_cache_hit|way1_cache_hit;
  
  
 
  /***************************************inner variable define(状态执行的指令)**************************************/   
   assign rcs_eq_ridle      = r_cs==RIDLE      ;
   assign rcs_eq_read       = r_cs==READ       ; 
   assign rcs_eq_lookup     = r_cs==LOOKUP     ;
   assign rcs_eq_miss       = r_cs==MISS       ;
   assign rcs_eq_write      = r_cs==WRITE      ;
   assign rcs_eq_writeback  = r_cs==WRITEBACK  ;
   assign rcs_eq_replace    = r_cs==REPLACE    ;
   assign rcs_eq_refill     = r_cs==REFILL     ;
   assign rcs_eq_writeblock = r_cs==WRITEBLOCK ;
   
   //ridle
    //正在处理的指令类型
    assign ridle_handling_store_cache   = rcs_eq_ridle & store_buffer_to_cache_or_ram_we_i & ~handling_uncache;
    assign ridle_handling_store_uncache = rcs_eq_ridle & store_buffer_to_cache_or_ram_we_i & handling_uncache ;
    
    //响应
    assign ridle_can_respone_ls              = rcs_eq_ridle & ~store_buffer_to_cache_or_ram_we_i ;
    assign ridle_respone_load                = ridle_can_respone_ls & cache_re;
    assign ridle_respone_store               = ridle_can_respone_ls & cache_we;
    assign ridle_can_respone_cacop_mode_zero = ridle_can_respone_ls & cacop_req_i&(cacop_op_mode_i==2'd0);
    assign ridle_can_respone_cacop_mode_one  = ridle_can_respone_ls & cacop_req_i&(cacop_op_mode_i==2'd1);
    assign ridle_can_respone_cacop_mode_two  = ridle_can_respone_ls & cacop_req_i&(cacop_op_mode_i==2'd2);
    assign ridle_respone_ls                  = ridle_respone_load|ridle_respone_store;
    
    //next状态
    assign cs_eq_ridle_ns = ridle_can_respone_cacop_mode_two|ridle_respone_load|ridle_respone_store ? READ:
                            ridle_handling_store_cache ? WRITE:
                            ridle_can_respone_cacop_mode_one|ridle_handling_store_uncache? MISS :
                            ridle_can_respone_cacop_mode_zero ? WRITEBLOCK :RIDLE;
   
   
   //read阶段
     //正在处理的指令写
     assign read_handling_load             = rcs_eq_read & ~handling_cacop_en & ~handling_store_access;
     assign read_handling_store            = rcs_eq_read & ~handling_cacop_en & handling_store_access;
     assign read_handling_cacop_model_two  = rcs_eq_read & handling_cacop_en ;
     
     assign read_can_respone_ls           =  (read_handling_load|read_handling_cacop_model_two)&cpu_mmu_finish_i;
     assign read_respone_load             =  read_can_respone_ls & cache_re;
     assign read_respone_store            =  read_can_respone_ls & cache_we;
     assign read_respone_ls               =  read_respone_load|read_respone_store;
     
     assign cs_eq_read_ns   =   (read_handling_load|read_handling_store |read_handling_cacop_model_two) ?  (cpu_mmu_finish_i?LOOKUP:READ):RIDLE;
   
   //lookup阶段
     //cache阶段正在执行的类型
     assign lookup_handling_cacop_model_two_cancle = rcs_eq_lookup & handling_cacop_en& handling_access_cancle_i;
     assign lookup_handling_load_req_cancle        = rcs_eq_lookup &~handling_cacop_en&~handling_store_access& handling_access_cancle_i;
     assign lookup_handling_store_req_cancle       = rcs_eq_lookup &~handling_cacop_en& handling_store_access& handling_access_cancle_i;
  
     
     assign lookup_handling_cacop_model_two_no_hit = rcs_eq_lookup & handling_cacop_en& ~handling_access_cancle_i&~cache_hit;
     assign lookup_handling_cacop_model_two_hit    = rcs_eq_lookup & handling_cacop_en& ~handling_access_cancle_i& cache_hit;   
     
     assign lookup_handling_load_req_uncache       = rcs_eq_lookup &~handling_cacop_en& ~handling_store_access& ~handling_access_cancle_i& uncache_i;
     assign lookup_handling_load_req_cache_hit     = rcs_eq_lookup &~handling_cacop_en& ~handling_store_access& ~handling_access_cancle_i&~uncache_i & cache_hit;
     assign lookup_handling_load_req_cache_unhit   = rcs_eq_lookup &~handling_cacop_en& ~handling_store_access& ~handling_access_cancle_i&~uncache_i & ~cache_hit;     
                                    
     assign lookup_handling_store_req_uncache      = rcs_eq_lookup &~handling_cacop_en& handling_store_access& ~handling_access_cancle_i& uncache_i;
     assign lookup_handling_store_req_cache_hit    = rcs_eq_lookup &~handling_cacop_en& handling_store_access& ~handling_access_cancle_i&~uncache_i & cache_hit;
     assign lookup_handling_store_req_cache_unhit  = rcs_eq_lookup &~handling_cacop_en& handling_store_access& ~handling_access_cancle_i&~uncache_i & ~cache_hit; 
     
     //完成
     assign lookup_no_write_cache_req_finish = lookup_handling_cacop_model_two_cancle|lookup_handling_load_req_cancle|lookup_handling_store_req_cancle
                                              |lookup_handling_cacop_model_two_no_hit|lookup_handling_load_req_cache_hit;
    
     assign lookup_req_finish                = lookup_handling_cacop_model_two_cancle|lookup_handling_load_req_cancle|lookup_handling_store_req_cancle|lookup_handling_cacop_model_two_no_hit|lookup_handling_load_req_cache_hit; 
     
     //响应
     assign lookup_can_respone_ls = lookup_no_write_cache_req_finish&((having_unstore_stage_two_req&cpu_mmu_finish_i)|no_stage_two_req);
     assign lookup_respone_load   =  lookup_can_respone_ls&cache_re;
     assign lookup_respone_store  = lookup_can_respone_ls&cache_we;
     assign lookup_respone_ls     = lookup_respone_load|lookup_respone_store;
     
     assign cs_eq_lookup_ns =
                            (  lookup_no_write_cache_req_finish&((having_unstore_stage_two_req&cpu_mmu_finish_i)|no_stage_two_req)&(cache_re|cache_we)
                              |lookup_req_finish&stage_two_cant_to_three
                            ) ? READ :
                            lookup_req_finish&stage_two_can_to_three?LOOKUP:
                            (
                             lookup_handling_cacop_model_two_hit|lookup_handling_load_req_cache_unhit|lookup_handling_store_req_cache_unhit
                            ) ? MISS:
                            //uncache的lload直接到replace发读请求
                            lookup_handling_load_req_uncache ? REPLACE:RIDLE;
     //write
        //正在处理的指令类型write_handling_store_req_cache
        assign write_handling_store_req_cache = rcs_eq_write;
        assign cs_eq_write_ns = RIDLE;
   
   
   
   //miss阶段正在执行
        assign miss_handling_load_req_cache_unhit  = rcs_eq_miss &~handling_cacop_en& ~handling_store_access;                                 
        assign miss_handling_cacop_model_two_hit   = rcs_eq_miss & handling_cacop_en;                                  
        assign miss_handling_store_req_uncache     = rcs_eq_miss &~handling_cacop_en& handling_store_access & handling_uncache;  
        assign miss_handling_store_req_cache_unhit = rcs_eq_miss &~handling_cacop_en& handling_store_access & ~handling_uncache;  
        
        //完成
        
        assign miss_send_data_ok = 1'b0;
        
        assign cs_eq_miss_ns =  
                                 miss_handling_cacop_model_two_hit
                                |miss_handling_load_req_cache_unhit
                                |miss_handling_store_req_uncache|miss_handling_store_req_cache_unhit ? (axi_wr_rdy_i? WRITEBACK:MISS):RIDLE;
    
    //Writeback
        //正在处理的指令
         assign wbe_handling_load_req_cache_unhit_dirty    = rcs_eq_writeback &~handling_cacop_en & ~handling_store_access & handling_req_cache_rdata_dirty;
         assign wbe_handling_load_req_cache_unhit_undirty  = rcs_eq_writeback &~handling_cacop_en & ~handling_store_access & ~handling_req_cache_rdata_dirty;                                   
         assign wbe_handling_cacop_model_two_hit_dirty     = rcs_eq_writeback & handling_cacop_en &  handling_req_cache_rdata_dirty;
         assign wbe_handling_cacop_model_two_hit_undirty   = rcs_eq_writeback & handling_cacop_en &  ~handling_req_cache_rdata_dirty;                                  
         assign wbe_handling_store_req_uncache             = rcs_eq_writeback &~handling_cacop_en &  handling_store_access & handling_uncache;
         assign wbe_handling_store_req_cache_unhit_dirty   = rcs_eq_writeback &~handling_cacop_en &  handling_store_access & ~handling_uncache & handling_req_cache_rdata_dirty;
         assign wbe_handling_store_req_cache_unhit_undirty = rcs_eq_writeback &~handling_cacop_en &  handling_store_access & ~handling_uncache & ~handling_req_cache_rdata_dirty; 
         
         assign wbe_no_write_cache_req_finish = wbe_handling_store_req_uncache;
         assign wbe_req_finish = wbe_handling_store_req_uncache;
         //响应)
         assign wbe_can_respone_ls =  wbe_no_write_cache_req_finish&((having_unstore_stage_two_req&cpu_mmu_finish_i)|no_stage_two_req);
         assign wbe_respone_load   = wbe_can_respone_ls &cache_re; 
         assign wbe_respone_store  = wbe_can_respone_ls &cache_we; 
         assign wbe_respone_ls     = wbe_respone_load|wbe_respone_store;
         
         assign cs_eq_writeback_ns = 
                                (
                                    wbe_no_write_cache_req_finish &((having_unstore_stage_two_req&cpu_mmu_finish_i)|no_stage_two_req)&(cache_re|cache_we)
                                    |wbe_req_finish&stage_two_cant_to_three
                                 )? READ :
                                 wbe_req_finish&stage_two_can_to_three?LOOKUP:
                                 (
                                    wbe_handling_load_req_cache_unhit_dirty|wbe_handling_load_req_cache_unhit_undirty
                                    |wbe_handling_cacop_model_two_hit_dirty|wbe_handling_cacop_model_two_hit_undirty
                                    |wbe_handling_store_req_cache_unhit_dirty|wbe_handling_store_req_cache_unhit_undirty
                                  )?REPLACE:RIDLE;
      //replace
        //正在处理的指令
        assign replace_handling_cacop_model_two       = rcs_eq_replace &  handling_cacop_en;
        assign replace_handling_load_req_uncache      = rcs_eq_replace & ~handling_cacop_en& ~handling_store_access& handling_uncache;
        assign replace_handling_load_req_cache_unhit  = rcs_eq_replace & ~handling_cacop_en& ~handling_store_access& ~handling_uncache;
        assign replace_handling_store_req_cache_unhit = rcs_eq_replace & ~handling_cacop_en&  handling_store_access& ~handling_uncache;
        
        //下一个状态
        assign cs_eq_replace_ns = (replace_handling_load_req_uncache|replace_handling_load_req_cache_unhit|replace_handling_store_req_cache_unhit) ? (axi_rd_rdy_i ? REFILL:REPLACE) :RIDLE;
      
      //refill
        //正在处理的指令类型
        assign refill_handling_cacop_model_two        = rcs_eq_refill &  handling_cacop_en;
        assign refill_handling_load_req_uncache       = rcs_eq_refill & ~handling_cacop_en& ~handling_store_access& handling_uncache;
        assign refill_handling_load_req_cache_unhit   = rcs_eq_refill & ~handling_cacop_en& ~handling_store_access& ~handling_uncache; 
        assign refill_handling_store_req_cache_unhit  = rcs_eq_refill & ~handling_cacop_en&  handling_store_access& ~handling_uncache;  
       
        assign cs_eq_refill_ns = (refill_handling_load_req_uncache|refill_handling_load_req_cache_unhit|refill_handling_store_req_cache_unhit)? ( (axi_ret_valid_i& axi_ret_last_i) ? WRITEBLOCK : REFILL) :RIDLE;
      
      //writeblock
        //正在处理的指令类型
        assign wbc_handling_load_req_uncache      = rcs_eq_writeblock & ~handling_cacop_en& ~handling_store_access& handling_uncache;
        assign wbc_handling_load_req_cache_unhit  = rcs_eq_writeblock & ~handling_cacop_en& ~handling_store_access& ~handling_uncache;
        
        assign wbc_handling_store_req_cache_unhit = rcs_eq_writeblock & ~handling_cacop_en& handling_store_access& ~handling_uncache;
        
        assign wbc_cacop_model_zero              = rcs_eq_writeblock &  handling_cacop_en & handling_cacop_op_mode==2'b00;
        assign wbc_cacop_model_one               = rcs_eq_writeblock &  handling_cacop_en & handling_cacop_op_mode==2'b01;
        assign wbc_cacop_model_two               = rcs_eq_writeblock &  handling_cacop_en & handling_cacop_op_mode==2'b10;
        
        //完成的指令类型
        assign wbc_no_write_cache_req_finish     = wbc_handling_load_req_uncache;
        assign wbc_cache_req_finish               = wbc_handling_load_req_uncache|wbc_handling_load_req_cache_unhit|wbc_cacop_model_zero|wbc_cacop_model_one|wbc_cacop_model_two;
        assign wbc_send_data_ok                  = wbc_handling_load_req_uncache|wbc_handling_load_req_cache_unhit|wbc_handling_store_req_cache_unhit;
        assign wbc_req_finish                    = wbc_handling_load_req_uncache|wbc_handling_load_req_cache_unhit|wbc_handling_store_req_cache_unhit|wbc_cacop_model_zero|wbc_cacop_model_one|wbc_cacop_model_two;
       
        // 响应
         assign wbc_can_respone_ls = wbc_no_write_cache_req_finish&((having_unstore_stage_two_req&cpu_mmu_finish_i)|no_stage_two_req);   
         assign wbc_respone_load   = wbc_can_respone_ls &cache_re;                                                   
         assign wbc_respone_store  = wbc_can_respone_ls &cache_we;                                                   
         assign wbc_respone_ls     = wbc_respone_load|wbc_respone_store;                                             
        
        //下一个状态
        assign cs_eq_writeblock_ns                   = 
                                                  (
                                                     wbc_cache_req_finish&stage_two_cant_to_three
                                                    | wbc_no_write_cache_req_finish&((having_unstore_stage_two_req&cpu_mmu_finish_i)|no_stage_two_req)&(cache_re|cache_we)
                                                  )? READ :
                                                   wbc_cache_req_finish&stage_two_can_to_three?LOOKUP:RIDLE;
                                                  
                                                  
    assign cache_respone_ls =  ridle_respone_ls|read_respone_ls|lookup_respone_ls |wbe_respone_ls|wbc_respone_ls;
    assign cache_respone_store = ridle_respone_store|read_respone_store|lookup_respone_store |wbe_respone_store|wbc_respone_store;
    
    assign load_req_finish  = lookup_handling_cacop_model_two_cancle|lookup_handling_load_req_cancle|lookup_handling_store_req_cancle
                                    |lookup_handling_load_req_cache_hit|wbc_handling_load_req_cache_unhit
                                    |wbc_handling_load_req_uncache;
    
    
   
    assign store_req_part_finish = lookup_handling_store_req_cancle
                                   |lookup_handling_store_req_uncache|lookup_handling_store_req_cache_hit
                                   | wbc_handling_store_req_cache_unhit ;
                                   
    assign store_req_finish  = lookup_handling_store_req_cancle
                               |wbe_handling_store_req_uncache
                               |write_handling_store_req_cache;
    
                                             
    assign r_ns = cs_eq_ridle_ns |cs_eq_read_ns |cs_eq_lookup_ns |cs_eq_miss_ns |cs_eq_write_ns| cs_eq_writeback_ns |cs_eq_replace_ns |cs_eq_refill_ns |cs_eq_writeblock_ns ;     
    
     //主状态转移
    always @(posedge clk)begin
       if(~resetn)begin
           r_cs <= RIDLE;
       end else begin
           r_cs <= r_ns;
       end
    end                                             
                
                
                                             
     
 /***************************************缓存机制**************************************/ 
 
  //随机way_id产生器
  reg rand_count;
    always @(posedge clk)begin
       if(resetn == 1'b0)begin
          rand_count <= 1'b0;
       end else begin
          rand_count <= rand_count +1;
       end
    end
 
   
 
 
 
 //cpu输入缓存
          Queue #(15)cache_cpu_request_part1_Queue// cache_cpu_access_basic_message_queue缓存cpu访问的
        (
            .clk            (clk   )                  ,
            .rst_n          (resetn)                  ,
                          
            .we_i           (cpu_request_part1_queue_we)  ,
                           
            .wdata_i        ( cpu_request_part1_queue_wdata)       ,
                         
            .used_i         (handling_req_finish)          ,
                         
            .full_o         ()                        ,
                           
            .rdata_o        ({handling_cacop_en,handling_cacop_op_mode,handling_store_access,handling_access_addr[11:0]}),//1+2+1+12
            .rdata_valid_o  (handling_valid)
           
        );
        
        
        
        
        Queue #(21)cache_cpu_request_part2_Queue                                                    
        (                                                                         
            .clk            (clk   )                  ,                           
            .rst_n          (resetn)                  ,                           
                                                                                  
            .we_i           (cpu_request_part2_queue_we)  ,                               
                                                                                      
            .wdata_i        (cpu_request_part2_queue_wdata)       ,                               
                                                                                      
            .used_i         (handling_req_finish)          ,                               
                                                                                      
            .full_o         ()                        ,                               
                                                                                      
            .rdata_o        ({handling_way,handling_uncache,handling_access_addr[31:12]}),//1+1+20             
            .rdata_valid_o  ()                                                        
                                                                                      
        );
        
        
        Queue #(35)store_buffer_queue                                                      
        (                                                                         
            .clk            (clk   )                  ,                           
            .rst_n          (resetn)                  ,                           
                                                                                  
            .we_i           (store_buffer_queue_we )  ,                               
                                                                                      
            .wdata_i        (store_buffer_queue_wdata)       ,                               
                                                                                      
            .used_i         (handling_req_finish)          ,                               
                                                                                      
            .full_o         ()                        ,                               
                                                                                      
            .rdata_o        ({handling_store_wstrb,handling_store_wdata}),// 4+32            
            .rdata_valid_o  (store_buffer_queue_valid)                                                        
                                                                                      
        );
        
         //写缓存计数器
         reg cache_table_rdata_cache_en;
         wire cache_table_rdata_cache_en_start;
          always@(posedge clk)begin
            if(resetn == 1'b0)begin
                cache_table_rdata_cache_en <=1'b0;
            end else if(cache_table_rdata_cache_en_start)begin
                cache_table_rdata_cache_en <=1'b1;
            end else if (cache_table_rdata_cache_en)begin
                cache_table_rdata_cache_en <=1'b0;
            end else begin
                cache_table_rdata_cache_en <=cache_table_rdata_cache_en;
            end 
          end
           
         wire cache_table_read_queue_ce;  
        Queue #(299)cache_read_queue                                                      
        (                                                                         
            .clk            (clk   )                  ,                           
            .rst_n          (resetn)                  ,                           
                                                                                  
            .we_i           (cache_table_read_queue_we )  ,                               
                                                                                      
            .wdata_i        (cache_table_read_queue_wdata)       ,                               
                                                                                      
            .used_i         (cache_table_read_queue_ce)          ,                               
                                                                                      
            .full_o         ()                        ,                               
                                                                                      
            .rdata_o        (cache_table_read_queue_rdata),             
            .rdata_valid_o  (cache_table_read_queue_valid)                                                        
                                                                                      
        );

//缓存：axi读回128个字节数据
    always @(posedge clk)begin
        //接收外界axi的数据计数器
       if(resetn == 1'b0|axi_write_count_ce)begin
           axi_write_count <= 2'd0;//初始值为0
       end else if(axi_write_count_we)begin//因为不是按照周期进行计数的所以要设置计数使能信号
           axi_write_count <= axi_write_count+1;
       end else begin
           axi_write_count <= axi_write_count;
       end
    
       //缓存[31:0]
       if(resetn == 1'b0)begin
           exrt_axi_rdata_buffer0 <= 32'd0;
       end else if (2'd0 == axi_write_count[1:0] )begin
           exrt_axi_rdata_buffer0 <= axi_ret_data_i;
       end else begin
           exrt_axi_rdata_buffer0 <= exrt_axi_rdata_buffer0;
       end
       //缓存[63:32]
        if(resetn == 1'b0)begin
           exrt_axi_rdata_buffer1 <= 32'd0;
       end else if (2'd1 == axi_write_count[1:0] )begin
           exrt_axi_rdata_buffer1 <= axi_ret_data_i;
       end else begin
           exrt_axi_rdata_buffer1 <= exrt_axi_rdata_buffer1;
       end
       //缓存[95:64]
       if(resetn == 1'b0)begin
           exrt_axi_rdata_buffer2 <= 32'd0;
       end else if (2'd2 == axi_write_count[1:0])begin
           exrt_axi_rdata_buffer2 <= axi_ret_data_i;
       end else begin
           exrt_axi_rdata_buffer2 <= exrt_axi_rdata_buffer2;
       end
       
       
        if(resetn == 1'b0)begin
             exrt_axi_rdata_buffer3  = 32'd0;
        end else if (2'd3 == axi_write_count[1:0])begin
             exrt_axi_rdata_buffer3  = axi_ret_data_i;
        end else begin
             exrt_axi_rdata_buffer3  =  exrt_axi_rdata_buffer3 ;
        end
       
    end




    
 //cache查找表  
   cache_table cache_table_item(
       .clk       (clk)    ,
       .req_i     (cache_table_en)    ,
       .r_index_i (cache_table_rindex)    ,
       .r_data_o  (cache_table_rdata )    ,              //(20+1+1+128)*2=300 
                  
                  
       .way_i     (cache_table_wway)    ,//写的数据，写往第几路
       .w_index_i (cache_table_windex)    ,//写地址
       .w_type_i  (cache_table_wtype)    ,//10为全写，01为部分写，00表示不写
       .offset_i  (cache_table_woffset)    ,//部分写的块内偏移地址                                             
       .wstrb_i   (cache_table_wstr)    ,//部分写的字节使能
       .w_data_i  (cache_table_wdatabus)     //发生部分写，则使用[31:0]位

    ); 
    
/**************************************************信号******************************************************************/
  //to CPU信号
  assign cache_free_o =   rcs_eq_ridle &(~store_buffer_queue_valid|clear_store_buffer_en_i);
  assign addr_ok_o = cache_respone_ls;
  assign data_ok_o = load_req_finish|store_req_part_finish;
  assign handling_req_finish =load_req_finish|store_req_finish;
  
  
  //缓存信号
    //cpu输入缓存 part1
     assign  cpu_request_index_offest    = cacop_req_i ? { cacop_op_addr_index_i,cacop_op_addr_offset_i}:{index_i,offset_i };
     assign  cpu_request_part1_queue_wdata = {cacop_req_i,cacop_op_mode_i,op_i,cpu_request_index_offest};//1+2+1+12
     
     //cpu输入缓存 part2
     assign hit_or_replace_way = rcs_eq_lookup&cache_hit ? way1_cache_hit : rand_count;
                                 
                                  
     
     
     assign cpu_req_tag = handling_cacop_en ? cacop_op_addr_tag_i :tag_i;       
     assign cpu_request_part2_queue_we = rcs_eq_lookup;
     assign cpu_request_part2_queue_wdata = {hit_or_replace_way,uncache_i,cpu_req_tag};
     
     //storebuffer缓存信息
     assign store_buffer_queue_we = cache_respone_store;
     assign store_buffer_queue_wdata = {store_wstrb_i,store_wdata_i};
     assign {cache_table_read_queue_rdata_way1,cache_table_read_queue_rdata_way0} =cache_table_read_queue_rdata;
     
     //cache查找表读除缓存
     assign cache_table_read_queue_we =cache_table_rdata_cache_en ;
     assign cache_table_read_queue_wdata = cache_table_rdata;
     assign cache_table_read_queue_ce = rcs_eq_lookup;
     
     //缓存外部axi输入128个数据
     assign  axi_write_count_ce    =   rcs_eq_refill&axi_ret_valid_i &axi_ret_last_i;  
  
  
   //cach查找表信息号
    assign cache_table_en = cache_respone_ls|((miss_handling_load_req_cache_unhit|miss_handling_cacop_model_two_hit |miss_handling_store_req_cache_unhit)&axi_wr_rdy_i);
    assign cache_table_rindex = (miss_handling_load_req_cache_unhit|miss_handling_cacop_model_two_hit |miss_handling_store_req_cache_unhit) ? handling_access_addr[11:4]:index_i ;
    
    assign cache_table_wway    = handling_way;
    assign cache_table_windex  = handling_access_addr[11:4];//更新读index是确定的，随机的是way 
    assign cache_table_wtype   = wbc_cacop_model_zero|wbc_cacop_model_one|wbc_cacop_model_two|wbc_handling_load_req_cache_unhit |wbc_handling_store_req_cache_unhit?2'b10:(write_handling_store_req_cache?2'b01:2'b00);
    assign cache_table_woffset = handling_access_addr[3:0];
    assign cache_table_wstr    = handling_store_wstrb;
    
    
    assign cache_table_wv       = 1'b1;
    assign cache_table_wtag     = handling_access_addr[31:12];
    assign cache_table_wdata0   =  write_handling_store_req_cache? handling_store_wdata:exrt_axi_rdata_buffer0;
    assign cache_table_wdata    = {exrt_axi_rdata_buffer3,exrt_axi_rdata_buffer2,exrt_axi_rdata_buffer1,cache_table_wdata0};
    assign cache_table_wd       = handling_access_addr;
    assign cache_table_wdatabus = (wbc_cacop_model_zero|wbc_cacop_model_one|wbc_cacop_model_two)?150'd0:{{cache_table_wv,cache_table_wtag},cache_table_wdata,cache_table_wd};
  
  
  //缓存
  assign axi_write_count_we =   rcs_eq_refill&axi_ret_valid_i;
  assign cache_table_rdata_cache_en_start = cache_respone_ls|ridle_can_respone_cacop_mode_two;
  assign cpu_request_part1_queue_we = cache_respone_ls|ridle_can_respone_cacop_mode_zero|ridle_can_respone_cacop_mode_one|ridle_can_respone_cacop_mode_two;
  assign handling_req_cache_rdata_dirty = handling_way? cache_rdata_way1_dirty :cache_rdata_way0_dirty;
                                          
  //axi信号
       assign axi_rd_req_o  = replace_handling_cacop_model_two|replace_handling_load_req_uncache|replace_handling_load_req_cache_unhit|replace_handling_store_req_cache_unhit;
       assign axi_rd_type_o = replace_handling_load_req_uncache? 3'b010:3'b100;
       assign axi_rd_addr_o = replace_handling_load_req_uncache? handling_access_addr :{handling_access_addr[31:4],4'd0};
       
                
                   
       assign axi_wr_req_o    = wbe_handling_load_req_cache_unhit_dirty |wbe_handling_cacop_model_two_hit_dirty|wbe_handling_store_req_cache_unhit_dirty|wbe_handling_store_req_uncache;
       assign axi_wr_type_o   = wbe_handling_store_req_uncache ?  3'b010:3'b100;
       assign axi_wr_addr_o   = wbe_handling_store_req_uncache ? handling_access_addr :{handling_access_addr[31:4],4'd0};
       assign axi_wr_wstrb_o  = handling_store_wstrb;
       assign axi_wr_data_o   = wbe_handling_store_req_uncache ?{96'd0,handling_store_wdata}?handling_way:cache_table_read_queue_rdata_way1:cache_table_read_queue_rdata_way0;
       
       

         
       assign cs_o                     = r_cs                  ;
       assign uncache_en_buffer_o      = handling_uncache     ;
       assign search_addr_buffer_o     = handling_access_addr    ;
       assign exrt_axi_rdata_buffer0_o = exrt_axi_rdata_buffer0;
       assign exrt_axi_rdata_buffer1_o = exrt_axi_rdata_buffer1;
       assign exrt_axi_rdata_buffer2_o = exrt_axi_rdata_buffer2;
       assign exrt_axi_rdata_buffer3_o = exrt_axi_rdata_buffer3;
       assign way0_cache_hit_o         = way0_cache_hit        ;
       assign way1_cache_hit_o         = way1_cache_hit        ;
       assign search_buffer_o          = cache_table_read_queue_rdata          ;
       assign wait_dispose_inst_num_o = inst_num;
  
//  assign diff_cache_en_o                = cache_en           ;
//  assign diff_cache_rindex_o            = cache_rindex       ;
//  assign diff_cache_raddr_o             = {tag,search_addr_buffer[11:0]};
//  assign diff_cache_rdata_o             = cache_rdata        ;
//  assign diff_cache_wway_o              = cache_wway         ;
//  assign diff_cache_w_index_o           = cache_w_index      ;
//  assign diff_cache_wtype_o             = cache_wtype        ;
//  assign diff_search_offset_o           = search_addr_buffer[3:0] ;
//  assign diff_cache_wdata_o             = cache_wdata        ;
     
  
     
endmodule