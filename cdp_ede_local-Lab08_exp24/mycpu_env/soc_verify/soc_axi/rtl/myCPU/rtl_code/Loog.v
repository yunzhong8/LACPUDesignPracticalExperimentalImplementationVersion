/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*
*/
/*************\
bug:
\*************/
//`include "DefineModuleBus.h"
`include "define.v"
module Loog(
    input  wire        clk,
    input  wire        rst_n,
    // inst sram interface
    output wire        inst_sram_req,
    output wire        inst_sram_wr,
    output wire [1:0]  inst_sram_size,
    output wire [3:0]  inst_sram_wstrb,
    output wire [3:0]  inst_sram_offset,
    output wire [7:0]  inst_sram_index,
    output wire [19:0] inst_sram_tag,
    output wire [31:0] inst_sram_wdata,
    output wire        inst_uncache_o,//if级给出
    output wire        inst_mmu_finish_o,
    output wire        inst_cache_refill_valid_o,
    //output wire [31:0]       inst_v_pc,
    
    input  wire        inst_sram_addr_ok ,
    input  wire        inst_sram_data_ok ,
    
    
    input  wire [63:0] inst_sram_rdata,
    // data sram interface
    
    output wire        data_sram_req,
    output wire        data_sram_wr ,
    output wire [1:0]  data_sram_size,
    output wire [3:0]  data_sram_wstrb ,
    output wire [3:0]  data_sram_offset,
    output wire [7:0]  data_sram_index,
    output wire [19:0] data_sram_tag,
    output wire [31:0] data_sram_wdata,
    output wire        data_uncache_o,//mem级给出D-cache的访问的是uncache
    output wire        data_store_buffer_ce_o,
    output wire        data_mmu_finish_o     ,
    //output wire [31:0]       data_v_addr,
    
    output wire        data_store_buffer_we_o,//D-cache需要将store_buffer中的数据写入cache
    output wire        data_cache_refill_valid_o,
    input  wire data_cache_free_i,
    input  wire inst_cache_free_i,
    
    input  wire        data_sram_addr_ok,
    input  wire        data_sram_data_ok,
    input  wire [31:0] data_sram_rdata,
    //硬件中断信号
    input wire [7:0] hardware_interrupt_data,
    
    output wire       inst_cacop_en_o             ,          
    output wire [1:0] inst_cacop_op_mode_o        ,    
    output wire [7:0] inst_cacop_op_addr_index_o   ,     
    output wire [3:0] inst_cacop_op_addr_offset_o ,    
    output wire [19:0]inst_cacop_op_addr_tag_o,        
   
    output wire       data_cacop_en_o             ,     
    output wire [1:0] data_cacop_op_mode_o        ,     
    output wire [7:0] data_cacop_op_addr_index_o  ,     
    output wire [19:0] data_cacop_op_addr_tag_o    ,     
    output wire [3:0] data_cacop_op_addr_offset_o ,     
                                            
    //cache错误信息
    input wire [`CacheDisposeInstNumWidth]inst_wait_dispose_inst_num_i,
    input wire [`CacheDisposeInstNumWidth]data_wait_dispose_inst_num_i,
    input wire inst_cache_error_i,
    input wire data_cache_error_i,
    
    //CPU错误信息
    output wire error_o,
    
    
    
    
    
    //差分测试接口
    output wire  [`OffcialWbToDiffBusWidth] wb_diiff_obus,
    output wire [`CsrToDiffBusWidth]   csr_diff_obus  ,
    output wire [`RegsToDiffBusWidth]  regs_diff_obus ,
    
    
    // trace debug interface
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_we,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);

/***************************************input variable define(输入变量定义)**************************************/

/***************************************output variable define(输出变量定义)**************************************/

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//PcBuffer
    wire [`PcBufferBusWidth]pcbuffer_to_pi_bus;

//PreIF
    wire [`PreifToNextBusWidth]preif_to_next_bus;
    wire preif_inst_sram_req;
    wire [`PcWidth]preif_inst_srtam_raddr;//依旧使用全长进行访问，高位补0希望使用的时候自己截断,
    wire preif_to_next_valid;
    wire [`PcBufferBusWidth]pi_to_pcbuffer_bus;
