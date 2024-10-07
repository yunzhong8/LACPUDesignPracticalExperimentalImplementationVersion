`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/28 16:33:54
// Design Name: 
// Module Name: mycpu_cache_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "DefineModuleBus.h"

module mycpu_cache_top(
    input  wire                         aclk                      ,
    input  wire                         aresetn                   ,
    
    //指令
    output wire                          inst_rd_req_o             ,//输出类AXI读请求                                          
    output wire [2:0]                   inst_rd_type_o            ,//输出类AXI读请求类型                                        
    output wire [31:0]                  inst_rd_addr_o            ,//输出类AXI读请求的起始地址    
                                     
    input  wire                         inst_rd_rdy_i             ,//AXI转接桥输入可以读啦，read_ready                            
    input  wire                         inst_ret_valid_i           ,//axi转接桥输入读回数据read_data_valid                       
    input  wire                         inst_ret_last_i           ,//axi转接桥输入这是最后一个读回数据，为什么是两位的？？？？                     
    input  wire [31:0]                  inst_ret_data_i           ,//axi转接桥输入的读回数据                                      
                                                                                                            
    output wire                         inst_wr_req_o             ,//类AXI输出的写请求                                         
    output wire [2:0]                   inst_wr_type_o            ,//类AXI输出的写请求类型                                       
    output wire [31:0]                  inst_wr_addr_o            ,//类AXI输出的写地址                                         
    output wire [3:0]                   inst_wr_wstrb_o           ,//写操作掩码                                              
    output wire  [`CacheBurstDataWidth] inst_wr_data_o            ,//类AXI输出的写数据128bit                                   
    input  wire                         inst_wr_rdy_i             ,//AXI总线输入的写完成信号，可以接收写请求                 
    
    //数据
    output wire                         data_rd_req_o             ,//输出类AXI读请求                                              
    output wire [2:0]                   data_rd_type_o            ,//输出类AXI读请求类型                               
    output wire [31:0]                  data_rd_addr_o            ,//输出类AXI读请求的起始地址
                                
    input  wire                         data_rd_rdy_i             ,//AXI转接桥输入可以读啦，read_ready                   
    input  wire                         data_ret_valid_i           ,//axi转接桥输入读回数据read_data_valid              
    input  wire                         data_ret_last_i           ,//axi转接桥输入这是最后一个读回数据，为什么是两位的？？？？            
    input  wire [31:0]                  data_ret_data_i           ,//axi转接桥输入的读回数据                             
                                                                                                    
    output wire                         data_wr_req_o             ,//类AXI输出的写请求                                
    output wire [2:0]                   data_wr_type_o            ,//类AXI输出的写请求类型                              
    output wire [31:0]                  data_wr_addr_o            ,//类AXI输出的写地址                                
    output wire [3:0]                   data_wr_wstrb_o           ,//写操作掩码                                     
    output wire  [`CacheBurstDataWidth] data_wr_data_o            ,//类AXI输出的写数据128bit                          
    input  wire                         data_wr_rdy_i             , //AXI总线输入的写完成信号，可以接收写请求                     
      
    //硬件中断信号
    input wire [7:0] hardware_interrupt_data,
    
    //CPU内部错误信息
    output wire error_o ,
      //trace 
    output wire [31:0] debug_wb_pc,                           
    output wire [ 3:0] debug_wb_rf_we,                        
    output wire [ 4:0] debug_wb_rf_wnum,                      
    output wire [31:0] debug_wb_rf_wdata                      
                        

    );
 /***************************************input variable define(输入变量定义)**************************************/

    wire        cpu_inst_req;
    wire        cpu_inst_wr;
    wire [1:0]  cpu_inst_size;
    wire [3:0]  cpu_inst_wstrb;
    
    wire [3:0]  cpu_inst_offset ; 
    wire [7:0]  cpu_inst_index  ;  
    wire [19:0] cpu_inst_tag    ;    
    wire [31:0] cpu_inst_wdata;
    wire        inst_uncache;
    wire        inst_mmu_finish;
    wire inst_cache_refill_valid;
    
    wire cpu_inst_addr_ok ;
    wire cpu_inst_data_ok ;
    wire [63:0]cpu_inst_rdata;
    
    
    // data sram interface
    
    wire        cpu_data_req;
    wire        cpu_data_wr ;
    wire [1:0]  cpu_data_size;
    wire [3:0]  cpu_data_wstrb ;
  
    wire [3:0]  cpu_data_offset ; 
    wire [7:0]  cpu_data_index  ;  
    wire [19:0] cpu_data_tag    ;    
    
 
    wire [31:0] cpu_data_wdata;
    wire        data_uncache;      
    wire        data_store_buffer_we;
    wire       data_cache_refill_valid;
    wire data_store_buffer_ce;
    wire data_mmu_finish     ;
    
    wire  cpu_data_addr_ok;
    wire  cpu_data_data_ok;
    wire [31:0] cpu_data_rdata;
    //cache空闲
    wire inst_cache_free ,data_cache_free ;
    
    reg          memref_valid;
    wire         memref_op;
    wire [  7:0] in_index;
    wire [ 19:0] in_tag;
    wire [  3:0] in_offset;
    wire [ 31:0] memref_data;
    wire [  3:0] memref_wstrb;
    
    wire         cache_addr_ok;
    wire         out_valid;
    wire [ 31:0] cacheres;
        
    wire         rd_req;
    wire [  2:0] rd_type;
    wire [ 31:0] rd_addr;
    wire         rd_rdy;
    wire         ret_valid;
    wire         ret_last;
    wire [ 31:0] ret_data;
    
    wire         wr_req;
    wire [  2:0] wr_type;
    wire [ 31:0] wr_addr;
    wire [  3:0] wr_wstrb;
    wire [127:0] wr_data;
    wire         wr_rdy;
    
    
    wire      [3:0]             inst_cs                     ;     
    wire                        inst_uncache_en_buffer      ;     
    wire     [31:0]             inst_search_addr_buffer     ;     
    wire     [31:0]             inst_exrt_axi_rdata_buffer0 ;     
    wire     [31:0]             inst_exrt_axi_rdata_buffer1 ; 
    wire     [31:0]             inst_exrt_axi_rdata_buffer2 ; 
    wire     [31:0]             inst_exrt_axi_rdata_buffer3 ; 
    wire                        inst_way0_cache_hit         ;     
    wire                        inst_way1_cache_hit        ;     
    wire     [299:0]            inst_search_buffer         ;     
                                                              
    wire      [3:0]             data_cs                     ;  
    wire                        data_uncache_en_buffer      ;  
    wire     [31:0]             data_search_addr_buffer     ;  
    wire     [31:0]             data_exrt_axi_rdata_buffer0 ;  
    wire     [31:0]             data_exrt_axi_rdata_buffer1 ; 
    wire     [31:0]             data_exrt_axi_rdata_buffer2 ; 
    wire     [31:0]             data_exrt_axi_rdata_buffer3 ; 
    wire                        data_way0_cache_hit         ;  
    wire                        data_way1_cache_hit         ;  
    wire     [299:0]            data_search_buffer          ;  
                                                                 
    
    
    //cache维护指令
    wire inst_cacop_en             ;
    wire [1:0] inst_cacop_op_mode        ;
    wire [7:0] inst_cacop_op_addr_index  ;
    wire [19:0] inst_cacop_op_addr_tag    ;       
    wire [3:0]inst_cacop_op_addr_offset ;
   
    wire       data_cacop_en            ;
    wire [1:0] data_cacop_op_mode       ;
    wire [7:0] data_cacop_op_addr_index ;
    wire [19:0] data_cacop_op_addr_tag   ;
    wire [3:0]data_cacop_op_addr_offset;
    
    //error信息
    wire [`CacheDisposeInstNumWidth]inst_wait_dispose_inst_num,data_wait_dispose_inst_num;
    wire data_cache_error,inst_cache_error;
    
