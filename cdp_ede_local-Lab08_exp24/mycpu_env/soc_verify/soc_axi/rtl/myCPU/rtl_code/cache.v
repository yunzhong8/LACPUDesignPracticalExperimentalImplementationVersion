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
module cache(
 input  wire                         clk                ,
 input  wire                         resetn             ,
 input  wire                         valid              ,//访问请求信号req，1表示有请求
 input  wire                         op                 ,//访问类型，0：req,1:write,we信号
 input  wire [`CacheOffsetWidth]     offset             ,//pc[3:0]
 input  wire [`CacheIndexWidth]      index              ,//pc[11:4]
 input  wire [`CacheTagWidth]        tag                ,//p_pc[31:12]
 
 //cache维护指令
 input                               cacop_req_i,
 input  [ 1:0]                       cacop_op_mode_i         ,  
 input  [ 7:0]                       cacop_op_addr_index_i   , //this signal from mem stage's va
 input  [19:0]                       cacop_op_addr_tag_i     , 
 input  [ 3:0]                       cacop_op_addr_offset_i  ,
 
 
 input  wire                         uncache_i          ,
 input  wire                         store_buffer_we_i  ,
 input  wire                         store_buffer_ce_i  ,
 input  wire                         cache_refill_valid_i,
 input  wire                         cpu_mmu_finish_i,//表示在mmu那一级的指令可以流往译码级啦

 input  wire [`CacheWstrbWidth]      wstrb              ,//写字节使能
 input  wire [31:0]                  wdata              ,//cache写数据
                                                    
 output wire                         addr_ok            ,//输出已经接收地址ok
 output wire                         data_ok            ,//输出数据准备好啦

                                                        
 output wire                         rd_req             ,//输出类AXI读请求
 output wire [2:0]                   rd_type            ,//输出类AXI读请求类型
 output wire [31:0]                  rd_addr            ,//输出类AXI读请求的起始地址
 input  wire                         rd_rdy             ,//AXI转接桥输入可以读啦，read_ready
 
 input  wire                         ret_valid           ,//axi转接桥输入读回数据read_data_valid
 input  wire                         ret_last           ,//axi转接桥输入这是最后一个读回数据，为什么是两位的？？？？
 input  wire [31:0]                  ret_data           ,//axi转接桥输入的读回数据
                                                        
 output wire                         wr_req             ,//类AXI输出的写请求
 output wire [2:0]                   wr_type            ,//类AXI输出的写请求类型
 output wire [31:0]                  wr_addr            ,//类AXI输出的写地址
 output wire [3:0]                   wr_wstrb           ,//写操作掩码
 output wire  [`CacheBurstDataWidth] wr_data            ,//类AXI输出的写数据128bit       
 input  wire                         wr_rdy             ,//AXI总线输入的写完成信号，可以接收写请求 
 
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
 output wire     [299:0]            search_buffer_o          ,          
 
 
 output wire diff_cache_en_o                               ,
 output wire [`CacheIndexWidth] diff_cache_rindex_o        ,
 output wire [31:0]diff_cache_raddr_o                      ,
 output wire [299:0] diff_cache_rdata_o                    ,
 output wire diff_cache_wway_o                             ,
 output wire [`CacheIndexWidth]diff_cache_w_index_o        ,
 output wire [1:0]diff_cache_wtype_o                       ,
 output wire [3:0]diff_search_offset_o                     ,
 output wire [149:0]diff_cache_wdata_o                      
 
                     
    );
  
  
 /***************************************input variable define(输入变量定义)**************************************/
  /***************************************output variable define(输出变量定义)**************************************/
   wire [`CacheTagWidth]      wr_addr_tag_o   ;//cache写外部axi的标记字段p_pc[31:12]
   wire [`CacheIndexWidth]    wr_addr_index_o ;//pc[11:4]
   wire [`CacheOffsetWidth]   wr_addr_offset_o;//p_pc[31:12] 
   wire [`CacheOffsetWidth]   rd_addr_offset_o;
  
  
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
  /***************** 缓存变量定义************************/ 
   wire         search_tag_buffer_we   ;//缓存地址写使能    
   wire         search_index_buffer_we ;//写虚拟地址存储
   wire  [31:0] search_addr_buffer     ;
   
   wire search_buffer_we_count_start,search_buffer_ce; 
   reg search_buffer_we_count;
   reg cache_wdata_buffer_valid;  
   wire cache_wway_buffer_wdata;
   wire axi_write_count_ce;
         
   reg          search_buffer_valid    ;    //表示当前是否有阶段2的指令  
   reg  [299:0] search_buffer          ;//查找缓存区/      
                
   wire          cache_wway_buffer_we   ; 
   reg          cache_wway_buffer      ;
                      
   wire          cache_wdata_buffer_we  ;  
   reg [31:0]   cache_wdata_buffer     ;//缓存写数据  
   reg [3:0]    cache_wstr_buffer      ;//缓存写字节使能 
   wire [1:0]cacop_op_mode  ;
   wire cacop_en;
   //缓存uncache使能信号(所以lookup要对该信号进行缓存)
   //load是uncache则缺失查找状态转移需要这个信号进行控制
   //store是uncache则要缓存到wb阶段发出是否要执行的信号
   reg           uncache_en_buffer      ;
   wire          uncache_en_buffer_we   ;
   
   /***************** 缓存外部axi传入数据 ************************/ 
   wire        axi_write_count_we      ; 
   reg  [1:0]  axi_write_count         ;//4个字 
   reg  [31:0] exrt_axi_rdata_buffer0,exrt_axi_rdata_buffer1,exrt_axi_rdata_buffer2,exrt_axi_rdata_buffer3;     
   
  //CacheTable需要的变量
   wire         cache_re,cache_we,no_cache_req      ;//cache请求：写使能，读使能
   wire         cache_search_op        ;//查找类型
   wire [299:0] cache_rdata            ;
   wire [149:0] cache_wdata            ;//cache待写回数据(只写一路的，所以是150)
   wire [31:0]  w_data0                ;
   wire [127:0] w_data                 ;//写回的128bit数据
   wire [19:0]  w_tag                  ;
   wire         w_v                    ;
   wire         w_d                    ; 
        
  //cache信号
   wire                    cache_en           ;//cache使能信号
   wire  [1:0]             cache_wtype        ;
   wire [`CacheIndexWidth] cache_rindex       ;
   wire                    cache_wway         ;//cache写的路
   wire [`CacheIndexWidth] cache_w_index      ;//cache写的地址  
   wire                    cache_hit; 
   
  //CacheMiss信号 
   reg                     miss_replace_way   ;
   wire                     miss_replace_way_we    ;    
  //查找命中信号
   wire                    way1_cache_hit,way0_cache_hit; 
  //随机数产生器
   reg                     rand_count;  
   
   
   
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
   
 
   //cache维护指令使能
   wire cacop_en_i;
   //如果当前有cacop指令的请求，且当前为空闲状态，则必响应
   assign cacop_en_i = cacop_req_i&cache_free_o;
  /***************************************inner variable define(错误状态)**************************************/

   wire error1,error2;
   wire stage_one_en ;
   wire stage_two_en;
   wire stage_three_en;
   reg[`CacheDisposeInstNumWidth] inst_num;
   always @(posedge clk)begin
        if(resetn == 1'b0)begin
            inst_num<=`CacheDisposeInstNumLen'b0;
        end else if(addr_ok&~data_ok)begin
            inst_num <= inst_num+`CacheDisposeInstNumLen'b1;
        end else if(addr_ok&data_ok)begin
            inst_num <= inst_num;
        end else if(~addr_ok&data_ok)begin
            inst_num <= inst_num-`CacheDisposeInstNumLen'b1;
        end else begin
            inst_num <= inst_num;
        end
   end
   
   assign stage_one_en    = addr_ok;
   assign stage_two_en   = search_buffer_we_count|search_buffer_valid;
   assign stage_three_en = rcs_eq_lookup;
 
 //idle阶段不可能存在访问请求的data_ok没有发出去（即当前要处理的指令数不等于0）              
    assign error1 = rcs_eq_ridle & inst_num!=0 ;

//cache所能处理的指令数最大不超过2
    assign error2 =  inst_num>2; 
   
   
 assign error_o = error1|error2;  
   /***************************************inner variable define(逻辑实现)**************************************/  
  /******************************inner variable define(缓存实现)*******************************/  
  //缓存访问cache的地址
 //用于清理队列访问完的地址   
 wire search_addr_ce;
    
//访问地址和访问类型缓存队列 
wire [11:0]index_offset_queue_wdata;
assign index_offset_queue_wdata =  cacop_en_i ? {cacop_op_addr_index_i,cacop_op_addr_offset_i}: {index,offset};  
Queue #(15)index_op_queue 
(
    .clk            (clk   )                  ,
    .rst_n          (resetn)                  ,
                  
    .we_i           (search_index_buffer_we)  ,
                   
    .wdata_i        ({cacop_en_i,cacop_op_mode_i,op,index_offset_queue_wdata})       ,
                 
    .used_i         (search_addr_ce)          ,
                 
    .full_o         ()                        ,
                   
    .rdata_o        ({cacop_en,cacop_op_mode,cache_search_op,search_addr_buffer[11:0]}),
    .rdata_valid_o  (search_index_valid)
   
);

wire [19:0]tag_queue_wdata;
assign tag_queue_wdata = cacop_en ? cacop_op_addr_tag_i: search_addr_buffer[31:12];
Queue #(19)tag_queue                                                      
(                                                                         
    .clk            (clk   )                  ,                           
    .rst_n          (resetn)                  ,                           
                                                                          
    .we_i           (search_tag_buffer_we)  ,                               
                                                                              
    .wdata_i        (tag)       ,                               
                                                                              
    .used_i         (search_addr_ce)          ,                               
                                                                              
    .full_o         ()                        ,                               
                                                                              
    .rdata_o        (search_addr_buffer[31:12]),             
    .rdata_valid_o  ()                                                        
                                                                              
);                                                                            
    
  
  

 always @(posedge clk)begin
     if(resetn == 1'b0)begin
           search_buffer       <=300'd0;
           search_buffer_valid <= 1'b0;
     end else if(search_buffer_we_count)begin
        search_buffer_valid <= 1'b1;
        search_buffer       <= cache_rdata; 
     end else if(search_buffer_ce  )begin
        search_buffer_valid <= 1'b0; 
        search_buffer       <= 300'd0;
     end else begin
        search_buffer_valid <= search_buffer_valid ;
        search_buffer       <= search_buffer;
     end
 end
 
 //写缓存计数器
  always@(posedge clk)begin
    if(resetn == 1'b0)begin
        search_buffer_we_count <=1'b0;
    end else if(search_buffer_we_count_start)begin
        search_buffer_we_count <=1'b1;
    end else if (search_buffer_we_count)begin
        search_buffer_we_count <=1'b0;
    end else begin
        search_buffer_we_count <=search_buffer_we_count;
    end 
  end
  
  //cache处理阶段要处理的way
  //缺失的时候要处理的值是：替换的way_id
  //命中的时候要出的是命中的，way_id
  //cache维护指令则要处理的是offsett[0]表示的way_id
 
  assign   cache_wway_buffer_wdata = cacop_en&(cacop_op_mode==2'b0|cacop_op_mode==2'b1) ? search_addr_buffer[0] :
                                    way0_cache_hit ? 1'b0 :
                                    way1_cache_hit ? 1'b1:
                                    miss_replace_way_we ? rand_count:1'b0;
  //缓存cpu写cache的数据
    always @(posedge clk)begin  
        //缓存读写路的look阶段命中way_id
       if(resetn == 1'b0)begin
           cache_wway_buffer <= 1'b0;
        end else if (cache_wway_buffer_we )begin
            cache_wway_buffer <= cache_wway_buffer_wdata;
        end else begin
            cache_wway_buffer <= cache_wway_buffer;
        end
        
      //缓存：写入cache的数据,字节使能
       if(resetn == 1'b0)begin
            cache_wdata_buffer  <= 32'd0;
            cache_wstr_buffer   <= 4'd0;
       end else if(cache_wdata_buffer_we)begin
           cache_wdata_buffer <= wdata;
           cache_wstr_buffer   <= wstrb ;
       end
       
       if(resetn == 1'b0)begin
            cache_wdata_buffer_valid <=1'b0;
       end else if(cache_wdata_buffer_we)begin
            cache_wdata_buffer_valid <=1'b1;
       end else if(store_buffer_ce_i)begin
             cache_wdata_buffer_valid <=1'b0;
       end else begin
             cache_wdata_buffer_valid <=1'b0;
       end      
       
       
       //缓存查找第二状态,查找的地址是不uncache,只要是到了第二状态就要缓存它
       if(resetn == 1'b0)begin
            uncache_en_buffer <= 1'b0;
       end else if(uncache_en_buffer_we)begin
            uncache_en_buffer <= uncache_i;
       end else begin
            uncache_en_buffer <= uncache_en_buffer;
       end
    end

 
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
           exrt_axi_rdata_buffer0 <= ret_data;
       end else begin
           exrt_axi_rdata_buffer0 <= exrt_axi_rdata_buffer0;
       end
       //缓存[63:32]
        if(resetn == 1'b0)begin
           exrt_axi_rdata_buffer1 <= 32'd0;
       end else if (2'd1 == axi_write_count[1:0] )begin
           exrt_axi_rdata_buffer1 <= ret_data;
       end else begin
           exrt_axi_rdata_buffer1 <= exrt_axi_rdata_buffer1;
       end
       //缓存[95:64]
       if(resetn == 1'b0)begin
           exrt_axi_rdata_buffer2 <= 32'd0;
       end else if (2'd2 == axi_write_count[1:0])begin
           exrt_axi_rdata_buffer2 <= ret_data;
       end else begin
           exrt_axi_rdata_buffer2 <= exrt_axi_rdata_buffer2;
       end
       
       
        if(resetn == 1'b0)begin
             exrt_axi_rdata_buffer3  = 32'd0;
        end else if (2'd3 == axi_write_count[1:0])begin
             exrt_axi_rdata_buffer3  = ret_data;
        end else begin
             exrt_axi_rdata_buffer3  =  exrt_axi_rdata_buffer3 ;
        end
       
    end
   
    
 
 //随机way_id产生器
    always @(posedge clk)begin
       if(resetn == 1'b0)begin
          rand_count <= 1'b0;
       end else begin
          rand_count <= rand_count +1;
       end
    end
  
 //缓存没有命中的替换的地址,和路id
    always @(posedge clk)begin
       if(resetn == 1'b0)begin
           miss_replace_way   <= 1'b0;
       end else if(miss_replace_way_we)begin
           miss_replace_way  <= rand_count;
       end else begin
           miss_replace_way   <= miss_replace_way   ;  
       end
    end
 
 //查找比较电路(使用的是第二个时钟周期传入的物理tag)
 //当标记相等，且v字有效，则为查找成功
 wire [`CacheTagWidth]         cache_rdata_way0_tag, cache_rdata_way1_tag;
 wire cache_rdata_way0_valid,cache_rdata_way1_valid;
    assign cache_rdata_way0_tag   = search_buffer[`Way0TagLocation];
    assign cache_rdata_way1_tag   = search_buffer[`Way1TagLocation];
    assign cache_rdata_way0_valid = search_buffer[`Way0VLocation];
    assign cache_rdata_way1_valid = search_buffer[`Way1VLocation];
    
    assign way0_cache_hit =   tag == cache_rdata_way0_tag && cache_rdata_way0_valid;
    assign way1_cache_hit =   tag == cache_rdata_way1_tag && cache_rdata_way1_valid;
    assign cache_hit = way0_cache_hit|way1_cache_hit;
    
 //当前cache请求类型   
    assign cache_re = valid&~op;
    assign cache_we = valid&op;
    assign no_cache_req =  ~valid;
 
 //cache写数据
    assign cache_rindex = (r_cs==MISS)?  search_addr_buffer[11:4]:index;//读地址
    
    assign w_tag = search_addr_buffer[31:12];//无论是否命中，tag位都是查找地址的[31:12](局部写不用设置)
    assign w_v = 1'b1;// 有效位,全写的时候设置为1,部分写不需要设在v字段
    //只有部分写的时候d=1,全写则d=0（由于是写缺失导致的全写模式也要设置d=1,所以应该是当前cache的请求是store则，为1,否则=0）
    //部分写和全写都会设置w_d字段 
    assign w_d =  cache_search_op ? 1'd1 :1'd0;
    //规定当状态是write的时候低32是CPU写入数据
    assign w_data0 = (r_cs==WRITE)? cache_wdata_buffer:exrt_axi_rdata_buffer0;
    assign w_data = {exrt_axi_rdata_buffer3,exrt_axi_rdata_buffer2,exrt_axi_rdata_buffer1,w_data0};
    assign cache_wdata = cacop_en&(cacop_op_mode==2'b0|cacop_op_mode==2'b1|cacop_op_mode==2'b10)?150'd0:{{w_v,w_tag},w_data,w_d};
 

 //替换的时候,写入外部axi的数据
   // 要求所有uncache的地址对应的空间必须是32bit为单位的不然会错
    assign wr_type = uncache_en_buffer? 3'b010:3'b100;//请求类型固定只能是行请求
    assign wr_wstrb = cache_wstr_buffer;
    assign wr_addr_index_o = search_addr_buffer[11:4];
    assign wr_addr_offset_o =  uncache_en_buffer ?search_addr_buffer[3:0]:4'd0;
 //查找缺失的时候,如果是uncache的是,写地址是查找地址
 //替换的时候，是被替换行的地址
 //如果随机选择的way=1则是search_buffer[`Way1TagLocation]，cache_way是和wr_addr_tag同时钟产生的，没有落后于wr_addr_tag
    assign wr_addr_tag_o = uncache_en_buffer ? search_addr_buffer[31:12]:
                           cache_wway ? cache_rdata[`Way1TagLocation] :  cache_rdata[`Way0TagLocation];
    
 //标记是要被替换的way中的，index是查询地址的，初始位是0000
    assign wr_addr = {wr_addr_tag_o,wr_addr_index_o,wr_addr_offset_o};//查找地址必须是物理地址
    
    //读一行读地址必须是当前地址截断低4位,作为起始地址
    //读一字,则必须是物理地址,不用截断
    assign rd_addr_offset_o = uncache_en_buffer ? search_addr_buffer[3:0]:4'd0;
    assign rd_addr = {search_addr_buffer[31:4],rd_addr_offset_o};
    //如果是uncache则写回的数据是cpu写cache的数据
    assign wr_data = uncache_en_buffer ? {96'd0,cache_wdata_buffer}:
                     cache_wway_buffer ? cache_rdata[`Way1DataLocation] : cache_rdata[`Way0DataLocation];//只选用查找缓存区的way0作为替换                   
  //暂时支持设备地址查找  
   assign rd_type = uncache_en_buffer? 3'b010:3'b100;
   /******************************inner variable define(各状态动作)*******************************/
   assign rcs_eq_ridle      = r_cs==RIDLE      ;
   assign rcs_eq_read       = r_cs==READ       ; 
   assign rcs_eq_lookup     = r_cs==LOOKUP     ;
   assign rcs_eq_miss       = r_cs==MISS       ;
   assign rcs_eq_write      = r_cs==WRITE      ;
   assign rcs_eq_writeback  = r_cs==WRITEBACK  ;
   assign rcs_eq_replace    = r_cs==REPLACE    ;
   assign rcs_eq_refill     = r_cs==REFILL     ;
   assign rcs_eq_writeblock = r_cs==WRITEBLOCK ;
  
  
 
 
 //cache是否空闲
 //在空闲态，且没有store指令
 assign cache_free_o = rcs_eq_ridle &(~cache_wdata_buffer_valid|store_buffer_ce_i);
 
   /******************************inner variable define(基础信号)*******************************/
   //store指令的部分完成（指发了data_ok，但是还没有写入cache/ram）
   wire lookup_store_req_uncache_part_finish,lookup_store_req_cache_hit_part_finish;
   //
   wire lookup_load_req_cancle,lookup_store_req_cancle,lookup_cacop_model_tow_cancle,lookup_cacop_model_tow_no_hit,lookup_load_req_cache_hit_finish;
   
   wire write_store_req_cache_hit_finish,write_store_req_cache_unhit_finish;
   wire writeback_store_req_uncache_finish,writeblock_store_req_cache_unhit_part_finish,writeblock_load_req_uncache_finish,writeblock_load_req_cache_unhit_finish,writeblock_cacop_model_tow_finish,writeblock_cacop_model_zo_finish;
   
   //cache请求完成，前缀表示那个阶段的指令完成，
   //请求前缀的状态完成，且完成状态不会写cache，保证了此时响应请求，不会出现读写冲突
   wire lookup_req_finish_no_write_cache,write_req_finish_no_write_cache,writeback_req_finish_no_write_cache,writeblock_req_finish_no_write_cache;
    //请求前缀的状态完成，且完成状态会写cache，不能响应新请求，会出现读写冲突，因为设计的cache的半双共
   wire lookup_req_finish_write_cache,write_req_finish_write_cache,writeback_req_finish_write_cache,writeblock_req_finish_write_cache;
   wire lookup_req_finish,write_req_finish,writeback_req_finish,writeblock_req_finish;
   wire load_req_finish;
   wire store_req_part_finish,store_req_finish;
   wire cacop_model_tow_finish,cacop_finish;
   
   //响应请求
   //响应cache维护指令请求
   wire respone_cacop_mode_zero,respone_cacop_mode_one,respone_cacop_mode_tow;
   //响应load，store指令请求，ls表示load,store请求都可以响应，
   wire ridle_can_respone_ls,read_can_respone_ls,lookup_can_respone_ls,write_can_respone_ls,writeback_can_respone_ls,writeblock_can_respone_ls;
   wire ridle_respone_load,ridle_respone_store,read_respone_load,read_respone_store,lookup_respone_load,lookup_respone_store,write_respone_load,write_respone_store,writeback_respone_load;
   wire writeback_respone_store,writeblock_respone_load,writeblock_respone_store;
  
   //状态是否能响应请求
   wire ridle_respone ,read_respone ,lookup_respone ,write_respone ,writeback_respone ,writeblock_respone;
   wire cache_respone;
   
   //在某个状态有些指令是完成，有些指令是继续执行的到下一个状态，就要设在goon信号
   wire looup_cacop_mode_tow_goon ,lookup_uncache_load_goon ,lookup_cache_ls_nohit_goon;
   wire writeback_uncache_load_goon , writeback_cache_ls_nohit_goon,  writeback_goon;

   
   
   /******************************inner variable define(请求完成信号)*******************************/
   
  assign lookup_store_req_uncache_part_finish   = rcs_eq_lookup&~cacop_en&cache_search_op & uncache_i &cache_refill_valid_i;
  assign lookup_store_req_cache_hit_part_finish = rcs_eq_lookup&~cacop_en&cache_search_op&cache_refill_valid_i& ~uncache_i&cache_hit;
   
   
  assign lookup_load_req_cancle                  = rcs_eq_lookup&~cacop_en&~cache_search_op&(~cache_refill_valid_i) ;
  assign lookup_store_req_cancle                 = rcs_eq_lookup&~cacop_en&cache_search_op&(~cache_refill_valid_i)  ;
  assign lookup_cacop_model_tow_cancle           = rcs_eq_lookup&cacop_en&(~cache_refill_valid_i)                   ;
  assign lookup_cacop_model_tow_no_hit           = rcs_eq_lookup&cacop_en&~cache_hit&cache_refill_valid_i           ; 
  assign lookup_load_req_cache_hit_finish        = rcs_eq_lookup&~cacop_en&(~uncache_i)&~cache_search_op&cache_refill_valid_i&cache_hit;
  
  
  assign write_store_req_cache_hit_finish   = rcs_eq_write;
  assign write_store_req_cache_unhit_finish = rcs_eq_write;
  
  assign writeback_store_req_uncache_finish = rcs_eq_writeback&~cacop_en&cache_search_op&uncache_en_buffer ;
  
  
  
  assign writeblock_store_req_cache_unhit_part_finish = rcs_eq_writeblock&~cacop_en&(~uncache_i)&cache_search_op;
  
  assign writeblock_load_req_uncache_finish      = rcs_eq_writeblock&~cacop_en&uncache_i   &(~cache_search_op);
  assign writeblock_load_req_cache_unhit_finish  = rcs_eq_writeblock&~cacop_en&(~uncache_i)&(~cache_search_op);
  assign writeblock_cacop_model_tow_finish       = rcs_eq_writeblock&cacop_en &(cacop_op_mode_i==2'd2);
  assign writeblock_cacop_model_zo_finish        = rcs_eq_writeblock&cacop_en &(cacop_op_mode_i==2'd0|cacop_op_mode_i==2'd1);
  //各阶段状态指令完成
  //lookup
  assign lookup_req_finish_no_write_cache = lookup_load_req_cancle|lookup_store_req_cancle|lookup_cacop_model_tow_cancle|lookup_cacop_model_tow_no_hit| lookup_load_req_cache_hit_finish;
  assign lookup_req_finish_write_cache = 1'b0;
  assign lookup_req_finish = lookup_req_finish_write_cache|lookup_req_finish_no_write_cache;
  
  assign write_req_finish_no_write_cache =1'b0;
  assign write_req_finish_write_cache     = write_store_req_cache_hit_finish|write_store_req_cache_unhit_finish;
  assign write_req_finish  = write_req_finish_write_cache|write_req_finish_no_write_cache;
  
  assign writeback_req_finish_write_cache = 1'b0;
  assign writeback_req_finish_no_write_cache = writeback_store_req_uncache_finish;
  assign writeback_req_finish = writeback_req_finish_write_cache|writeback_req_finish_no_write_cache;
  
  //writeblock_req_finish_no_write_cache
  assign writeblock_req_finish_no_write_cache = writeblock_cacop_model_zo_finish|writeblock_cacop_model_tow_finish|writeblock_load_req_uncache_finish;
  assign writeblock_req_finish_write_cache =writeblock_load_req_cache_unhit_finish;
  assign writeblock_req_finish = writeblock_req_finish_write_cache|writeblock_req_finish_no_write_cache;
  //要发地址ok,要清理ce
  assign load_req_finish            = lookup_load_req_cancle |writeblock_load_req_uncache_finish|lookup_load_req_cache_hit_finish|writeblock_load_req_cache_unhit_finish;
 
  
 //部分完成发data_ok
  assign store_req_part_finish = lookup_store_req_cancle|lookup_store_req_uncache_part_finish|lookup_store_req_cache_hit_part_finish|writeblock_store_req_cache_unhit_part_finish;
  
 //完成发ce
  assign store_req_finish = lookup_store_req_cancle|writeback_store_req_uncache_finish|write_store_req_cache_hit_finish|write_store_req_cache_unhit_finish;
  
  assign cacop_model_tow_finish =lookup_cacop_model_tow_cancle|lookup_cacop_model_tow_no_hit |writeblock_cacop_model_tow_finish;
  //要清理 ce要发data_ok
  assign cacop_finish = writeblock_cacop_model_zo_finish|cacop_model_tow_finish;
 
  /******************************inner variable define(响应信号)*******************************/
  assign respone_cacop_mode_zero =rcs_eq_ridle &  cacop_en_i&(cacop_op_mode_i==2'd0);
  assign respone_cacop_mode_one  =rcs_eq_ridle &  cacop_en_i&(cacop_op_mode_i==2'd1);
  assign respone_cacop_mode_tow  =rcs_eq_ridle &  cacop_en_i&(cacop_op_mode_i==2'd2);
  
  //当前有cacop指令请求，则暂停所有ls的响应，
  assign ridle_can_respone_ls       = rcs_eq_ridle      & (~cacop_req_i)&(~store_buffer_we_i);
  assign read_can_respone_ls        = rcs_eq_read       & (~cacop_req_i)&(~cacop_en)&cpu_mmu_finish_i &(~cache_search_op);
  assign lookup_can_respone_ls      = rcs_eq_lookup     & (~cacop_req_i)&lookup_req_finish_no_write_cache&(search_buffer_we_count&(~cache_wdata_buffer_valid)&cpu_mmu_finish_i |~search_buffer_we_count);
  assign write_can_respone_ls       = rcs_eq_write      & (~cacop_req_i)&write_req_finish_no_write_cache&(~search_buffer_valid);
  assign writeback_can_respone_ls   = rcs_eq_writeback  & (~cacop_req_i)&writeback_req_finish_no_write_cache&(~search_buffer_valid);
  assign writeblock_can_respone_ls  = rcs_eq_writeblock & (~cacop_req_i)&writeblock_req_finish_no_write_cache&(~search_buffer_valid);
  
  
  assign ridle_respone_load       = ridle_can_respone_ls      &cache_re;
  assign ridle_respone_store      = ridle_can_respone_ls      &cache_we;
  assign read_respone_load        = read_can_respone_ls       &cache_re;
  assign read_respone_store       = read_can_respone_ls       &cache_we;
  assign lookup_respone_load      = lookup_can_respone_ls     &cache_re;
  assign lookup_respone_store     = lookup_can_respone_ls     &cache_we; 
  assign write_respone_load       = write_can_respone_ls      &cache_re;
  assign write_respone_store      = write_can_respone_ls      &cache_we;
  assign writeback_respone_load   = writeback_can_respone_ls  &cache_re; 
  assign writeback_respone_store  = writeback_can_respone_ls  &cache_we; 
  assign writeblock_respone_load  = writeblock_can_respone_ls &cache_re; 
  assign writeblock_respone_store = writeblock_can_respone_ls &cache_we; 
  
  
  //要发地址ok,要查cache
//  assign ridle_respone      =  respone_cacop_mode_tow | ridle_respone_load|ridle_respone_store ;
  assign ridle_respone      =  ridle_respone_load     | ridle_respone_store ;
  assign read_respone       =  read_respone_load      | read_respone_store;
  assign lookup_respone     =  lookup_respone_load    | lookup_respone_store;
  assign write_respone      =  write_respone_load     | write_respone_store  ;
  assign writeback_respone  =  writeback_respone_load | writeback_respone_store;
  assign writeblock_respone =  writeblock_respone_load| writeblock_respone_store;
  
  //要发地址ok
  assign cache_respone =ridle_respone|read_respone|lookup_respone|write_respone|writeback_respone|writeblock_respone;
//  assign cache_respone =read_respone|lookup_respone|write_respone|writeback_respone|writeblock_respone;
 
 
//发生请求响应需要做的事情  
    //load,store指令的响应
                                  
    assign addr_ok  =   cache_respone;
                                      
    assign search_buffer_we_count_start  = cache_respone;
                                               
                                         
    //缓存访问地址
    //正常访问模式的需要缓存，访问地址，
    //cacop维护指令模式0,1都需要缓存            
   assign search_index_buffer_we =  cache_respone|respone_cacop_mode_zero|respone_cacop_mode_one;           
   
   //cache使能                                  
   assign cache_en = cache_respone              
                     | rcs_eq_miss&(~uncache_en_buffer|cacop_en)&wr_rdy//miss状态要读出要替换的数据.cache维护指令在该阶段也要触发读cache,
                     | rcs_eq_write//使能cache进行部分写
                     | rcs_eq_writeblock;//使能cache，对cache类进行全写
                     
     //如果响应写指令，保存写指令的写数据          
   assign cache_wdata_buffer_we  =    ridle_respone_store |read_respone_store |lookup_respone_store| write_respone_store|writeback_respone_store|writeblock_respone_store;
                                    
//lookup阶段需要做的事情                    
     //缓存物理地址，用于uncache,和cache发生缺失                 
   assign search_tag_buffer_we   =     rcs_eq_lookup;     
   //缓存uncache信号      
   assign uncache_en_buffer_we =  rcs_eq_lookup;    
   
//访问指令完成需要做的事情   
   //当前访问指令完成则要清理存储的访问信息                                                                                                                                  
    assign search_addr_ce =  cacop_finish |load_req_finish|  store_req_finish   ;                                                                              
                                                                                                                                                                           
    assign search_buffer_ce =   rcs_eq_lookup;    
    //访问指令完成                              
//    assign data_ok  =   cacop_model_tow_finish|load_req_finish|store_req_part_finish;
    assign data_ok  =   load_req_finish|store_req_part_finish;
                      
                                                                                                                             
//store指令需要做的事情     
   //cache写类型                  
   assign cache_wtype     =   rcs_eq_write ? 2'b01  :rcs_eq_writeblock& (~uncache_en_buffer) ?   2'b10:2'b00;    
   
   //保存命中way_id，用store根据名way_id进行写   
   //cache维护指令在idle阶段记录下将要操作的cache的way            
   assign cache_wway_buffer_we =    rcs_eq_ridle  & cacop_en
                                    | rcs_eq_lookup & (~uncache_i) & cache_hit &cache_search_op;
   //往外界axi写数据 
   //uncache属性的store指令
   //cache属性的load/store指令                                   
   assign wr_req = rcs_eq_writeback & ( uncache_en_buffer&cache_search_op  | (~uncache_en_buffer&(cache_wway_buffer&cache_rdata[`Way1DLocation] |  (~cache_wway_buffer)&cache_rdata[`Way0DLocation])) );                         
   //保存替换way_id
   //code=2的不会如果没有命中，该指令就算完成了，所以触发页没有什么事情
   assign miss_replace_way_we =   rcs_eq_lookup&(~uncache_i)&(~cache_hit)  ;                  
  //请求读外界数据
   assign rd_req                =      rcs_eq_replace;         
   //接受外界读出数据的计数器             
   assign axi_write_count_we     =   rcs_eq_refill&ret_valid ;                 
   //清理计数器
   assign  axi_write_count_ce    =   rcs_eq_refill&ret_valid &ret_last;              
                     
         
        assign   cs_eq_ridle_ns =    respone_cacop_mode_zero ? WRITEBLOCK :
                                     respone_cacop_mode_one  | rcs_eq_ridle&store_buffer_we_i& uncache_en_buffer  ? MISS :
                                     rcs_eq_ridle&store_buffer_we_i&(~cache_wdata_buffer_valid) ? WRITE:
                                     respone_cacop_mode_tow |ridle_respone_load|ridle_respone_store ? READ:RIDLE;
                             
        assign cs_eq_read_ns   =   rcs_eq_read ?  (cpu_mmu_finish_i?LOOKUP:READ):RIDLE;
        
        assign looup_cacop_mode_tow_goon   =  cacop_en&cache_hit &cache_refill_valid_i;
        assign lookup_uncache_load_goon    = ~cacop_en&uncache_i &~cache_search_op&cache_refill_valid_i;
        assign lookup_cache_ls_nohit_goon  = ~cacop_en&~uncache_i&~cache_hit&cache_refill_valid_i;
           
        assign cs_eq_lookup_ns = ( 
                                   //look阶段指令完成，且没有第二阶段指令，如果没有cache维护指令的请求，但有ls的请求，则响应
                                   //本处为什么不使用lookup_can_respone_ls,因为响应ls有两种请求：1存在第二阶段指令，这种是要跳转lookup,2：不存在第二阶段指令，这种是要跳往read状态的
                                   lookup_req_finish_no_write_cache & ~search_buffer_we_count    &(~cacop_req_i)& (cache_re|cache_we)    
                                   |lookup_req_finish      & search_buffer_we_count&~cpu_mmu_finish_i
                                 ) ? READ :
                                (looup_cacop_mode_tow_goon|lookup_uncache_load_goon|lookup_cache_ls_nohit_goon)? MISS:
                                lookup_req_finish & search_buffer_we_count & cpu_mmu_finish_i?LOOKUP:RIDLE;
                                
        assign cs_eq_write_ns = write_req_finish_no_write_cache?READ:RIDLE; 
 
                                      
      assign cs_eq_miss_ns  =  (
                                    uncache_en_buffer & ( 
                                                            cache_search_op& wr_rdy    
                                                            | ~cache_search_op   
                                                         )
                                    | ~uncache_en_buffer 
                                 ) ? WRITEBACK : MISS;
    assign writeback_uncache_load_goon   = rcs_eq_writeback&~cacop_en&uncache_en_buffer&~cache_search_op;
    assign writeback_cache_ls_nohit_goon = rcs_eq_writeback&~cacop_en&~uncache_en_buffer                ;
    assign writeback_goon                = writeback_uncache_load_goon|writeback_cache_ls_nohit_goon    ;
    assign cs_eq_writeback_ns = cacop_en ? WRITEBLOCK :
                                (   
                                    writeback_req_finish_no_write_cache&(~search_buffer_valid)&(~cacop_req_i)&(cache_re|cache_we)
                                    |writeback_req_finish&search_buffer_we_count&~cpu_mmu_finish_i
                                )? READ :
                                writeback_req_finish&search_buffer_valid &cpu_mmu_finish_i ? LOOKUP :
                                writeback_goon?REPLACE:RIDLE;
    
    assign cs_eq_replace_ns    = rd_rdy ? REFILL : REPLACE;
    
    assign cs_eq_refill_ns     =  ret_last & ret_valid ? WRITEBLOCK : REFILL ;
     
    assign cs_eq_writeblock_ns = writeblock_req_finish&search_buffer_valid &cpu_mmu_finish_i ? LOOKUP :
                                 (  
                                    writeblock_req_finish_no_write_cache&~search_buffer_valid&(~cacop_req_i)&(cache_re|cache_we))
                                    |(writeblock_req_finish&search_buffer_valid &~cpu_mmu_finish_i
                                 )? READ :RIDLE; 
     
     
     
   
    
    
                                                 
    
    assign r_ns = rcs_eq_ridle         ?   cs_eq_ridle_ns      :      
                  rcs_eq_read          ?   cs_eq_read_ns       :
                  rcs_eq_lookup        ?   cs_eq_lookup_ns     :
                  rcs_eq_miss          ?   cs_eq_miss_ns       :
                  rcs_eq_write         ?   cs_eq_write_ns      :
                  rcs_eq_writeback     ?   cs_eq_writeback_ns  :
                  rcs_eq_replace       ?   cs_eq_replace_ns    :
                  rcs_eq_refill        ?   cs_eq_refill_ns     :
                  rcs_eq_writeblock    ?   cs_eq_writeblock_ns : RIDLE;
    
    
    
    
   
                 
   
   /******************************inner variable define(状态转移)*******************************/                        
 
 //主状态转移
    always @(posedge clk)begin
       if(~resetn)begin
           r_cs <= RIDLE;
       end else begin
           r_cs <= r_ns;
       end
    end  

   
 //在write状态，写的数据是缓存cpu的，其他状态来自随机计数器
  assign cache_wway    =  cache_wway_buffer  ;
  assign cache_w_index =  search_addr_buffer[11:4] ;//更新读index是确定的，随机的是way 
    
 //cache查找表  
   cache_table cache_table_item(
       .clk       (clk)    ,
       .req_i     (cache_en)    ,
       .r_index_i (cache_rindex)    ,
       .r_data_o  (cache_rdata)    ,              //(20+1+1+128)*2=300 
                  
                  
       .way_i     (cache_wway)    ,//写的数据，写往第几路
       .w_index_i (cache_w_index)    ,//写地址
       .w_type_i  (cache_wtype)    ,//10为全写，01为部分写，00表示不写
       .offset_i  (search_addr_buffer[3:0])    ,//部分写的块内偏移地址                                             
       .wstrb_i   (cache_wstr_buffer)    ,//部分写的字节使能
       .w_data_i  (cache_wdata)     //发生部分写，则使用[31:0]位

    ); 
    

    
  assign cs_o                     = r_cs                  ;
  assign uncache_en_buffer_o      = uncache_en_buffer     ;
  assign search_addr_buffer_o     = search_addr_buffer    ;
  assign exrt_axi_rdata_buffer0_o = exrt_axi_rdata_buffer0;
  assign exrt_axi_rdata_buffer1_o = exrt_axi_rdata_buffer1;
  assign exrt_axi_rdata_buffer2_o = exrt_axi_rdata_buffer2;
  assign exrt_axi_rdata_buffer3_o = exrt_axi_rdata_buffer3;
  assign way0_cache_hit_o         = way0_cache_hit        ;
  assign way1_cache_hit_o         = way1_cache_hit        ;
  assign search_buffer_o          = search_buffer          ;
  assign wait_dispose_inst_num_o = inst_num;
  
  assign diff_cache_en_o                = cache_en           ;
  assign diff_cache_rindex_o            = cache_rindex       ;
  assign diff_cache_raddr_o             = {tag,search_addr_buffer[11:0]};
  assign diff_cache_rdata_o             = cache_rdata        ;
  assign diff_cache_wway_o              = cache_wway         ;
  assign diff_cache_w_index_o           = cache_w_index      ;
  assign diff_cache_wtype_o             = cache_wtype        ;
  assign diff_search_offset_o           = search_addr_buffer[3:0] ;
  assign diff_cache_wdata_o             = cache_wdata        ;
     
endmodule