//Preif_IF
    wire if_valid;
   
 //分支预测
    wire [`PtoWbusWidth] ex_to_pr_bus; 
    wire [`PrToIfBusWidth]pr_to_if_bus;
 //uncache预测
    wire                 puc_to_pre_uncache;
    wire  [`PucWbusWidth]to_puc_wbus;
    wire  [`PucAddrWidth]to_puc_raddr;

//IF
    wire if_allowin;
    wire line1_if_to_next_valid;
    wire if_now_clk_ram_req;
    wire [`IfToPreBusWidth]if_to_pre_bus;
    
   
    wire [`IfToNextSignleBusWidth]if_to_next_signle_data_bus;
    wire [`IfToNextBusWidth]if_to_next_bus;
    
 //IFTwo阶段
    wire ift_allowin;
    wire line1_ift_to_next_valid;
    wire line2_ift_to_next_valid;
    
    wire [`IftToPreifBusWidth] ift_to_preif_bus;
    wire [`IfToICacheBusWidth]ift_to_icache_bus;
    wire [`IftToNextBusWidth]  ift_to_next_bus;    
    
    
    
//ID阶段
    wire id_allowin;
    wire line1_id_to_next_valid;
    wire line2_id_to_next_valid;
    
    wire [`IdToPreifBusWidth]id_to_preif_bus;
//    wire [`IdToPreBusWidth]id_to_pre_bus;
    wire [`IdToNextBusWidth]id_to_next_bus;
    
//Launch阶段
    wire la_allowin;
    wire line1_la_to_next_valid;
    wire line2_la_to_next_valid;
    wire [`LaunchToNextBusWidth]la_to_next_bus;
    wire [`RegsReadIbusWidth]reg_raddr_bus;
        
    
    
   // wire banch_flush;
//DataRealte
   wire [`RegsReadObusWidth]regs_rdata_bus;
   wire [`RegsRigthReadBusWidth]dr_to_id_bus;
//Rfb
   
    wire [`CsrToPreifWidth]csr_to_preif_bus;
    wire csr_interrupt_en;
    wire [63:0]countreg_to_id_bus;
    wire [`CsrToWbWidth]csr_to_wb_bus;
//EX
    wire ex_allowin;
    wire line1_ex_to_next_valid;
    wire line2_ex_to_next_valid;
    
    wire [`ExForwardBusWidth]ex_forward_bus;
    wire [`ExToDataBusWidth] ex_to_data_bus;
    wire [`ExToNextBusWidth]  ex_to_next_bus;
//MM    
    wire mm_allowin;
    wire  mm_valid;
    wire line1_mm_to_next_valid;
    wire line2_mm_to_next_valid;
    wire mm_now_clk_pre_cache_req;
    wire mm_store_buffer_ce;
    wire [`MmForwardBusWidth]mm_forward_bus;
    wire [`MmToNextBusWidth]mm_to_next_bus;
//MEMI
    wire                        mem_allowin;
    wire                        mem_valid;
    wire                        line1_mem_to_next_valid;
    wire                        line2_mem_to_next_valid;
    wire                        mem_store_buffer_ce;
    wire [`MemToNextBusWidth]     mem_to_next_bus;
    wire [`MemToPreBusWidth]     mem_to_pre_bus;
    wire [`MemForwardBusWidth]  mem_forward_bus;
   
//WB
    wire wb_allowin;
    wire line1_wb_to_next_valid;
    wire line2_wb_to_next_valid;
    
    wire wb_store_buffer_ce;
    wire [`RegsWriteBusWidth]wb_to_regs_bus ;                  
    wire  [`WbToCsrWidth]    wb_to_csr_bus; 
    wire [`WbToDebugBusWidth]wb_to_debug_bus; 
    wire [`ExcepToCsrWidth]  excep_to_csr_bus;
    
//MMU
    wire [`IfToMmuBusWidth] if_to_mmu_bus  ;            
    wire [`MemToMmuBusWidth]   mem_to_mmu_bus    ;              
    wire [`WbToMmuBusWidth]    wb_to_mmu_bus     ;//csr到mmu的数据  
    wire [`CsrToMmuBusWidth]   csr_to_mmu_bus    ;              
                                                        
    wire [`MmuToIfBusWidth]    mmu_to_if_bus  ;//取指令翻译结果    
    wire [`MmuToMemBusWidth]   mmu_to_mem_bus    ;//访存翻译结果       
    wire [`MmuToWbBusWidth]    mmu_to_wb_bus     ;//tlb读指令        