/*******************************complete logical function (逻辑功能实现)*******************************/ 
  Loog cpu(
    .clk              (aclk   ),
    .rst_n            (aresetn),  //low active

    .inst_sram_req    (cpu_inst_req    ),//out
    .inst_sram_wr     (cpu_inst_wr     ),//out
    .inst_sram_size   (cpu_inst_size   ),//out
    .inst_sram_wstrb  (cpu_inst_wstrb  ),//out
    .inst_sram_offset (cpu_inst_offset ),//out
    .inst_sram_index  (cpu_inst_index  ),//out
    .inst_sram_tag    (cpu_inst_tag    ),//out
    .inst_sram_wdata  (cpu_inst_wdata  ),//out
    .inst_uncache_o   (inst_uncache    ),  
    .inst_mmu_finish_o(inst_mmu_finish),   
    .inst_cache_refill_valid_o (inst_cache_refill_valid),
    //.v_pc_i             (),
    .inst_cache_free_i (inst_cache_free ),
    .inst_sram_addr_ok(cpu_inst_addr_ok),//input
    .inst_sram_data_ok(cpu_inst_data_ok),//input
    
    .inst_sram_rdata  (cpu_inst_rdata  ),//input
    
    .data_cache_free_i (data_cache_free ),
    .data_sram_req    (cpu_data_req    ),//out
    .data_sram_wr     (cpu_data_wr     ),//out
    .data_sram_size   (cpu_data_size   ),//out
    .data_sram_wstrb  (cpu_data_wstrb  ),//out
    .data_sram_offset (cpu_data_offset ),
    .data_sram_index  (cpu_data_index  ), 
    .data_sram_tag    (cpu_data_tag    ),      
    .data_sram_wdata  (cpu_data_wdata  ),//out
    .data_uncache_o   (data_uncache    ),
    .data_store_buffer_we_o (data_store_buffer_we),
    .data_store_buffer_ce_o(data_store_buffer_ce),
    .data_mmu_finish_o     (data_mmu_finish     ),   
    .data_cache_refill_valid_o (data_cache_refill_valid),
    
    .data_sram_addr_ok(cpu_data_addr_ok),//input
    .data_sram_data_ok(cpu_data_data_ok),//input
    
    .data_sram_rdata  (cpu_data_rdata  ),//input
    //中断
    .hardware_interrupt_data(hardware_interrupt_data),//input
    
    //cache维护
    .data_cacop_en_o            (data_cacop_en            ),
    .data_cacop_op_mode_o       (data_cacop_op_mode       ),
    .data_cacop_op_addr_index_o (data_cacop_op_addr_index ),
    .data_cacop_op_addr_tag_o   (data_cacop_op_addr_tag   ),
    .data_cacop_op_addr_offset_o(data_cacop_op_addr_offset),
    
    .inst_cacop_en_o              (inst_cacop_en            ),
    .inst_cacop_op_mode_o         (inst_cacop_op_mode       ),
    .inst_cacop_op_addr_index_o   (inst_cacop_op_addr_index ),
    .inst_cacop_op_addr_tag_o     (inst_cacop_op_addr_tag   ),
    .inst_cacop_op_addr_offset_o  (inst_cacop_op_addr_offset),
    
    //cache错误信息
    .inst_wait_dispose_inst_num_i(inst_wait_dispose_inst_num),
    .data_wait_dispose_inst_num_i(data_wait_dispose_inst_num),
    .inst_cache_error_i           (inst_cache_error),
    .data_cache_error_i           (data_cache_error),
    //CPU错误信息
    .error_o                      (error_o),

    //debug interface
    .debug_wb_pc      (debug_wb_pc      ),//output
    .debug_wb_rf_we   (debug_wb_rf_we   ),//output
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),//output
    .debug_wb_rf_wdata(debug_wb_rf_wdata) //output
);  
    



