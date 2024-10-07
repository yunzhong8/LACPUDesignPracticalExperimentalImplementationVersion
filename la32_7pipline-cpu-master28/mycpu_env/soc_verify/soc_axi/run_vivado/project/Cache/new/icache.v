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
\*************/
//写会外部需要检测当前是否是脏数据，我没检查，只要miss就写回
//设备地址只返回一次valid,导致错误
//实现
`include"define.v"
module icache(
 input  wire                         clk                ,
 input  wire                         resetn             ,
 input  wire                         valid              ,//访问请求信号req，1表示有请求
 input  wire                         op                 ,//访问类型，0：req,1:write,we信号
 input  wire [`CacheOffsetWidth]     offset             ,//pc[3:0]
 input  wire [`CacheIndexWidth]      index              ,//pc[11:4]
 input  wire [`CacheTagWidth]        tag                ,//p_pc[31:12]
 
 input  wire                         uncache_i          ,
 input  wire                         store_buffer_we_i  ,
 input  wire                         store_buffer_ce_i  ,
 input  wire                         cache_refill_valid_i,
 input  wire                         cpu_mmu_finish_i,//表示在mmu那一级的指令可以流往译码级啦

 input  wire [`CacheWstrbWidth]      wstrb              ,//写字节使能
 input  wire [31:0]                  wdata              ,//cache写数据
                                                    
 output wire                         addr_ok            ,//输出已经接收地址ok
 output wire                         data_ok            ,//输出数据准备好啦
 output wire [63:0]                  rdata              ,//输出读出数据
                                                        
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
 
 
 
 output wire      [3:0]             cs_o                     ,          
 output wire                        uncache_en_buffer_o      ,
 output wire     [31:0]             search_addr_buffer_o     ,
 output wire     [31:0]             exrt_axi_rdata_buffer0_o ,
 output wire     [31:0]             exrt_axi_rdata_buffer1_o ,
 output wire     [31:0]             exrt_axi_rdata_buffer2_o ,
 output wire     [31:0]             exrt_axi_rdata_buffer3_o ,
 output wire                        way0_cache_hit_o         ,
 output wire                        way1_cache_hit_o         ,
 output wire     [299:0]            search_buffer_o           
 
 
 
 
 
            
    );
  
  
 /***************************************input variable define(输入变量定义)**************************************/
  /***************************************output variable define(输出变量定义)**************************************/
   wire[`CacheTagWidth]       wr_addr_tag_o   ;//cache写外部axi的标记字段p_pc[31:12]
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
  reg [3:0]r_cs,r_ns;
    
    
  /***************************************inner variable define(内部变量定义)**************************************/ 
  //缓存变量定义
   wire         search_tag_buffer_we   ;//缓存地址写使能    
   wire         search_index_buffer_we ;//写虚拟地址存储
   wire  [31:0]  search_addr_buffer     ;
   
         
   reg          search_buffer_we       ;
   reg          serach_buffer_ce       ;
   reg          search_buffer_valid    ;      
   reg  [299:0] search_buffer          ;//查找缓存区/      
                
   wire          cache_wway_buffer_we   ; 
   reg          cache_wway_buffer      ;
                      
   wire          cache_wdata_buffer_we  ;  
   reg [31:0]   cache_wdata_buffer     ;//缓存写数据  
   reg [3:0]    cache_wstr_buffer      ;//缓存写字节使能   
   //缓存uncache使能信号(所以lookup要对该信号进行缓存)
   //load是uncache则缺失查找状态转移需要这个信号进行控制
   //store是uncache则要缓存到wb阶段发出是否要执行的信号
   reg          uncache_en_buffer      ;
   wire          uncache_en_buffer_we   ;
   
  //缓存外部axi传入数据   
   wire [31:0] ret_wrote_data          ;//返回的是已经写入的数据  
   wire         axi_write_count_we      ; 
   reg  [1:0]  axi_write_count         ;//4个字 
   reg  [31:0] exrt_axi_rdata_buffer0,exrt_axi_rdata_buffer1,exrt_axi_rdata_buffer2,exrt_axi_rdata_buffer3;     
   
  //CacheTable需要的变量
   wire         cache_re,cache_we,no_cache_req      ;//cache请求：写使能，读使能
   wire          cache_search_op        ;//查找类型
   wire [299:0] cache_rdata            ;
   wire [149:0] cache_wdata            ;//cache待写回数据(只写一路的，所以是150)
   wire [31:0]  w_data0                ;
   wire [127:0] w_data                 ;//写回的128bit数据
   wire [19:0]  w_tag                  ;
   wire         w_v                    ;
   wire         w_d                    ;      
  //cache信号
   wire                     cache_en           ;//cache使能信号
   wire  [1:0]              cache_wtype        ;
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
   /***************************************inner variable define(逻辑实现)**************************************/  
  /******************************inner variable define(缓存实现)*******************************/  
  //缓存访问cache的地址
 //用于清理队列访问完的地址   
 wire search_addr_ce;
    