//cache
    wire [`MemToCacheBusWidth]  mem_to_cache_bus  ;
    wire [`WbToCacheBusWidth]   wb_to_cache_bus   ;
    
    
    wire       inst_cacop_en          ; 
    wire [13:0] inst_cacop_bus        ;  
    wire [19:0]inst_cacop_op_addr_tag ;   
                                              
    wire       data_cacop_en             ;   
    wire [13:0] data_cacop_bus           ;  
    wire [19:0]data_cacop_op_addr_tag    ;  
    
//差分测试
   wire [`ZzqWbToDiffBusWidth]    zzq_wb_to_diff_bus;     


//CPU内部出现设计中不可能出现的状态
 wire ift_error;
 wire id_error;
 wire la_error;
 wire mem_error;
 wire cpu_error;
 `ifdef OPEN_DIFF   
     wire diff_error;
 `endif
  
//冲刷信号
    wire excep_flush;//wb阶段各自冲刷:重取冲刷，例外冲刷，
    wire id_branch_flush;//id阶段发现跳转指令地址预测错误，进行冲刷
    wire ift_uncache_pre_error_flush ; //ift阶段发现对uncache属性预测错误，进行冲刷
   
    
    

/****************************************input decode(输入解码)***************************************/


/****************************************output code(输出解码)***************************************/

/*******************************complete logical function (逻辑功能实现)*******************************/

Error Error_item(
   .clk          ( clk )  ,
   .rst_n        ( rst_n )    ,
                
  .inst_cache_error_i (inst_cache_error_i ),
  .data_cache_error_i (data_cache_error_i ),
  
  .if_error_i    ( 1'b0)       ,
  .ift_error_i   (ift_error),
  .id_error_i    ( id_error )  ,
  .launch_error_i(la_error )       ,
  .ex_error_i    ( 1'b0)       ,
  .mm_error_i    ( 1'b0)       ,
  .mem_error_i   ( mem_error )      ,
  .wb_error_i    ( 1'b0 )      ,
//  .diff_error_i(diff_error),            
   .diff_error_i(1'b0),                 
    //发错错误
   .cpu_inner_error_o ( cpu_error)
   
);


assign error_o=cpu_error;








    PreifReg PcBuffer_item(
       // 时钟
       .rst_n(rst_n),                                       
       .clk(clk),  
       //冲刷信号     
       .excep_flush_i(excep_flush),
       //数据
       .inst_pc_buffer_i(pi_to_pcbuffer_bus),
       .inst_pc_buffer_o(pcbuffer_to_pi_bus)
    );
    
    
    
    //组合计算nextPC值
    PreIF PreIFI(
        //时钟
        .rst_n(rst_n),
        //握手
        .next_allowin_i(if_allowin),
        .now_to_next_valid_o(preif_to_next_valid),
        .excep_flush_i(excep_flush),
        
        //数据域
        .if_to_ibus   (if_to_pre_bus),
        .ift_to_ibus(ift_to_preif_bus),
        .id_to_ibus(id_to_preif_bus),
        .inst_ram_addr_ok_i(inst_sram_addr_ok),
        .pcbuffer_to_ibus(pcbuffer_to_pi_bus),
       //中断使能                    
         .interrupt_en_i            (csr_interrupt_en), 
       // cpu错误`
       .cpu_error_i(cpu_error),
        
        //例外
        .csr_to_ibus( csr_to_preif_bus ),
        
        .inst_sram_req_o(preif_inst_sram_req),
        .inst_sram_raddr_o (preif_inst_srtam_raddr),
        .to_pcbuffer_obus(pi_to_pcbuffer_bus),
        .to_next_obus(preif_to_next_bus)
        
    );
    
    
    
    Predactor Predactor_item(
            .rst_n         (rst_n),  
            .clk           (clk),
            .pc_i          (preif_inst_srtam_raddr),
            .if_allowin_i  (if_allowin),
            .to_if_obus    (pr_to_if_bus),
            .id_to_ibus    (ex_to_pr_bus)

    );
    
    Predactor_PUC Predactor_PUC_item(
             .rst_n      (rst_n)  ,
             .clk        (clk)  ,
             
             .raddr_i      (to_puc_raddr)  ,
             .uncache_o  (puc_to_pre_uncache)  ,
             .wbus_i     (to_puc_wbus)
    );                  
    
    
    
        
      IfStage IfStageI(
         //时钟                                                 
         .rst_n                     (rst_n            ),                                       
         .clk                       (clk               ),                                                    
         //握手                                                          
         .next_allowin_i            (ift_allowin),                                
         .pre_to_now_valid_i        (preif_to_next_valid),              
                  
                                                                       
         .line1_now_to_next_valid_o (line1_if_to_next_valid)   ,         
         .now_allowin_o             (if_allowin)   ,   
          //冲刷                      
         .excep_flush_i             (excep_flush),
         .other_flush_i             (id_branch_flush|ift_uncache_pre_error_flush),
         //中断使能                    
         //.interrupt_en_i            (csr_interrupt_en),         
    //数据域                                                
         .pre_to_ibus               (preif_to_next_bus) ,
         //预测
         .pr_to_ibus                (pr_to_if_bus), 
         .pre_uncache_i             ( puc_to_pre_uncache),
         .puc_raddr_o               (to_puc_raddr),
         
         .mmu_to_ibus               (mmu_to_if_bus),
         
         .if_now_clk_ram_req_o      (if_now_clk_ram_req),                                                
         .to_pre_obus               (if_to_pre_bus) , 
         .to_mmu_obus               (if_to_mmu_bus), 
         .to_next_signle_data_obus  (if_to_next_signle_data_bus)  ,    
         .to_next_obus              (if_to_next_bus)      
);                         
        
       //访问外部存储器                                                                             
           //assign inst_sram_en=inst_en_o;                                                  
           assign inst_sram_req   = preif_inst_sram_req;                                       
           assign inst_sram_wr    = 1'b0;                                                       
           assign inst_sram_size  = 2'd2;                                                     
           assign inst_sram_wstrb = 4'b0000;                                                 
           //assign inst_sram_addr = if_pc_o;                                                
           assign {inst_sram_index, inst_sram_offset} = preif_inst_srtam_raddr[11:0];        
           assign  inst_sram_tag                      = ift_to_icache_bus[19:0];                                   
           assign inst_sram_wdata                     = 32'h0000_0000;                                            
           assign inst_uncache_o                      = ift_to_icache_bus[20];                                     
           assign inst_cache_refill_valid_o           = ift_to_icache_bus[21];                          
           assign inst_mmu_finish_o                   = ift_allowin;
        
        
        
        
      IfTStage IfTStage_item(                                                                      
                .clk                        ( clk   )   ,                
                .rst_n                      ( rst_n )   ,                
                                                    
                .next_allowin_i             ( id_allowin )   ,                
                .line1_pre_to_now_valid_i   ( line1_if_to_next_valid )   ,                               
                                                         
                .line1_now_to_next_valid_o  ( line1_ift_to_next_valid )   ,                
                .line2_now_to_next_valid_o  ( line2_ift_to_next_valid )   ,                
                .now_allowin_o              ( ift_allowin )   ,                
                                             
                .excep_flush_i              ( excep_flush|id_branch_flush )   ,  
                .uncache_pre_error_flush_o  (ift_uncache_pre_error_flush)   ,//if阶段对uncache属性预测错误的冲刷          
                //错误
                .error_o                      ( ift_error),
                .cache_dispose_inst_num_i     ( inst_wait_dispose_inst_num_i),                                             
                .inst_sram_data_ok_i          ( inst_sram_data_ok )   , 
                .inst_sram_rdata_i            ( inst_sram_rdata  )   ,   
                                 
                .pre_to_ibus                  ( if_to_next_bus )   ,  
                .pre_to_next_signle_ibus      ( if_to_next_signle_data_bus),
                .now_clk_pre_inst_ram_req_i   (if_now_clk_ram_req),          
                              
                          
                .to_puc_obus                (to_puc_wbus),
                .to_preif_obus              ( ift_to_preif_bus),                                  
                .to_icache_obus             ( ift_to_icache_bus )   ,                
                .to_next_obus               ( ift_to_next_bus )                    
        );  
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
      
       IdStage IdStage_item(                                                                      
                .clk                        ( clk   )   ,                
                .rst_n                      ( rst_n )   ,                
                                                    
                .next_allowin_i             ( la_allowin )   ,                
                .line1_pre_to_now_valid_i   ( line1_ift_to_next_valid )   ,                
                .line2_pre_to_now_valid_i   ( line2_ift_to_next_valid )   ,                
                                                         
                .line1_now_to_next_valid_o  ( line1_id_to_next_valid )   ,                
                .line2_now_to_next_valid_o  ( line2_id_to_next_valid )   ,                
                .now_allowin_o              ( id_allowin )   ,                
                                             
                .excep_flush_i              ( excep_flush )   ,    
                .branch_flush_o             ( id_branch_flush)    ,//  对跳转指令预测错误的冲刷         
                //错误
                .error_o                     (id_error),
                                                       
                             
                .pre_to_ibus                ( ift_to_next_bus )   ,  
                
              
                          
                //.to_pre_obus                (id_to_pre_bus  ),  
                .to_preif_obus              (id_to_preif_bus),                                  
                          
                .to_next_obus               ( id_to_next_bus )                    
        );                                                                                   
      
             
        
    
        

