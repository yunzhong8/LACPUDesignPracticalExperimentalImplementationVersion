
/*
*作者：zzq
*创建时间：2023-04-22
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*
*/
/*************\
bug:
1. 握手信号的组合逻辑环查找方式，就是将握手信号删掉在看
2. 当冲刷信号有效的时候要求清空除法器，即复位除法器，我没有做导致错误，
3. 较为幸运的是我给exe设置了阻塞，也就是说EXE后续流水的指令可能发生例外冲刷，EXE就会阻塞不动，旧不会发出req请求，也就是说该阶段读写数据是不会发生变化的
4. 写 ifelse的时候else忘记写啦
\*************/
`include "DefineModuleBus.h"
module sramaxibridge(
    //时钟
    input  wire  clk      ,
    input  wire  rst_n    ,
    //sram1
    input  wire [`SramIbusWidth]sram_ibus1,
    input  wire [`SramIbusWidth]sram_ibus2,
    output wire [`SramObusWidth]sram_obus1,
    output wire [`SramObusWidth]sram_obus2,
    //sram2
    
    //axi
    //ar
  output  reg  [3 :0] m_arid   ,
  output  reg  [31:0] m_araddr ,
  output  wire [7 :0] m_arlen  ,//不涉及
  output  reg  [2 :0] m_arsize ,
  output  wire [1 :0] m_arburst,//不涉及
  output  wire [1 :0] m_arlock ,//不涉及
  output  wire [3 :0] m_arcache,//不涉及
  output  wire [2 :0] m_arprot ,//不涉及
  output  reg         m_arvalid,
  input   wire        m_arready,
  //r
  input  wire [3 :0] m_rid    ,
  input  wire [31:0] m_rdata  ,
  input  wire [1 :0] m_rresp  ,
  input  wire        m_rlast  ,
  input  wire        m_rvalid ,
  output reg         m_rready ,
  //aw
  output  wire [3 :0] m_awid   ,//不涉及
  output  reg [31:0] m_awaddr ,
  output  wire [7 :0] m_awlen  ,//不涉及
  output  reg [2 :0] m_awsize ,
  output  wire [1 :0] m_awburst,//不涉及
  output  wire [1 :0] m_awlock ,//不涉及
  output  wire [3 :0] m_awcache,//不涉及
  output  wire [2 :0] m_awprot ,//不涉及
  output  reg        m_awvalid,
  input   wire        m_awready,
  //w
  output  wire [3 :0] m_wid    ,//不涉及
  output  reg  [31:0] m_wdata  ,
  output  reg  [3 :0] m_wstrb  ,
  output  wire        m_wlast  ,//不涉及
  output  reg         m_wvalid ,
  input   wire        m_wready ,
  //b
  input   wire [3 :0] m_bid    ,//不涉及
  input   wire [1 :0] m_bresp  ,//不涉及
  input   wire        m_bvalid ,
  output  reg        m_bready 

         
);

/***************************************input variable define(输入变量定义)**************************************/
  wire        sram2_req_i,sram1_req_i;  
  wire        sram2_wr_i,sram1_wr_i;       
  wire [1:0]  sram2_size_i,sram1_size_i;    
  wire [3:0]  sram2_wstrb_i,sram1_wstrb_i;
  wire [31:0] sram2_addr_i,sram1_addr_i;    
  wire [31:0] sram2_wdata_i,sram1_wdata_i;   
  reg sram1_addr_ok_o;        
  reg sram1_data_ok_o;
  wire sram2_addr_ok_o;
  wire sram2_data_ok_o;
  
  reg [31:0] sram2_rdata_o,sram1_rdata_o;   
  reg      sram2_raddr_ok_o,sram2_waddr_ok_o;
  reg      sram2_rdata_ok_o,sram2_wdata_ok_o;

//固定读请求通道
assign m_arlen = 0;
assign m_arburst = 2'b01;
assign m_arlock = 0;
assign m_arcache = 0;
assign m_awprot = 0;
//写请求通道
assign m_awid = 4'b0001;
assign m_awlen = 7'd0;
assign m_awburst = 2'b01;
assign m_awlock  = 0; 
assign m_awcache = 0; 
assign m_awprot  = 0;
//写数据通道
assign m_wid = 4'b0001;
assign m_wlast = 1'b1;











/***************************************output variable define(输出变量定义)**************************************/

/***************************************parameter define(常量定义)**************************************/
  parameter REmpty = 2'b00;//读初始状态
 
  parameter RWaitExtAXIAcceptAddr= 2'b10;//读等待外部AIX接受地址
  parameter RWaitExtAXIAcceptAddrData= 2'b01;//读等待外部AIX接受地址
  parameter RWaitExtAXIData=2'b11;
  
  parameter WEmpty = 3'b000;//读初始状态
  
   parameter WAcceptCPUData = 3'b001;//读持续接受CPU数据`
   parameter WWaitExtAXIAcceptAddrData = 3'b010;//读持续接受CPU数据`
   parameter WWaitExtAXIAcceptData = 3'b011;//读持续接受CPU数据`
   parameter WWaitExtAXIAcceptAddr = 3'b100;//读持续接受CPU数据`
   parameter WWaitExtAXIWriteFnish = 3'b101;
   reg[1:0]r_cs,r_ns;
   reg [2:0]w_cs,w_ns;
  
/***************************************inner variable define(内部变量定义)**************************************/

wire now_write_arrive,now_writing;//表示当前没有正在写数据
wire now_read_arrive,now_reading;
/****************************************input decode(输入解码)***************************************/
assign   {sram1_req_i,sram1_wr_i,sram1_size_i,sram1_wstrb_i,sram1_addr_i,sram1_wdata_i}=sram_ibus1;
assign   {sram2_req_i,sram2_wr_i,sram2_size_i,sram2_wstrb_i,sram2_addr_i,sram2_wdata_i}=sram_ibus2;
/****************************************output code(输出解码)***************************************/
assign sram_obus1 = {sram1_addr_ok_o,sram1_data_ok_o,sram1_rdata_o};
assign sram_obus2 = {sram2_addr_ok_o,sram2_data_ok_o,sram2_rdata_o};

//当正在读的时装周期，则有读控制，没有正在读的时钟周期：不是正在写，并且不是写到达，且读到达的时候，由读控制
assign sram2_data_ok_o = now_reading||(now_read_arrive && ! now_writing && !now_write_arrive) ? sram2_rdata_ok_o :sram2_wdata_ok_o;
assign sram2_addr_ok_o = now_reading||(now_read_arrive && ! now_writing && !now_write_arrive) ? sram2_raddr_ok_o :sram2_waddr_ok_o;
/****************************************output code(内部解码)***************************************/

/*******************************complete logical function (逻辑功能实现)*******************************/

assign now_write_arrive = w_cs!=REmpty;//已经开始执行写啦
assign now_writing =  (w_cs==REmpty) && sram2_req_i && sram2_wr_i;//有写请求来访

assign now_read_arrive =  (r_cs == REmpty && (sram2_req_i && !sram2_wr_i) ||(sram1_req_i && !sram1_wr_i));//读请求信号在当前时钟刚到
assign now_reading = r_cs != REmpty;//当前已经读状态



//确定du下一个状态//状态执行功能
/*握手信号类型有
 //CPU                   
 sram1_addr_ok_o = 1'b0; 
 sram2_addr_ok_o = 1'b0; 
 sram1_data_ok_o = 1'b0; 
 sram2_data_ok_o = 1'b0; 
 //AXI                   
 m_arvalid = 1'b1;       
 m_rready = 1'b0;       
*/
//状态位和握手信号else必须写，数据域可以不写
always @ *begin
    case(r_cs)
        REmpty:begin
        //CPU握手信号
          sram1_data_ok_o = 1'b0; 
          sram2_rdata_ok_o = 1'b0;
        //AXI握手信号
          m_arvalid = 1'b0;  
          m_rready = 1'b0;
            if(sram2_req_i && !sram2_wr_i && (!now_write_arrive) && (!now_writing)) begin//数据读
                 r_ns = RWaitExtAXIAcceptAddr;  //下一个状态
                 m_arid = 4'b1;//数据域
                 m_araddr = sram2_addr_i;
                 m_arsize = sram2_size_i;
                 //握手信号
                 sram1_addr_ok_o = 1'b0; 
                 sram2_raddr_ok_o = 1'b1;                  
            end else if(sram1_req_i && !sram1_wr_i && (!now_write_arrive) && (!now_writing))begin//指令读
                r_ns = RWaitExtAXIAcceptAddr;
                m_arid = 4'b0;
                m_araddr = sram1_addr_i;
                m_arsize = sram1_size_i;
                //握手信号
                sram1_addr_ok_o = 1'b1;
                sram2_raddr_ok_o = 1'b0;  
            end else begin
                 r_ns = REmpty;
                 sram1_addr_ok_o = 1'b0;
                 sram2_raddr_ok_o = 1'b0;  
            end
        end RWaitExtAXIAcceptAddr:begin//等待外部axi接收读地址
             //CPU
             sram1_addr_ok_o = 1'b0;
             sram2_raddr_ok_o = 1'b0;
             sram1_data_ok_o = 1'b0;
             sram2_rdata_ok_o = 1'b0;
             //AXI
             m_arvalid = 1'b1; 
             m_rready = 1'b0;
            if(m_arready)begin
                r_ns=RWaitExtAXIData;
            end else begin
                r_ns=RWaitExtAXIAcceptAddr;
            end
        end RWaitExtAXIData:begin//等待外部axi传入读出数据
            //CPU
            sram1_addr_ok_o = 1'b0;
            sram2_raddr_ok_o = 1'b0;
            //AXI
            m_arvalid = 1'b0;
            m_rready = 1'b1;
            if(m_rvalid && m_rid==4'b1)begin//数据读出
                r_ns = REmpty;
                sram1_data_ok_o = 1'b0;
                sram2_rdata_ok_o = 1'b1;
                sram2_rdata_o = m_rdata;
            end else if(m_rvalid && m_rid==4'b0)begin//又是忘记写else，导致双if
                r_ns = REmpty;
                sram1_data_ok_o = 1'b1; 
                sram2_rdata_ok_o = 1'b0;
                sram1_rdata_o = m_rdata;
            end else begin
                r_ns = RWaitExtAXIData;
                sram2_rdata_ok_o = 1'b0;
                sram1_data_ok_o = 1'b0;
            end
        end default:begin
            r_ns = REmpty;
            sram1_addr_ok_o = 1'b0; 
            sram2_raddr_ok_o = 1'b0; 
            sram1_data_ok_o = 1'b0; 
            sram2_rdata_ok_o = 1'b0; 
            m_arvalid = 1'b0;       
            m_rready = 1'b0;         
       end
    endcase
end 

always@(posedge clk)begin
        if(rst_n == `RstEnable )begin
            r_cs <= REmpty;
        end else begin 
            r_cs <= r_ns;
        end
 end
 
 
 
 
//写状态级
/*握手信号类型有
 //cpu
 sram2_addr_ok_o = 1'b0;
 sram2_data_ok_o = 1'b0;
 //axi
 m_wvalid = 1'b1;
 m_awvalid = 1'b1;
 m_bready = 1'b0;
*/
 always @ *begin
    case(w_cs)
        WEmpty:begin
            m_wvalid = 1'b0;
            m_awvalid = 1'b0;
            m_bready = 1'b0;
            if(sram2_req_i && sram2_wr_i && !now_reading)begin//数据写
                w_ns = WWaitExtAXIAcceptAddrData;
                //cpu
                sram2_waddr_ok_o = 1'b1;
                sram2_wdata_ok_o = 1'b0;
                //axi
                m_awaddr = sram2_addr_i;
                m_awsize = sram2_size_i;
                m_wdata  = sram2_wdata_i;
                m_wstrb  = sram2_wstrb_i;
             end else begin
                w_ns = WEmpty;//少写啦else情况导致用啦if情况的数据
                sram2_waddr_ok_o = 1'b0;
                sram2_wdata_ok_o = 1'b0;
             end
         end 
         WWaitExtAXIAcceptAddrData:begin//等待外部axi接收写数据和写地址
            //cpu
            sram2_waddr_ok_o = 1'b0;
            sram2_wdata_ok_o = 1'b0;
            //axi
            m_wvalid  = 1'b1;
            m_awvalid = 1'b1;
            m_bready  = 1'b0;
            if(m_wready & m_awready)begin
                w_ns = WWaitExtAXIWriteFnish;
            end else if( m_awready)begin
                w_ns = WWaitExtAXIAcceptData;
            end else if(m_wready )begin
                w_ns = WWaitExtAXIAcceptAddr;
            end else begin 
                w_ns = WWaitExtAXIAcceptAddrData;
            end 
         end 
         WWaitExtAXIAcceptData:begin//等待接受数据
            //cpu                      
            sram2_waddr_ok_o = 1'b0;    
            sram2_wdata_ok_o = 1'b0;    
            //axi                      
            m_wvalid  = 1'b1;          
            m_awvalid = 1'b0;          
            m_bready  = 1'b0;          
            if(m_wready )begin
                w_ns = WWaitExtAXIWriteFnish;
            end else begin
                 w_ns = WWaitExtAXIAcceptData;
            end
         end 
         WWaitExtAXIAcceptAddr:begin//等待接收地址
             //cpu                      
            sram2_waddr_ok_o = 1'b0;    
            sram2_wdata_ok_o = 1'b0;    
            //axi                      
            m_wvalid  = 1'b0;          
            m_awvalid = 1'b1;          
            m_bready  = 1'b0; 
            if(m_awready )begin
                w_ns = WWaitExtAXIWriteFnish;
            end else begin
                 w_ns = WWaitExtAXIAcceptAddr;
            end     
              
         end 
         WWaitExtAXIWriteFnish:begin //等待写完成信号
           //cpu
            sram2_waddr_ok_o = 1'b0;
            //axi
            m_wvalid = 1'b0;
            m_awvalid = 1'b0;
            m_bready = 1'b1;//
            if(m_bvalid)begin//axi输入写完成，则输出data_ok=1
                w_ns = REmpty;
                sram2_wdata_ok_o = 1'b1;
            end else begin//axi没有写完成，则data_ok=0
                w_ns = WWaitExtAXIWriteFnish;
                sram2_wdata_ok_o = 1'b0;
            end         
         end 
         default:begin
            w_ns = REmpty;
            //cpu                   
            sram2_waddr_ok_o = 1'b0; 
            sram2_wdata_ok_o = 1'b0; 
            //axi                   
            m_wvalid = 1'b0;        
            m_awvalid = 1'b0;       
            m_bready = 1'b0;        
         end
      endcase
   end
 always@(posedge clk)begin
        if(rst_n == `RstEnable )begin
            w_cs <= WEmpty;
        end else begin 
            w_cs <= w_ns;
        end
 end

endmodule
