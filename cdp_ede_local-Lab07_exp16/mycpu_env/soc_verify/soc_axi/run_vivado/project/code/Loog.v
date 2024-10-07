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
`include "DefineModuleBus.h"
module Loog(
    input  wire        clk,
    input  wire        rst_n,
    // inst sram interface
    output wire        inst_sram_req,
    output wire        inst_sram_wr,
    output wire [1:0]  inst_sram_size,
    output wire [3:0]  inst_sram_wstrb,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input  wire inst_sram_addr_ok ,
    input  wire inst_sram_data_ok ,
    
    
    input  wire [31:0] inst_sram_rdata,
    // data sram interface
    
    output wire        data_sram_req,
    output wire        data_sram_wr ,
    output wire [1:0]  data_sram_size,
    output wire [3:0]  data_sram_wstrb ,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    
    input  wire  data_sram_addr_ok,
    input  wire  data_sram_data_ok,
    input  wire [31:0] data_sram_rdata,
    //硬件中断信号
    input wire [7:0] hardware_interrupt_data,
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
    wire [`PreifToIfBusWidth]preif_to_pi_bus;
    wire preif_inst_sram_req;
    wire preif_to_if_valid;
    wire [`PcBufferBusWidth]pi_to_pcbuffer_bus;
//Preif_IF
    wire if_valid;
    wire [`PreifToIfBusWidth] pi_to_if_bus;
   

//IF
    wire if_allowin;
    wire line1_if_to_id_valid;
    wire line2_if_to_id_valid;
    wire [`IfToPreifBusWidth]if_to_preif_bus;
    wire [`IfToICacheBusWidth]if_to_icache_bus;
    wire [`IfToIdBusWidth]if_to_id_bus;
    
//Icache
    wire [`ICacheReadObusWidth] icache_to_if_bus;
//ID阶段
    wire id_allowin;
    wire line1_id_to_ex_valid;
    wire line2_id_to_ex_valid;
    
    wire [`IdToPreifBusWidth]id_to_preif_bus;
    wire [`IdToIfBusWidth]id_to_if_bus;
    wire [`IdToExBusWidth]id_to_ex_bus;
    wire [`IdToRfbBusWidth]id_to_rfb_bus;
    wire banch_flush;
//DataRealte
   wire [`RfbToIdBusWidth]rfb_to_dr_bus;
   wire [`RegsRigthReadBusWidth]dr_to_id_bus;
//Rfb
   
    wire [`CsrToPreifWidth]csr_to_preif_bus;
    wire csr_interrupt_en;
    wire [63:0]countreg_to_id_bus;
    wire [`CsrToWbWidth]csr_to_wb_bus;
//EX
    wire ex_allowin;
    wire line1_ex_to_mem_valid;
    wire line2_ex_to_mem_valid;
    
    wire [`ExForwardBusWidth]ex_forward_bus;
    wire [`ExToDataBusWidth]ex_to_data_bus;
    wire [`ExToMemBusWidth]ex_to_mem_bus;

//MEMI
    wire mem_allowin;
    wire line1_mem_to_wb_valid;
    wire line2_mem_to_wb_valid;
    wire [`MemToWbBusWidth]mem_to_wb_bus;
    wire [`MemToExBusWidth]mem_to_ex_bus;
    wire [`MemForwardBusWidth]mem_forward_bus;
//WB
    wire wb_allowin;
    wire line1_wb_to_rfb_valid;
    wire line2_wb_to_rfb_valid;
    
    wire [`RegsWriteBusWidth]  wb_to_regs_bus ;                  
    wire  [`WbToCsrWidth] wb_to_csr_bus; 
    wire [`WbToDebugBusWidth]wb_to_debug_bus; 
    wire [`ExcepToCsrWidth]excep_to_csr_bus;
    wire excep_flush;

/****************************************input decode(输入解码)***************************************/


/****************************************output code(输出解码)***************************************/