Data_Relevant DRI(                
                    .ex_forward_ibus   (ex_forward_bus ),
                    .mm_forward_ibus   (mm_forward_bus),
                    .mem_forward_ibus  (mem_forward_bus),
                    
                    .regs_old_read_ibus  ({regs_rdata_bus,reg_raddr_bus}),
                    
                    .regs_rigth_read_obus (dr_to_id_bus)
                   );
                   
     Lanuch LanuchI(
        //时钟
        .rst_n(rst_n),
        .clk(clk),
        //握手
        .next_allowin_i(ex_allowin),    
        .line1_pre_to_now_valid_i(line1_id_to_next_valid),        
        .line2_pre_to_now_valid_i(line2_id_to_next_valid), 
        
        .line1_now_to_next_valid_o (line1_la_to_next_valid)   ,  
        .line2_now_to_next_valid_o (line2_la_to_next_valid)   ,  
        .now_allowin_o             (la_allowin)   ,
        //冲刷流水
        .excep_flush_i(excep_flush), 
        .error_o(la_error),                  
     
         //数据域
        .pre_to_ibus(id_to_next_bus),         
        .regs_rigth_read_ibus(dr_to_id_bus),                 
        .cout_to_ibus(countreg_to_id_bus ), 
          
        .regs_raddr_obus(reg_raddr_bus),  
        .to_next_obus (la_to_next_bus)   
        
      
     
     );

    Reg_File_Box RFI(
        .rst_n(rst_n),
        .clk(clk),
        
        .id_to_ibus(reg_raddr_bus),//id组合逻辑输出读地址
        .wb_to_regs_ibus(wb_to_regs_bus),//wb阶段输出写地址
        .wb_to_csr_ibus(wb_to_csr_bus),
        .excep_to_csr_ibus(excep_to_csr_bus),
        .hardware_interrupt_data_i(hardware_interrupt_data),
        
        .csr_to_diff_obus  (csr_diff_obus ),
        .regs_to_diff_obus (regs_diff_obus),
        
        
        .to_preif_obus (csr_to_preif_bus),
        .to_id_obus(regs_rdata_bus),//输出读出数据
        .countreg_to_id_obus(countreg_to_id_bus),
        .to_wb_obus(csr_to_wb_bus),
        .to_mmu_obus(csr_to_mmu_bus),
        .interrupt_en_o(csr_interrupt_en)
        
        
    );
    ExStage ExStageI(
        //时钟
        .clk                        ( clk                    )  ,
        .rst_n                      ( rst_n                  )  ,
        
        //握手
        .next_allowin_i             ( mem_allowin           )   ,                   
        .line1_pre_to_now_valid_i   ( line1_la_to_next_valid  )   ,        
        .line2_pre_to_now_valid_i   ( line2_la_to_next_valid  )   ,        
                                              
        .line1_now_to_next_valid_o  ( line1_ex_to_next_valid )   ,       
        .line2_now_to_next_valid_o  ( line2_ex_to_next_valid )   ,       
        .now_allowin_o              ( ex_allowin            )   ,      
        //冲刷·
        .excep_flush_i              ( excep_flush           )   ,  
        
        .next_stages_valid_i        (mm_valid|mem_valid),
        .data_sram_addr_ok_i        ( data_sram_addr_ok     )   , 
        .inst_cache_free_i          (inst_cache_free_i),
        .data_cache_free_i          (data_cache_free_i),
                    
                                          
     
        .pre_to_ibus                ( la_to_next_bus          )   ,               
        .next_to_ibus               ( 0         )   , 
        
          
         .inst_cacop_en_o            (inst_cacop_en),
         .inst_cacop_obus            (inst_cacop_bus),
         .data_cacop_en_o            (data_cacop_en),
         .data_cacop_obus            ( data_cacop_bus ),                            
        .forward_obus               ( ex_forward_bus        )   ,                      
        .to_data_obus               ( ex_to_data_bus        )   ,  
        .to_pr_obus                 ( ex_to_pr_bus          )   ,                 
        .to_next_obus               ( ex_to_next_bus         )  
                
    
    
    );
    
    
    
    assign{data_sram_req,data_sram_wr,data_sram_size,data_sram_wstrb,{data_sram_index, data_sram_offset},data_sram_wdata} = ex_to_data_bus;
    assign data_sram_tag          = mem_to_cache_bus[19:0];
    assign data_uncache_o         = mem_to_cache_bus[20];
    assign data_cache_refill_valid_o = mem_to_cache_bus[21];
    assign data_store_buffer_we_o = wb_to_cache_bus;
    
    
    assign inst_cacop_en_o     =inst_cacop_en;        
        
    assign {inst_cacop_op_mode_o,inst_cacop_op_addr_index_o,inst_cacop_op_addr_offset_o}= inst_cacop_bus;
    assign inst_cacop_op_addr_tag_o   = inst_cacop_op_addr_tag;
  
                          
    assign data_cacop_en_o    =     data_cacop_en     ;  
    assign {data_cacop_op_mode_o,data_cacop_op_addr_index_o, data_cacop_op_addr_offset_o} = data_cacop_bus ; 
      
    assign  data_cacop_op_addr_tag_o=  data_cacop_op_addr_tag; 
    
    
    
    
    
    
    
    
    
    
    
    
    MMStage MMStage_item(                                                         
           .clk                          ( clk    ) ,   
           .rst_n                        ( rst_n  ) ,   
                                         
           .next_allowin_i               ( mem_allowin  ) ,   
           .line1_pre_to_now_valid_i     ( line1_ex_to_next_valid  ) ,   
           .line2_pre_to_now_valid_i     ( line2_ex_to_next_valid  ) ,   
                                        
           .line1_now_to_next_valid_o    ( line1_mm_to_next_valid  ) ,   
           .line2_now_to_next_valid_o    ( line2_mm_to_next_valid  ) ,   
           .now_allowin_o                ( mm_allowin  ) ,  
           .now_valid_o                  ( mm_valid), 
                                        
           .excep_flush_i                ( excep_flush  ) ,   
                                                                                                  
           .pre_to_ibus                  ( ex_to_next_bus  ) ,   
           .next_to_ibus                 ( mem_to_pre_bus  ) ,  
           .mmu_to_ibus                  ( mmu_to_mem_bus), 
           
           .now_clk_pre_cache_req_o   (mm_now_clk_pre_cache_req),
           .to_mmu_obus                  ( mem_to_mmu_bus),
           .store_buffer_ce_o            (mm_store_buffer_ce),
           .forward_obus                 ( mm_forward_bus)   ,
           .to_next_obus                 ( mm_to_next_bus  )     
    );                                                                      
    
    
    assign data_mmu_finish_o =mem_allowin;
    assign data_store_buffer_ce_o = mem_store_buffer_ce|mm_store_buffer_ce|wb_store_buffer_ce;
    