cache icache_item(
    .clk    (aclk),//input
    .resetn (aresetn),//input
    
    .valid  (cpu_inst_req),//input
    .op     (cpu_inst_wr ), //input
    .offset (cpu_inst_offset), //input
    .index  (cpu_inst_index  ), //input
    .tag    (cpu_inst_tag     ), //input
    
    .cacop_req_i                (inst_cacop_en            ),     
    .cacop_op_mode_i           (inst_cacop_op_mode       ),
    .cacop_op_addr_index_i     (inst_cacop_op_addr_index ),
    .cacop_op_addr_tag_i       (inst_cacop_op_addr_tag   ),
    .cacop_op_addr_offset_i    (inst_cacop_op_addr_offset),
    
    
    
    
    
    
    
    
    
    
    
    .uncache_i        (inst_uncache),
    .store_buffer_we_i(1'b0),
    .store_buffer_ce_i(1'b0),
    .cpu_mmu_finish_i(inst_mmu_finish),
    .cache_refill_valid_i(inst_cache_refill_valid),
    .v_pc_i(),
    .wstrb  (cpu_inst_wstrb ),//input
    .wdata  (cpu_inst_wdata),//input

    .addr_ok(cpu_inst_addr_ok),//output
    .data_ok(cpu_inst_data_ok),//output
   //.rdata  (cpu_inst_rdata ),//output

    .rd_req   (inst_rd_req_o   ),//output
    .rd_type  (inst_rd_type_o  ),//output
    .rd_addr  (inst_rd_addr_o  ),//output
    
    .rd_rdy   (inst_rd_rdy_i   ),//intput
    .ret_valid(inst_ret_valid_i),//intput
    .ret_last (inst_ret_last_i ),//intput
    .ret_data (inst_ret_data_i ),//intput

    .wr_req   (inst_wr_req_o     ),//output
    .wr_type  (inst_wr_type_o    ),//output
    .wr_addr  (inst_wr_addr_o    ),//output
    .wr_wstrb (inst_wr_wstrb_o   ),//output
    .wr_data  (inst_wr_data_o    ),//output
    .wr_rdy   (inst_wr_rdy_i     ), //input
    
    .error_o                  (inst_cache_error),
    .wait_dispose_inst_num_o  (inst_wait_dispose_inst_num),
    .cache_free_o             ( inst_cache_free             ),
    .cs_o                     ( inst_cs                     ),     
    .uncache_en_buffer_o      ( inst_uncache_en_buffer      ),
    .search_addr_buffer_o     ( inst_search_addr_buffer     ),
    .exrt_axi_rdata_buffer0_o ( inst_exrt_axi_rdata_buffer0 ),
    .exrt_axi_rdata_buffer1_o ( inst_exrt_axi_rdata_buffer1 ),
    .exrt_axi_rdata_buffer2_o ( inst_exrt_axi_rdata_buffer2 ),
    .exrt_axi_rdata_buffer3_o ( inst_exrt_axi_rdata_buffer3 ),
    .way0_cache_hit_o         ( inst_way0_cache_hit         ),
    .way1_cache_hit_o         ( inst_way1_cache_hit         ),
    .search_buffer_o          ( inst_search_buffer          )
                                 
    
);   


 parameter WRITEBLOCK = 4'b1000;//8写完要阻塞一个时钟周期才允许读
   //Cache读出数据  
   assign cpu_inst_rdata = (inst_cs==WRITEBLOCK &cpu_inst_data_ok ) ? (inst_uncache_en_buffer ? (inst_search_addr_buffer[2]?{ inst_exrt_axi_rdata_buffer0,32'd0}:{ 32'd0,inst_exrt_axi_rdata_buffer0}) : (inst_search_addr_buffer[3]? {inst_exrt_axi_rdata_buffer3,inst_exrt_axi_rdata_buffer2} : {inst_exrt_axi_rdata_buffer1,inst_exrt_axi_rdata_buffer0})):  
                  inst_way0_cache_hit ? (inst_search_addr_buffer[3]? {inst_search_buffer[`Way0Data3Location],inst_search_buffer[`Way0Data2Location]}:{inst_search_buffer[`Way0Data1Location],inst_search_buffer[`Way0Data0Location]}) :  
                  inst_way1_cache_hit ? (inst_search_addr_buffer[3]? {inst_search_buffer[`Way1Data3Location],inst_search_buffer[`Way1Data2Location]}:{inst_search_buffer[`Way1Data1Location],inst_search_buffer[`Way1Data0Location]}) :64'd0;    
    
    










 
    
    
cache dcache_item(
    .clk    (aclk),//input
    .resetn (aresetn),//input
    
    .valid  (cpu_data_req),//input
    .op     (cpu_data_wr), //input
    
    .offset (cpu_data_offset ), //input
    .index  (cpu_data_index  ), //input
    .tag    (cpu_data_tag    ), //input
    
    .cacop_req_i                (data_cacop_en            ),     
    .cacop_op_mode_i           (data_cacop_op_mode       ),
    .cacop_op_addr_index_i     (data_cacop_op_addr_index ),
    .cacop_op_addr_tag_i       (data_cacop_op_addr_tag   ),
    .cacop_op_addr_offset_i    (data_cacop_op_addr_offset),
    
    
    
  
    
    .uncache_i        (data_uncache),
    .store_buffer_we_i(data_store_buffer_we),
    .store_buffer_ce_i(data_store_buffer_ce),  
    .cpu_mmu_finish_i(data_mmu_finish),   
    .cache_refill_valid_i(data_cache_refill_valid),
    
    
    .wstrb  (cpu_data_wstrb),//input
    .wdata  (cpu_data_wdata),//input

    .addr_ok(cpu_data_addr_ok),//output
    .data_ok(cpu_data_data_ok),//output
    //.rdata  (cpu_data_rdata ),//output

    .rd_req   (data_rd_req_o   ),//output
    .rd_type  (data_rd_type_o  ),//output
    .rd_addr  (data_rd_addr_o  ),//output
    
    .rd_rdy   (data_rd_rdy_i   ),//intput
    .ret_valid(data_ret_valid_i),//intput
    .ret_last (data_ret_last_i ),//intput
    .ret_data (data_ret_data_i ),//intput

    .wr_req  (data_wr_req_o   ),//output
    .wr_type (data_wr_type_o  ),//output
    .wr_addr (data_wr_addr_o  ),//output
    .wr_wstrb(data_wr_wstrb_o ),//output
    .wr_data (data_wr_data_o  ),//output
    .wr_rdy  (data_wr_rdy_i   ), //input
    
    .error_o                  (data_cache_error),
    .wait_dispose_inst_num_o  (data_wait_dispose_inst_num),
    .cache_free_o             ( data_cache_free             ),
    .cs_o                     ( data_cs                     ),
    .uncache_en_buffer_o      ( data_uncache_en_buffer      ),
    .search_addr_buffer_o     ( data_search_addr_buffer     ),
    .exrt_axi_rdata_buffer0_o ( data_exrt_axi_rdata_buffer0 ),
    .exrt_axi_rdata_buffer1_o ( data_exrt_axi_rdata_buffer1 ), 
    .exrt_axi_rdata_buffer2_o ( data_exrt_axi_rdata_buffer2 ), 
    .exrt_axi_rdata_buffer3_o ( data_exrt_axi_rdata_buffer3 ), 
    .way0_cache_hit_o         ( data_way0_cache_hit         ),
    .way1_cache_hit_o         ( data_way1_cache_hit         ),
    .search_buffer_o          ( data_search_buffer          ) 
      
);   
//Cache读出数据
 assign cpu_data_rdata = (data_cs==WRITEBLOCK &&cpu_data_data_ok ) ? 
                (data_uncache_en_buffer?data_exrt_axi_rdata_buffer0 :
                    data_search_addr_buffer[3:2]==2'b00 ? data_exrt_axi_rdata_buffer0:                               
                    data_search_addr_buffer[3:2]==2'b01 ? data_exrt_axi_rdata_buffer1:                               
                    data_search_addr_buffer[3:2]==2'b10 ? data_exrt_axi_rdata_buffer2:data_exrt_axi_rdata_buffer3) :
 
                data_way0_cache_hit ? (data_search_addr_buffer[3:2]==2'b00 ? data_search_buffer[`Way0Data0Location]:
                                       data_search_addr_buffer[3:2]==2'b01 ? data_search_buffer[`Way0Data1Location]:
                                       data_search_addr_buffer[3:2]==2'b10 ? data_search_buffer[`Way0Data2Location]:data_search_buffer[`Way0Data3Location]) :
                data_way1_cache_hit ? (data_search_addr_buffer[3:2]==2'b00 ? data_search_buffer[`Way1Data0Location]://又是赋值粘贴导致没有修改,造成错误
                                       data_search_addr_buffer[3:2]==2'b01 ? data_search_buffer[`Way1Data1Location]:
                                       data_search_addr_buffer[3:2]==2'b10 ? data_search_buffer[`Way1Data2Location]:data_search_buffer[`Way1Data3Location]) :32'd0;  
 
   
    
endmodule