/*******************************complete logical function (逻辑功能实现)*******************************/
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
        .now_to_next_valid_o(preif_to_if_valid),
        .excep_flush_i(excep_flush),
        
        //数据域
        .if_to_ibus   (if_to_preif_bus),
        .id_to_ibus(id_to_preif_bus),
        .inst_ram_addr_ok_i(inst_sram_addr_ok),
        .pcbuffer_to_ibus(pcbuffer_to_pi_bus),
        //例外
        .csr_to_ibus( csr_to_preif_bus ),
        
        .inst_sram_req_o(preif_inst_sram_req),
        .to_pcbuffer_obus(pi_to_pcbuffer_bus),
        .to_pi_obus(preif_to_pi_bus)
    );
    
        
      IfStage IfStageI(
         //时钟                                                 
         .rst_n(rst_n),                                       
         .clk(clk),                                                    
         //握手                                                          
         .next_allowin_i            (id_allowin),                                
         .pre_to_now_valid_i        (preif_to_if_valid),              
                  
                                                                       
         .line1_now_to_next_valid_o (line1_if_to_id_valid)   ,         
         .line2_now_to_next_valid_o (line2_if_to_id_valid)   ,         
         .now_allowin_o             (if_allowin)   ,   
          //冲刷                      
         .excep_flush_i             (excep_flush),
         .banch_flush_i             (banch_flush),
         //中断使能                    
         .interrupt_en_i            (csr_interrupt_en),         
    //数据域                                                
         .pre_to_ibus               (preif_to_pi_bus) ,
         .next_to_ibus              (id_to_if_bus),
         .inst_sram_data_ok_i       (inst_sram_data_ok),
         .inst_sram_rdata_i         (inst_sram_rdata)  ,   
         .icache_to_ibus            (icache_to_if_bus)  ,
         
                                                         
         .to_pre_obus               (if_to_preif_bus) ,        
         .to_icache_obus            (if_to_icache_bus)  ,    
         .to_next_obus              (if_to_id_bus)      
);                         
        
        
        
        
           
        
        
    //访问外部存储器
        //assign inst_sram_en=inst_en_o;
        assign inst_sram_req = preif_inst_sram_req;
        assign inst_sram_wr = 1'b0;
        assign inst_sram_size = 2'd2;
        assign inst_sram_wstrb = 4'b0000;
        //assign inst_sram_addr = if_pc_o;
        assign inst_sram_addr = preif_to_pi_bus[31:0];
        assign inst_sram_wdata= 32'h0000_0000;
        
        
    //访问cache
    Icache IcacheI(
            .rst_n        ( rst_n           )     ,
            .clk          ( clk            )      ,
            
            .read_ibus    (if_to_icache_bus[65:0]),
            .write_ibus   (if_to_icache_bus[`IfToICacheBusLen-1:66]),
            
            .read_obus    ( icache_to_if_bus)
            
     
    );

Data_Relevant DRI(                
                    .ex_forward_ibus   (ex_forward_bus ),
                    .mem_forward_ibus  (mem_forward_bus),
                    
                    .regs_old_read_ibus  ({rfb_to_dr_bus,id_to_rfb_bus}),
                    
                    .regs_rigth_read_obus (dr_to_id_bus)
                   );
                   
     Lanuch LanuchI(
        //时钟
        .rst_n(rst_n),
        .clk(clk),
        //握手
        .next_allowin_i(ex_allowin),    
        .line1_pre_to_now_valid_i(line1_if_to_id_valid),        
        .line2_pre_to_now_valid_i(line2_if_to_id_valid), 
        
        .line1_now_to_next_valid_o (line1_id_to_ex_valid)   ,  
        .line2_now_to_next_valid_o (line2_id_to_ex_valid)   ,  
        .now_allowin_o             (id_allowin)   ,
        //冲刷流水
        .excep_flush_i(excep_flush),   
        .banch_flush_o(banch_flush),                  
     
         //数据域
        .pre_to_ibus(if_to_id_bus),         
        .regs_rigth_read_ibus(dr_to_id_bus),                 
        .cout_to_ibus(countreg_to_id_bus ), 
         
        .to_pre_obus(id_to_if_bus),   
        .regs_raddr_obus(id_to_rfb_bus),  
        .to_next_obus (id_to_ex_bus) ,     
        .to_preif_obus(id_to_preif_bus)    
      
     
     );

    Reg_File_Box RFI(
        .rst_n(rst_n),
        .clk(clk),
        
        .id_to_ibus(id_to_rfb_bus),//id组合逻辑输出读地址
        .wb_to_regs_ibus(wb_to_regs_bus),//wb阶段输出写地址
        .wb_to_csr_ibus(wb_to_csr_bus),
        .excep_to_csr_ibus(excep_to_csr_bus),
        .hardware_interrupt_data_i(hardware_interrupt_data),
        
        .to_preif_obus (csr_to_preif_bus),
        .to_id_obus(rfb_to_dr_bus),//输出读出数据
        .countreg_to_id_obus(countreg_to_id_bus),
        .to_wb_obus(csr_to_wb_bus),
        .interrupt_en_o(csr_interrupt_en)
        
        
    );
    ExStage ExStageI(
        //时钟
        .rst_n(rst_n),
        .clk(clk),
        //握手
        .next_allowin_i            (mem_allowin)       ,                   
        .line1_pre_to_now_valid_i  (line1_id_to_ex_valid)      ,        
        .line2_pre_to_now_valid_i  (line2_id_to_ex_valid)      ,        
                                             
        .line1_now_to_next_valid_o  (line1_ex_to_mem_valid)       ,       
        .line2_now_to_next_valid_o  (line2_ex_to_mem_valid)       ,       
        .now_allowin_o             (ex_allowin)      ,      
        //冲刷·
        .excep_flush_i(excep_flush)   ,    
        .data_sram_addr_ok_i(data_sram_addr_ok),            
                                          
        .pre_to_ibus        (id_to_ex_bus) ,               
        .mem_to_ibus        (mem_to_ex_bus) ,              
                                           
        .forward_obus       (ex_forward_bus),                      
        .to_data_obus       (ex_to_data_bus) ,                 
        .to_next_obus       (ex_to_mem_bus)                    
    
    
    );
    
    
    
//    assign data_sram_req    = ex_to_data_bus[`EnLen+`EnLen+`MemWeLen+`MemAddrLen+`MemDataLen+1];
//    assign data_sram_wr     = data_sram_wstrb [`EnLen+`MemWeLen+`MemAddrLen+`MemDataLen+1];
//    assign data_sram_size   = ex_to_data_bus[`MemWeLen+`MemAddrLen+`MemDataLen+1:`MemWeLen+`MemAddrLen+`MemDataLen]; 
//    assign data_sram_wstrb  = ex_to_data_bus[`MemWeLen+`MemAddrLen+`MemDataLen-1:`MemAddrLen+`MemDataLen];
//    assign data_sram_addr   = ex_to_data_bus[`MemAddrLen+`MemDataLen-1:`MemDataLen];
//    assign data_sram_wdata  = ex_to_data_bus[`MemDataLen-1:0];
    assign{data_sram_req,data_sram_wr,data_sram_size,data_sram_wstrb,data_sram_addr,data_sram_wdata} = ex_to_data_bus;
    
//访问外部数据存储器
   MemStage MemStageI(
         //时钟                                    
         .rst_n(rst_n),                          
         .clk(clk),                              
         //握手                                    
         .next_allowin_i         (wb_allowin)       ,      
         .line1_pre_to_now_valid_i   (line1_ex_to_mem_valid)      ,   
         .line2_pre_to_now_valid_i   (line2_ex_to_mem_valid)      ,    
                                                            
         .line1_now_to_next_valid_o  (line1_mem_to_wb_valid)       ,  
         .line2_now_to_next_valid_o  (line2_mem_to_wb_valid)       ,  
         .now_allowin_o              (mem_allowin)      ,   
         //冲刷·                                   
         .excep_flush_i(excep_flush)   ,
         
         //数据域
         .pre_to_ibus  (ex_to_mem_bus)    ,  
         .data_sram_data_ok_i(data_sram_data_ok),                   
         .mem_rdata_i  (data_sram_rdata)   ,  
                     
         .forward_obus (mem_forward_bus)   ,       
         .to_ex_obus   (mem_to_ex_bus)  ,    
         .to_next_obus (mem_to_wb_bus)       
   
   );
    
   WbStage WbStageI(
          //时钟                                    
          .rst_n(rst_n),                          
          .clk(clk),                              
          //握手                                    
          .next_allowin_i         (1'b1)       ,      
          .line1_pre_to_now_valid_i   (line1_mem_to_wb_valid)      ,   
          .line2_pre_to_now_valid_i   (line2_mem_to_wb_valid)      ,    
                                                  
          .line1_now_to_next_valid_o  (line1_wb_to_rfb_valid)       ,  
          .line2_now_to_next_valid_o  (line2_wb_to_rfb_valid)       ,  
          .now_allowin_o              (wb_allowin)      ,   
          //冲刷·                                   
          .excep_flush_o      (excep_flush)     ,
          //数据域
          .pre_to_ibus        (mem_to_wb_bus) ,              
          .csr_to_ibus        (csr_to_wb_bus) ,                       
          
          .wb_to_debug_obus   (wb_to_debug_bus),                                      
          .wb_to_regs_obus    (wb_to_regs_bus) ,                   
          .wb_to_csr_obus     (wb_to_csr_bus) ,                    
          .excep_to_csr_obus  (excep_to_csr_bus)                
   
   ); 
    
    
    
   
    
   
    assign debug_wb_rf_we    =  {4{wb_to_debug_bus[69]}};
    assign debug_wb_rf_wnum  =  wb_to_debug_bus[68:64];
    assign debug_wb_rf_wdata =  wb_to_debug_bus[63:32];
    assign debug_wb_pc       =  wb_to_debug_bus[31:0];  

endmodule