//访问外部数据存储器
   MemStage MemStageI(
         //时钟                                    
         .rst_n(rst_n),                          
         .clk(clk),                              
         //握手                                    
         .next_allowin_i         (wb_allowin)       ,      
         .line1_pre_to_now_valid_i   (line1_mm_to_next_valid)      ,   
         .line2_pre_to_now_valid_i   (line2_mm_to_next_valid)      ,    
                                                            
         .line1_now_to_next_valid_o  (line1_mem_to_next_valid)       ,  
         .line2_now_to_next_valid_o  (line2_mem_to_next_valid)       ,  
         .now_allowin_o              (mem_allowin)      ,   
         .now_valid_o                ( mem_valid),
         //冲刷·                                   
         .excep_flush_i(excep_flush)   ,
         //错误
         .error_o(mem_error),
         .cache_dispose_inst_num_i(data_wait_dispose_inst_num_i),
         //数据域
         .pre_to_ibus  (mm_to_next_bus)    ,  
         .cache_rdata_ok_i(data_sram_data_ok),   
                
         .cache_rdata_i  (data_sram_rdata)   ,
         .now_clk_pre_cache_req_i(mm_now_clk_pre_cache_req),  
          
         .inst_cacop_op_addr_tag_o(inst_cacop_op_addr_tag),
         .data_cacop_op_addr_tag_o(data_cacop_op_addr_tag),           
         .forward_obus (mem_forward_bus)   ,
         .to_cache_obus(mem_to_cache_bus),       
         .to_pre_obus   (mem_to_pre_bus)  ,   
         .store_buffer_ce_o(mem_store_buffer_ce),        
         .to_next_obus (mem_to_next_bus)       
   
   );
    
   WbStage WbStageI(
          //时钟                                    
          .rst_n(rst_n),                          
          .clk(clk),                              
          //握手                                    
          .next_allowin_i         (1'b1)       ,      
          .line1_pre_to_now_valid_i   (line1_mem_to_next_valid)      ,   
          .line2_pre_to_now_valid_i   (line2_mem_to_next_valid)      ,    
                                                  
          .line1_now_to_next_valid_o  (line1_wb_to_next_valid)       ,  
          .line2_now_to_next_valid_o  (line2_wb_to_next_valid)       ,  
          .now_allowin_o              (wb_allowin)      ,   
          //冲刷·                                   
          .excep_flush_o      (excep_flush)     ,
          //数据域
          .pre_to_ibus        (mem_to_next_bus) ,              
          .csr_to_ibus        (csr_to_wb_bus) ,     
          .mmu_to_ibus        ( mmu_to_wb_bus),                  
          
          .zzq_wb_to_diff_obus     (zzq_wb_to_diff_bus),   
          .offcial_wb_to_diff_obus (wb_diiff_obus),
          
          .wb_to_debug_obus   (wb_to_debug_bus),                                      
          .wb_to_regs_obus    (wb_to_regs_bus) ,                   
          .wb_to_csr_obus     (wb_to_csr_bus) ,    
          .wb_to_mmu_obus     (wb_to_mmu_bus), 
          .to_cache_obus      (wb_to_cache_bus) ,   
          .store_buffer_ce_o  (wb_store_buffer_ce),                   
          .excep_to_csr_obus  (excep_to_csr_bus)                
   
   ); 
   
   
Mmu Mmu_item(

 .clk           (clk   ),    
 .rst_n         (rst_n ),                                             
                                                           
 .if_to_ibus    (if_to_mmu_bus) ,
 .mem_to_ibus   (mem_to_mmu_bus  ) ,
 .wb_to_ibus    (wb_to_mmu_bus   ) ,
 .csr_to_ibus   (csr_to_mmu_bus  ) ,
                                   
 .to_if_obus    (mmu_to_if_bus) ,
 .to_mem_obus   (mmu_to_mem_bus  ) ,
 .to_wb_obus    (mmu_to_wb_bus   ) 
);
 
 
 `ifdef OPEN_DIFF   
     wire diff_error;
     diff diff_item(
             .clk        (clk  ),
             .rst_n      (rst_n),
             .error_o(diff_error),
                         
             .wb_to_ibus (zzq_wb_to_diff_bus)
           
        );
   `endif
    
   
    assign debug_wb_rf_we    =  {4{wb_to_debug_bus[69]}};
    assign debug_wb_rf_wnum  =  wb_to_debug_bus[68:64];
    assign debug_wb_rf_wdata =  wb_to_debug_bus[63:32];
    assign debug_wb_pc       =  wb_to_debug_bus[31:0];  

endmodule