//访问地址和访问类型缓存队列    
Queue #(12)index_op_queue 
(
    .clk            (clk   )                  ,
    .rst_n          (resetn)                  ,
                  
    .we_i           (search_index_buffer_we)  ,
                   
    .wdata_i        ({op,index,offset})       ,
                 
    .used_i         (search_addr_ce)          ,
                 
    .full_o         ()                        ,
                   
    .rdata_o        ({cache_search_op,search_addr_buffer[11:0]}),
    .rdata_valid_o  ()
   
);

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
    
    
 
 wire search_buffer_we_count_start,search_buffer_ce; 
 reg search_buffer_we_count,search_buffer_ce_count;
 reg cache_wdata_buffer_valid;  
 always @(posedge clk)begin
     if(resetn == 1'b0)begin
           search_buffer <=300'd0;
           search_buffer_valid <= 1'b0;
     end else if(search_buffer_we_count)begin
        search_buffer_valid <= 1'b1;
        search_buffer <= cache_rdata; 
     end else if(search_buffer_ce  )begin
        search_buffer_valid <= 1'b0; 
        search_buffer <= 300'd0;
     end else begin
        search_buffer_valid <= search_buffer_valid ;
        search_buffer <= search_buffer;
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
  
    
  //缓存cpu写cache的数据
    always @(posedge clk)begin  
        //缓存读写路的id
       if(resetn == 1'b0)begin
           cache_wway_buffer <= 1'b0;
        end else if (cache_wway_buffer_we & way0_cache_hit)begin//查找命中的话，则根据查找出的数据所在路作为写入路
            cache_wway_buffer <= 1'b0;
        end else if (cache_wdata_buffer_we & way1_cache_hit)begin
            cache_wway_buffer <= 1'b1;
        end else if (miss_replace_way_we)begin//没有命中,store写的way_id是缺失替换的way_id(必须更改因为其是在回填结束的时候等store_buffer),load指令不关心这个,因为其是在回填的时候就会返回数据
            cache_wway_buffer <= rand_count;
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
    wire axi_write_count_ce;
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
    assign way0_cache_hit =   tag == search_buffer[`Way0TagLocation] && search_buffer[`Way0VLocation];
    assign way1_cache_hit =   tag == search_buffer[`Way1TagLocation] && search_buffer[`Way1VLocation];
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
    assign cache_wdata = {{w_v,w_tag},w_data,w_d};
 

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
                     miss_replace_way ? cache_rdata[`Way1DataLocation] : cache_rdata[`Way0DataLocation];//只选用查找缓存区的way0作为替换                   
  //暂时支持设备地址查找  
   assign rd_type = uncache_en_buffer? 3'b010:3'b100;
   /******************************inner variable define(各状态动作)*******************************/  
   wire rcs_eq_ridle     ;
   wire rcs_eq_read      ;
   wire rcs_eq_lookup    ;
   wire rcs_eq_miss      ;
   wire rcs_eq_write     ;
   wire rcs_eq_writeback ;
   wire rcs_eq_replace   ;
   wire rcs_eq_refill    ;
   wire rcs_eq_writeblock;
   assign rcs_eq_ridle      = r_cs==RIDLE      ;
   assign rcs_eq_read       = r_cs==READ       ; 
   assign rcs_eq_lookup     = r_cs==LOOKUP     ;
   assign rcs_eq_miss       = r_cs==MISS       ;
   assign rcs_eq_write      = r_cs==WRITE      ;
   assign rcs_eq_writeback  = r_cs==WRITEBACK  ;
   assign rcs_eq_replace    = r_cs==REPLACE    ;
   assign rcs_eq_refill     = r_cs==REFILL     ;
   assign rcs_eq_writeblock = r_cs==WRITEBLOCK ;
  
  
  
 
//发生请求响应需要做的事情  
    //load,store指令的响应                              
   assign addr_ok  =    rcs_eq_ridle &(cache_we|cache_re) //初始态有请求就读cache                                                                                                                                                   
                      | rcs_eq_read &cpu_mmu_finish_i &(~cache_search_op)&(cache_re|cache_we) //读状态必须当前指令能流往lookup才会响应请求指令       
                      //lookup,重填有效cache类，hit,read指令，(有第二阶段指令，且不是store指令，且下级允许输入|无第二阶段指令)&有新请求，read指令完成                                                                                          
                      | rcs_eq_lookup&(cpu_mmu_finish_i&(~uncache_i)&cache_hit &(~cache_search_op)&( search_buffer_we_count&cpu_mmu_finish_i&(~cache_wdata_buffer_valid) | ~search_buffer_we_count)&(cache_re|cache_we) 
                      //look，重填无效,sotre指令直接响应，read指令必须判断当前有没有第二阶段的指令
                                       |(~cpu_mmu_finish_i)&((~cache_search_op)&( search_buffer_we_count&cpu_mmu_finish_i&(~cache_wdata_buffer_valid) | ~search_buffer_we_count)|cache_search_op)&(cache_re|cache_we)
                                    );
    assign search_buffer_we_count_start  =  rcs_eq_ridle &(cache_we|cache_re) //初始态有请求就读cache
                                          |rcs_eq_read &cpu_mmu_finish_i &(~cache_search_op)&(cache_re|cache_we) //读状态必须当前指令能流往lookup才会响应请求指令
                                          //lookup,重填有效cache类，hit,read指令，(有第二阶段指令，且不是store指令，且下级允许输入|无第二阶段指令)&有新请求，read指令完成                                                                                          
                                          | rcs_eq_lookup&(cpu_mmu_finish_i&(~uncache_i)&cache_hit &(~cache_search_op)&( search_buffer_we_count&cpu_mmu_finish_i&(~cache_wdata_buffer_valid) | ~search_buffer_we_count)&(cache_re|cache_we) 
                                          //look，重填无效,sotre指令直接响应，read指令必须判断当前有没有第二阶段的指令
                                                        |(~cpu_mmu_finish_i)&((~cache_search_op)&( search_buffer_we_count&cpu_mmu_finish_i&(~cache_wdata_buffer_valid) | ~search_buffer_we_count)|cache_search_op)&(cache_re|cache_we)
                                                        );                  
                                         
    //缓存访问地址            
   assign search_index_buffer_we =    rcs_eq_ridle &(cache_we|cache_re) //初始态有请求就读cache                                                                                                                                                   
                                    | rcs_eq_read &cpu_mmu_finish_i &(~cache_search_op)&(cache_re|cache_we) //读状态必须当前指令能流往lookup才会响应请求指令                                                                                                  
                                    //lookup,重填有效cache类，hit,read指令，(有第二阶段指令，且不是store指令，且下级允许输入|无第二阶段指令)&有新请求，read指令完成                                                                                          
                                     | rcs_eq_lookup&(cpu_mmu_finish_i&(~uncache_i)&cache_hit &(~cache_search_op)&( search_buffer_we_count&cpu_mmu_finish_i&(~cache_wdata_buffer_valid) | ~search_buffer_we_count)&(cache_re|cache_we) 
                                     //look，重填无效,sotre指令直接响应，read指令必须判断当前有没有第二阶段的指令
                                                      |(~cpu_mmu_finish_i)&((~cache_search_op)&( search_buffer_we_count&cpu_mmu_finish_i&(~cache_wdata_buffer_valid) | ~search_buffer_we_count)|cache_search_op)&(cache_re|cache_we)
                                                   );                   
   
   //读cache                                  
   assign cache_en =   rcs_eq_ridle &(cache_we|cache_re) //初始态有请求就读cache
                     | rcs_eq_read &cpu_mmu_finish_i &(~cache_search_op)&(cache_re|cache_we) //读状态必须当前指令能流往lookup才会响应请求指令
                     //lookup,重填有效cache类，hit,read指令，(有第二阶段指令，且不是store指令，且下级允许输入|无第二阶段指令)&有新请求，read指令完成                                                                                          
                      | rcs_eq_lookup&(cpu_mmu_finish_i&(~uncache_i)&cache_hit &(~cache_search_op)&( search_buffer_we_count&cpu_mmu_finish_i&(~cache_wdata_buffer_valid) | ~search_buffer_we_count)&(cache_re|cache_we) 
                      //look，重填无效,sotre指令直接响应，read指令必须判断当前有没有第二阶段的指令
                                       |(~cpu_mmu_finish_i)&((~cache_search_op)&( search_buffer_we_count&cpu_mmu_finish_i&(~cache_wdata_buffer_valid) | ~search_buffer_we_count)|cache_search_op)&(cache_re|cache_we)
                                    )                   
                     | rcs_eq_miss&(~uncache_en_buffer)&wr_rdy;//miss状态要读出要替换的数据
                     
     //如果响应写指令，保存写指令的写数据          
   assign cache_wdata_buffer_we  =    rcs_eq_ridle &(cache_we) //初始态有请求就读cache         
                                    | rcs_eq_read &cpu_mmu_finish_i &(~cache_search_op)&(cache_we) //读状态必须当前指令能流往lookup才会响应请求指令 
                                    //lookup,重填有效cache类，hit,read指令，(有第二阶段指令，且不是store指令，且下级允许输入|无第二阶段指令)&有新请求，read指令完成                                                                                          
                                    | rcs_eq_lookup&(cpu_mmu_finish_i&(~uncache_i)&cache_hit &(~cache_search_op)&( search_buffer_we_count&cpu_mmu_finish_i&(~cache_wdata_buffer_valid) | ~search_buffer_we_count)&cache_we 
                                    //look，重填无效,sotre指令直接响应，read指令必须判断当前有没有第二阶段的指令
                                                     |(~cpu_mmu_finish_i)&((~cache_search_op)&( search_buffer_we_count&cpu_mmu_finish_i&(~cache_wdata_buffer_valid) | ~search_buffer_we_count)|cache_search_op)&cache_we
                                                     );
                                    
//lookup阶段需要做的事情                    
     //缓存物理地址，用于uncache,和cache发生缺失                 
   assign search_tag_buffer_we   =     rcs_eq_lookup;     
   //缓存uncache信号      
   assign uncache_en_buffer_we =  rcs_eq_lookup;    
   
//访问指令完成需要做的事情   
   //当前访问指令完成则要清理存储的访问信息                                                                                                                                  
     assign search_addr_ce =   rcs_eq_lookup&((~cache_refill_valid_i)| (cache_refill_valid_i&(~uncache_i)&cache_hit&(~cache_search_op)) )//重填无效的指令都要清理 .(重填有效&cache类&命中&读指令）要清理
                            | rcs_eq_writeback&uncache_en_buffer&cache_search_op//重填有效，uncache的store指令在write阶段清理
                            | rcs_eq_writeblock&(~cache_search_op)//回填结束 if 是重填有效，ucache类|（cache类，未命中） 读指令，则表明当前指令完成了要清理，                                                         
                            | rcs_eq_write;//是重填有效，cache类,（未命中|命中）store指令则在write阶段完成                                                                                        
                                                                                                                                                                           
    assign search_buffer_ce =   rcs_eq_lookup;    
    //访问指令完成                              
    assign data_ok  =   
                       rcs_eq_lookup&((~cache_refill_valid_i)| (cache_refill_valid_i&((~uncache_i)&cache_hit)|(uncache_i&cache_search_op) ))  //重填有效，且是cache类，(命中，则read,store都返回data_ok,if未命中，只能在wirebolck返回data_ok)              
                       |rcs_eq_writeblock;     
                                                                                                                             
//store指令需要做的事情     
   //cache写类型                  
   assign cache_wtype     =   rcs_eq_write ? 2'b01  :rcs_eq_writeblock& (~uncache_en_buffer) ?   2'b10:2'b00;    
   
   //保存命中way_id，用store根据名way_id进行写               
   assign cache_wway_buffer_we =  rcs_eq_lookup & (~uncache_i) & cache_hit &cache_search_op;
   //往外界axi写数据                                    
   assign wr_req = rcs_eq_writeback & ( uncache_en_buffer&cache_search_op  | (~uncache_en_buffer&(miss_replace_way&cache_rdata[`Way1DLocation] |  (~miss_replace_way)&cache_rdata[`Way0DLocation])) );                         
   //保存替换way_id
   assign miss_replace_way_we =   rcs_eq_lookup&(~uncache_i)&(~cache_hit)  ;                  
  //请求读外界数据
   assign rd_req        =      rcs_eq_replace;         
   //接受外界读出数据的计数器             
   assign axi_write_count_we     =   rcs_eq_refill&ret_valid ;                 
   //清理计数器
   assign  axi_write_count_ce    =   rcs_eq_refill&ret_valid &ret_last;              
                     
                     
                     
                     
                     
   
   /******************************inner variable define(状态转移)*******************************/                        
 //主状态机   
 always @(*)begin
    case(r_cs)
        RIDLE:begin         
             if(store_buffer_we_i)begin
                    if(uncache_en_buffer)begin
                        r_ns = MISS;
                    end else begin
                        r_ns = WRITE;
                    end
              
            end else if(cache_we|cache_re)begin//有写请求
                r_ns = READ;          
            end else begin//如果没有发来请求，则保持原状态             
                r_ns = RIDLE;
            end
        end READ:begin
             if(cpu_mmu_finish_i)begin
                  r_ns                   = LOOKUP;                     
             end else begin    
                  r_ns                   = READ;  
             end
        end LOOKUP:begin   
            //查找指令是uncache
            if(uncache_i)begin
                //读请求是uncache(对新请求不响应)
                if(~cache_search_op )begin
                    if(cache_refill_valid_i)begin
                        r_ns = MISS;
                    end else begin//重提填无效表明uncache的read指令完成了
                        if(search_buffer_we_count)begin //如果有第二阶段的指令
                            if(cpu_mmu_finish_i )begin  //第二阶段指令要流往第三阶段啦                            
                                r_ns = LOOKUP;                                                            
                            end else begin  //暂时不能流往第三阶段             
                                r_ns = READ;                                                            
                            end
                         end else begin    //没有第二阶段的指令                   
                            if(cache_re|cache_we)begin//有新的读请求                       
                                 r_ns = READ;                                                                                                       
                            end else begin //没有新请求                           
                               r_ns = RIDLE;                               
                                                                            
                            end                                                                                
                        end  
                                                              
                    end
                end else begin//写请求是uncache(简化对新请求不响应)
                    if(cache_re|cache_we)begin//有新的读请求                       
                                 r_ns = READ;                                                                                                       
                    end else begin //没有新请求                           
                               r_ns = RIDLE;                               
                                                                            
                     end             
                end        
            //cache
            end else begin
                //命中
                if(cache_hit)begin
                    //读请求命中
                    if(~cache_search_op)begin
                        if(search_buffer_we_count)begin 
                            if(cpu_mmu_finish_i )begin                              
                                r_ns = LOOKUP;                                                            
                            end else begin               
                                r_ns = READ;                                                            
                           end
                        end else begin                       
                            if(cache_re|cache_we)begin//有新的读请求                       
                                 r_ns = READ;                                                                                                       
                            end else begin //没有新请求                           
                               r_ns = RIDLE;                               
                                                                            
                            end                                                                                
                        end
                    end else begin//写请求命中
                            r_ns = RIDLE;                                                     
                    
                    end
                 end else begin //没有命中,(包含读命中和写命中都没命中)  
                    if(cache_refill_valid_i)begin                               
                        r_ns = MISS;
                    end else begin //重填无效    
                         if(~cache_search_op )begin
                                 if(search_buffer_we_count)begin //如果有第二阶段的指令
                                     if(cpu_mmu_finish_i )begin  //第二阶段指令要流往第三阶段啦                            
                                         r_ns = LOOKUP;                                                            
                                     end else begin  //暂时不能流往第三阶段             
                                         r_ns = READ;                                                            
                                    end
                                  end else begin    //没有第二阶段的指令                   
                                     if(cache_re|cache_we)begin//有新的读请求                       
                                          r_ns = READ;                                                                                                       
                                     end else begin //没有新请求                           
                                        r_ns = RIDLE;                               
                                                                                     
                                     end                                                                                
                                 end  
                         end else begin//写请求是uncache(简化对新请求不响应)
                             if(cache_re|cache_we)begin//有新的读请求                       
                                          r_ns = READ;                                                                                                       
                             end else begin //没有新请求                           
                                        r_ns = RIDLE;                               
                                                                                     
                              end             
                         end                                           
                    end
                end
            end
            
        end WRITE:begin//往cache内写数据            
            r_ns                  = RIDLE;                             
        
        end MISS:begin//读出要被替换的数据，等待外部允许接收写请求（替换的index和way是有随机产生的）                   
            if(uncache_en_buffer)begin
                if(cache_search_op)begin//sotre指令uncache是要等wready信号的
                    if(wr_rdy)begin
                        r_ns = WRITEBACK; 
                    end else begin
                        r_ns =MISS;
                    end  
                end else begin//读指令uncache则直接跳转
                    r_ns = WRITEBACK; 
                end           
            end else begin
                 if(wr_rdy)begin                   
                    r_ns = WRITEBACK;
                 end else begin               
                     r_ns = MISS;
                 end
            end
       
        end WRITEBACK:begin//将要替换cache行数据发到axi中（如果写回数据是脏数据则在本状态进行写回，如果非脏数据本状态不进行写会踩在）
            if(uncache_en_buffer)begin
              //store指令
                if(cache_search_op)begin//uncache的指令在writeback就完成了
                    r_ns = RIDLE;
                end else begin   //laod指令
                     r_ns = REPLACE;
                end 
            end else begin
                 r_ns = REPLACE;
                
            end      
        end REPLACE :begin//将读请求发给axi，直到axi接收到数据，就跳转到下一个状态
           if( rd_rdy)begin
               r_ns = REFILL;
           end else begin
               r_ns = REPLACE;
           end
           
        end REFILL:begin//准备接收axi读出数据
            //当前是uncache                 
            if(uncache_en_buffer)begin
                if(ret_last & ret_valid)begin
                     r_ns = WRITEBLOCK;
                 end else begin
                     r_ns = REFILL;
                 end
            //非uncache的写         
            end else if(ret_last & ret_valid)begin//如果当前数据是最后一个数据，则将当前数据和历史数据拼接，一同写入到cache中
                if(cache_search_op)begin//如果是写指令,外部写入cache完成后发出data_o
                    r_ns                   = RIDLE;  
                end  else  begin//如果是读指令的话，则返回data_ok 
                    r_ns = WRITEBLOCK;  
                end                                                                          
                
            end else  if (ret_valid)begin //查找，返回会数据有没有待查在的数据有则返回data_ok
                r_ns = REFILL;
            end           
        end WRITEBLOCK: begin
            if(search_buffer_valid)begin//如果有一条第二阶段的指令
                if(cpu_mmu_finish_i)begin//如果第二阶段指令可以流往第三阶段
                    r_ns                   = LOOKUP; 
                end else begin
                    r_ns                   = READ; 
                end
            end else begin
                 r_ns                   = RIDLE;      
            end                                                                 
        end default begin            
             r_ns                  = RIDLE;        
  
        end
    endcase
 end
 
 
 //主状态转移
    always @(posedge clk)begin
       if(~resetn)begin
           r_cs <= RIDLE;
       end else begin
           r_cs <= r_ns;
       end
    end  

   
 //在write状态，写的数据是缓存cpu的，其他状态来自随机计数器
  assign cache_wway    = (r_cs ==WRITE) ? cache_wway_buffer  :miss_replace_way;
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
    
  //Cache读出数据
 assign rdata = (rcs_eq_writeblock &data_ok ) ? (uncache_en_buffer ? (search_addr_buffer[2]?{ exrt_axi_rdata_buffer0,32'd0}:{ 32'd0,exrt_axi_rdata_buffer0}) : (search_addr_buffer[3]? {exrt_axi_rdata_buffer3,exrt_axi_rdata_buffer2} : {exrt_axi_rdata_buffer1,exrt_axi_rdata_buffer0})):
                way0_cache_hit ? (search_addr_buffer[3]? {search_buffer[`Way0Data3Location],search_buffer[`Way0Data2Location]}:{search_buffer[`Way0Data1Location],search_buffer[`Way0Data0Location]}) :
                way1_cache_hit ? (search_addr_buffer[3]? {search_buffer[`Way1Data3Location],search_buffer[`Way1Data2Location]}:{search_buffer[`Way1Data1Location],search_buffer[`Way1Data0Location]}) :64'd0;  
    
 
  assign cs_o                     = r_cs                  ;
  assign uncache_en_buffer_o      = uncache_en_buffer     ;
  assign search_addr_buffer_o     = search_addr_buffer    ;
  assign exrt_axi_rdata_buffer0_o = exrt_axi_rdata_buffer0;
  assign exrt_axi_rdata_buffer1_o = exrt_axi_rdata_buffer1;
  assign exrt_axi_rdata_buffer2_o = exrt_axi_rdata_buffer2;
  assign exrt_axi_rdata_buffer3_o = exrt_axi_rdata_buffer3;
  assign way0_cache_hit_o         = way0_cache_hit        ;
  assign way1_cache_hit_o         = way1_cache_hit        ;
  assign earch_buffer_o           = search_buffer          ;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
endmodule
