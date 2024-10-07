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
    wire [31:0] cpu_inst_addr;
    wire [31:0] cpu_inst_wdata;
    
    wire cpu_inst_addr_ok ;
    wire cpu_inst_data_ok ;
    wire [31:0]cpu_inst_rdata;
    
    
    // data sram interface
    
    wire        cpu_data_req;
    wire        cpu_data_wr ;
    wire [1:0]  cpu_data_size;
    wire [3:0]  cpu_data_wstrb ;
    wire [31:0] cpu_data_addr;
    wire [31:0] cpu_data_wdata;
   
    wire  cpu_data_addr_ok;
    wire  cpu_data_data_ok;
    wire [31:0] cpu_data_rdata;
    wire [`SramIbusWidth]sram_ibus2,sram_ibus1;
    wire [`SramObusWidth]sram_obus2,sram_obus1;
    
//cp/*******************************complete logical function (逻辑功能实现)*******************************/u
Loog cpu(
    .clk              (aclk   ),
    .rst_n            (aresetn),  //low active

    .inst_sram_req    (cpu_inst_req    ),
    .inst_sram_wr     (cpu_inst_wr     ),
    .inst_sram_size   (cpu_inst_size   ),
    .inst_sram_wstrb  (cpu_inst_wstrb  ),
    .inst_sram_addr   (cpu_inst_addr   ),
    .inst_sram_wdata  (cpu_inst_wdata  ),
    .inst_sram_addr_ok(cpu_inst_addr_ok),
    .inst_sram_data_ok(cpu_inst_data_ok),
    .inst_sram_rdata  (cpu_inst_rdata  ),
    
    .data_sram_req    (cpu_data_req    ),
    .data_sram_wr     (cpu_data_wr     ),
    .data_sram_size   (cpu_data_size   ),
    .data_sram_wstrb  (cpu_data_wstrb  ),
    .data_sram_addr   (cpu_data_addr   ),
    .data_sram_wdata  (cpu_data_wdata  ),
    .data_sram_addr_ok(cpu_data_addr_ok),
    .data_sram_data_ok(cpu_data_data_ok),
    .data_sram_rdata  (cpu_data_rdata  ),
    //中断
    .hardware_interrupt_data(8'b0),

    //debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_we   (debug_wb_rf_we   ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);
assign sram_ibus1 = {cpu_inst_req,cpu_inst_wr,cpu_inst_size,cpu_inst_wstrb,cpu_inst_addr,cpu_inst_wdata  };
assign sram_ibus2 = {cpu_data_req,cpu_data_wr,cpu_data_size,cpu_data_wstrb,cpu_data_addr,cpu_data_wdata  };
assign {cpu_inst_addr_ok,cpu_inst_data_ok,cpu_inst_rdata} = sram_obus1;
assign {cpu_data_addr_ok,cpu_data_data_ok,cpu_data_rdata} = sram_obus2;

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