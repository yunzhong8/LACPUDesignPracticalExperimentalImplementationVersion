//`include "DefineModuleBus.h"
`include "define.v"
module mycpu_top(
    input  wire        aclk,
    input  wire        aresetn,
        //ar                                                
    output  wire [3 :0] arid   ,                        
    output  wire [31:0] araddr ,                        
    output  wire [7 :0] arlen  ,                        
    output  wire [2 :0] arsize ,                        
    output  wire [1 :0] arburst,                        
    output  wire [1 :0] arlock ,                        
    output  wire [3 :0] arcache,                        
    output  wire [2 :0] arprot ,                        
    output  wire        arvalid,                        
    input wire          arready,                          
    //r                                                   
    input wire [3 :0] rid    ,                          
    input wire [31:0] rdata  ,                          
    input wire [1 :0] rresp  ,                          
    input wire        rlast  ,                          
    input wire        rvalid ,                          
    output  wire      rready ,                        
    //aw                                                  
    output  wire [3 :0] awid   ,                        
    output  wire [31:0] awaddr ,                        
    output  wire [7 :0] awlen  ,                        
    output  wire [2 :0] awsize ,                        
    output  wire [1 :0] awburst,                        
    output  wire [1 :0] awlock ,                        
    output  wire [3 :0] awcache,                        
    output  wire [2 :0] awprot ,                        
    output  wire        awvalid,                        
    input wire          awready,                          
    //w                                                   
    output  wire [3 :0] wid    ,                        
    output  wire [31:0] wdata  ,                        
    output  wire [3 :0] wstrb  ,                        
    output  wire        wlast  ,                        
    output  wire        wvalid ,                        
    input wire          wready ,                          
    //b                                                   
    input wire [3 :0] bid    ,                          
    input wire [1 :0] bresp  ,                          
    input wire        bvalid ,                          
    output  wire      bready,     
    //cpu 
    output wire error_o, 
    //trace 
    output wire [31:0] debug_wb_pc,                           
    output wire [ 3:0] debug_wb_rf_we,                        
    output wire [ 4:0] debug_wb_rf_wnum,                      
    output wire [31:0] debug_wb_rf_wdata                      
                        
                     

);


/***************************************input variable define(输入变量定义)**************************************/

     wire                         inst_rd_req        ;
     wire [2:0]                   inst_rd_type       ;
     wire [31:0]                  inst_rd_addr       ;
                                                    
     wire                         inst_rd_rdy        ;
     wire                         inst_ret_valid     ;
     wire                         inst_ret_last      ;
     wire [31:0]                  inst_ret_data      ;
                                                   
     wire                         inst_wr_req        ;
     wire [2:0]                   inst_wr_type       ;
     wire [31:0]                  inst_wr_addr       ;
     wire [3:0]                   inst_wr_wstrb      ;
     wire [`CacheBurstDataWidth]  inst_wr_data       ;
     wire                         inst_wr_rdy        ;
                                                     
     wire                         data_rd_req        ;
     wire [2:0]                   data_rd_type       ;
     wire [31:0]                  data_rd_addr       ;
                                                    
     wire                         data_rd_rdy        ;
     wire                         data_ret_valid     ;
     wire                         data_ret_last      ;
     wire [31:0]                  data_ret_data      ;
                                                     
     wire                         data_wr_req        ;
     wire [2:0]                   data_wr_type       ;
     wire [31:0]                  data_wr_addr       ;
     wire [3:0]                   data_wr_wstrb      ;
     wire [`CacheBurstDataWidth]  data_wr_data       ;
     wire                         data_wr_rdy        ;   
                                                            
    
    
 
    wire [`SramIbusWidth]sram_ibus2,sram_ibus1;
    wire [`SramObusWidth]sram_obus2,sram_obus1;
    
    
//cp/*******************************complete logical function (逻辑功能实现)*******************************/u
mycpu_cache_top  mycpu_cache_item (

         .aclk           (aclk   ),     
         .aresetn        (aresetn),     
                            
                            
         .inst_rd_req_o      (inst_rd_req    ),//输出类AXI读请求                            
         .inst_rd_type_o     (inst_rd_type   ),//输出类AXI读请求类型                          
         .inst_rd_addr_o     (inst_rd_addr   ),//输出类AXI读请求的起始地址                       
                            
         .inst_rd_rdy_i      (inst_rd_rdy    ),//AXI转接桥输入可以读啦，read_ready  ,addr_ok            
         .inst_ret_valid_i   (inst_ret_valid ),//axi转接桥输入读回数据read_data_valid ,data_ok        
         .inst_ret_last_i    (inst_ret_last  ),//axi转接桥输入这是最后一个读回数据，为什么是两位的？？？？       
         .inst_ret_data_i    (inst_ret_data  ),//axi转接桥输入的读回数据                        
                             
         .inst_wr_req_o      (inst_wr_req    ),//类AXI输出的写请求                           
         .inst_wr_type_o     (inst_wr_type   ),//类AXI输出的写请求类型                         
         .inst_wr_addr_o     (inst_wr_addr   ),//类AXI输出的写地址                           
         .inst_wr_wstrb_o    (inst_wr_wstrb  ),//写操作掩码                                
         .inst_wr_data_o     (inst_wr_data   ),//类AXI输出的写数据128bit                     
         .inst_wr_rdy_i      (inst_wr_rdy  ),//AXI总线输入的写完成信号，可以接收写请求                
                            
                            
         .data_rd_req_o      (data_rd_req    ),//输出类AXI读请求                            
         .data_rd_type_o     (data_rd_type   ),//输出类AXI读请求类型                          
         .data_rd_addr_o     (data_rd_addr   ),//输出类AXI读请求的起始地址                       
                            
         .data_rd_rdy_i      (data_rd_rdy    ),//AXI转接桥输入可以读啦，read_ready              
         .data_ret_valid_i   (data_ret_valid ),//axi转接桥输入读回数据read_data_valid         
         .data_ret_last_i    (data_ret_last  ),//axi转接桥输入这是最后一个读回数据，为什么是两位的？？？？       
         .data_ret_data_i    (data_ret_data  ),//axi转接桥输入的读回数据                        
                             
         .data_wr_req_o      (data_wr_req    ),//类AXI输出的写请求                           
         .data_wr_type_o     (data_wr_type   ),//类AXI输出的写请求类型                         
         .data_wr_addr_o     (data_wr_addr   ),//类AXI输出的写地址                           
         .data_wr_wstrb_o    (data_wr_wstrb  ),//写操作掩码                                
         .data_wr_data_o     (data_wr_data   ),//类AXI输出的写数据128bit                     
         .data_wr_rdy_i      (data_wr_rdy    ),//AXI总线输入的写完成信号，可以接收写请求                
         //中断
         .hardware_interrupt_data(8'b0),
         //CPU错误信息
         .error_o (error_o),
         //debug interface
         .debug_wb_pc      (debug_wb_pc      ),
         .debug_wb_rf_we   (debug_wb_rf_we   ),
         .debug_wb_rf_wnum (debug_wb_rf_wnum ),
         .debug_wb_rf_wdata(debug_wb_rf_wdata)
         );
assign sram_ibus1 = {inst_rd_req,inst_rd_type,inst_rd_addr,
                    inst_wr_req,inst_wr_type,inst_wr_addr,inst_wr_wstrb,inst_wr_data  };
                    
assign sram_ibus2 = {data_rd_req,data_rd_type,data_rd_addr,
                     data_wr_req,data_wr_type,data_wr_addr,data_wr_wstrb,data_wr_data};
                     
assign {inst_ret_last,inst_wr_rdy,inst_ret_valid,inst_rd_rdy,inst_ret_data} = sram_obus1;
assign {data_ret_last,data_wr_rdy,data_ret_valid,data_rd_rdy,data_ret_data} = sram_obus2;

sramaxibridge sramaxibridge_item(
    //时钟
      .clk      (aclk),
      .rst_n    (aresetn),
    //sram1
    .sram_ibus1(sram_ibus1),
    .sram_ibus2(sram_ibus2),
    .sram_obus1(sram_obus1),
    .sram_obus2(sram_obus2),
    //sram2
    
    //axi
    //ar
  .m_arid   (arid   ),
  .m_araddr (araddr ),
  .m_arlen  (arlen  ),
  .m_arsize (arsize ),
  .m_arburst(arburst),
  .m_arlock (arlock ),
  .m_arcache(arcache),
  .m_arprot (arprot ),
  .m_arvalid(arvalid),
  .m_arready(arready),
  //r
  .m_rid    (rid   ),
  .m_rdata  (rdata ),
  .m_rresp  (rresp ),
  .m_rlast  (rlast ),
  .m_rvalid (rvalid),
  .m_rready (rready),
 //aw
  .m_awid   (awid   ),
  .m_awaddr (awaddr ),
  .m_awlen  (awlen  ),
  .m_awsize (awsize ),
  .m_awburst(awburst),
  .m_awlock (awlock ),
  .m_awcache(awcache),
  .m_awprot (awprot ),
  .m_awvalid(awvalid),
  .m_awready(awready),
  //w
  .m_wid    (wid   ),
  .m_wdata  (wdata ),
  .m_wstrb  (wstrb ),
  .m_wlast  (wlast ),
  .m_wvalid (wvalid),
  .m_wready (wready),
  //b
  .m_bid    (bid   ),
  .m_bresp  (bresp ),
  .m_bvalid (bvalid),
  .m_bready (bready)
  );
  
  
  
  
  endmodule