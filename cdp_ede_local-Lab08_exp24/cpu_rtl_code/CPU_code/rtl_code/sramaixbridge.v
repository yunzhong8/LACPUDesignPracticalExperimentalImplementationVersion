
/*
*作者：zzq
*创建时间：2023-04-22
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*req_i:读写请求(rd_req)
*rlen_i读长度(用rd_type表示)
*r_ready_o
:
*raddr_i读地址rd_addr
*we:使能wr_req
*size:一次读写长度(由rd_type表示)
*wstrb:写字节使能(wr_wstrb)
*wdata:写数据128bit(wr_data)
*rlast_o:读组合一个字节ret_last
*
*输出：
*模块功能：
*支持burst传输的转接桥
*/
/*************\
bug:
1. 握手信号的组合逻辑环查找方式，就是将握手信号删掉在看
2. 当冲刷信号有效的时候要求清空除法器，即复位除法器，我没有做导致错误，
3. 较为幸运的是我给exe设置了阻塞，也就是说EXE后续流水的指令可能发生例外冲刷，EXE就会阻塞不动，旧不会发出req请求，也就是说该阶段读写数据是不会发生变化的
4. 写 ifelse的时候else忘记写啦
想不通这个sb设计,cache写的是,req是=0,和类sram接口是不一致的,我还要重新调整,真是无语
5.  mw_addr_finish 用之前忘记清理之前的值,以前有1导致错误,always中用到的每个寄存器都要在不同状态上明确它的值,要清理
6. 只能使能信号放在状态机里面,数据的控制最好不要放在状态机里面
7. 因为写状态机某一个状态忘记给出 write_count_reg_rst1,write_count_reg_rst3初始值,导致保留了历史值,导致控制错误 
8. 转接桥设计的ready信号有逻辑有问题，需要重构
\*************/
//`include "DefineModuleBus.h"
`include "define.v"
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
  output  reg  [7 :0] m_arlen  ,//由cache提供,部分读则值0,全读则值3(128bit4个32)
  output  reg  [2 :0] m_arsize ,
  output  wire [1 :0] m_arburst,//设置为incr模式01
  output  wire [1 :0] m_arlock ,//不涉及
  output  wire [3 :0] m_arcache,//不涉及
  output  wire [2 :0] m_arprot ,//不涉及
  output  reg         m_arvalid,
  input   wire        m_arready,
  //r
  input  wire [3 :0] m_rid    ,
  input  wire [31:0] m_rdata  ,
  input  wire [1 :0] m_rresp  ,
  input  wire        m_rlast  ,//读返回的最后一个数据据使能信号
  input  wire        m_rvalid ,
  output reg         m_rready ,
  //aw
  output  wire [3 :0] m_awid   ,//不涉及
  output  reg [31:0] m_awaddr ,
  output  reg [7 :0] m_awlen  ,//不涉及
  output  reg [2 :0] m_awsize ,
  output  wire [1 :0] m_awburst,//不涉及
  output  wire [1 :0] m_awlock ,//不涉及
  output  wire [3 :0] m_awcache,//不涉及
  output  wire [2 :0] m_awprot ,//不涉及
  output  reg        m_awvalid,
  input   wire        m_awready,
  //w
  output  wire [3 :0] m_wid    ,//不涉及
  output  wire [31:0] m_wdata  ,
  output  reg  [3 :0] m_wstrb  ,
  output  reg         m_wlast  ,//不涉及
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
  wire [31:0] sram2_raddr_i,sram1_raddr_i;    
  wire [31:0] sram2_waddr_i,sram1_waddr_i;    
  wire [2:0]  sram2_rtype_i,sram1_rtype_i;//读类型
  wire [2:0]  sram2_wtype_i,sram1_wtype_i;//写类型
  wire [127:0] sram2_wdata_i,sram1_wdata_i;   

  reg sram1_rready_o;//真恶心,这个出现啦相互依赖啦,addr_ok的输出依赖请求输入,cache中的请求信号又依赖啦外部addr_ok        
  reg sram1_rvalid_o;
  reg sram1_wready_o  ;
  
  reg sram2_rready_o;
  reg sram2_rvalid_o;
  reg sram2_wready_o  ;
  
  wire [31:0] sram2_rdata_o,sram1_rdata_o;   
  

//固定读请求通道
assign m_arburst = 2'b01;
assign m_arlock = 0;
assign m_arcache = 0;
assign m_arprot = 0;
assign m_awprot = 0;
//写请求通道
assign m_awid = 4'b0001;
assign m_awburst = 2'b01;
assign m_awlock  = 0; 
assign m_awcache = 0; 
assign m_awprot  = 0;
//写数据通道
assign m_wid = 4'b0001;



/***************************************output variable define(输出变量定义)**************************************/
  wire        sram2_rlast_o,sram1_rlast_o;
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

//写外部axi
reg [31:0]axi_w_data[4:0];//128个写回数据
reg [1:0]write_count_reg;//写计数器00写回[31:0]01:[63:32]10:[95:64]11[127:96]
reg write_count_reg_rst1;
reg write_count_reg_rst3;
reg write_count_reg_sub;
always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        write_count_reg <= 2'b00;
   end else if(write_count_reg_rst1)begin//复位为0
        write_count_reg <= 2'b00;
   end else if(write_count_reg_rst3)begin//复位为3
        write_count_reg <= 2'b11;
   end else if(write_count_reg_sub)begin//自减1
        write_count_reg <= write_count_reg-2'd1;
   end else begin//保持原值
        write_count_reg <= write_count_reg;
   end
end
//读写完成信号
reg mw_addr_finish,mw_data_finish;
reg mw_addr_finish_we,mw_data_finish_we;
reg mw_addr_finish_rst,mw_data_finish_rst;
always@(posedge clk)begin
    if(rst_n == `RstEnable)begin
         mw_addr_finish <= 1'b0;
    end else if(mw_addr_finish_rst)begin
         mw_addr_finish <= 1'b0;
    end else if( mw_addr_finish_we)begin
         mw_addr_finish <= 1'b1;
    end else begin
       mw_addr_finish   <= mw_addr_finish;
    end
    
     if(rst_n == `RstEnable)begin
         mw_data_finish <= 1'b0;
     end else if(mw_data_finish_rst)begin
        mw_data_finish <= 1'b0;
     end else if(mw_data_finish_we)begin
        mw_data_finish <= 1'b1;
     end else begin
        mw_data_finish <= mw_data_finish;
     end
end
////缓存sram读信息
//reg axi_rbuffer_we,axi_wbuffer_we;
//always@(posedge clk)begin
//    if(rst_n == `RstEnable)begin
//        m_arlen  <= 8'd0;
//        m_arsize <= 3'd0;
//    end else if(axi_rbuffer_we)begin
//        if(sram1_rtype_i == 3'b000)begin//半字读
//            m_arlen  <= 8'd0;
//            m_arsize <= 3'd0;
//        end else if(sram1_rtype_i == 3'b001) begin//字读
//            m_arlen  <= 8'd0;   
//            m_arsize <= 3'd1;   
//        end else if(sram1_rtype_i == 3'b010) begin//字读
//            m_arlen  <= 8'd0;   
//            m_arsize <= 3'd2;   
//        end else if(sram1_rtype_i == 3'b100)begin//行读
//            m_arlen  <= 8'd3;   
//            m_arsize <= 3'd2;   
//        end
//    end else begin
//        m_arlen  <= m_arlen ;
//        m_arsize <= m_arsize;
//    end
//end 

/****************************************input decode(输入解码)***************************************/
assign   {sram1_req_i,sram1_rtype_i,sram1_raddr_i,
          sram1_wr_i, sram1_wtype_i,sram1_waddr_i,sram1_wstrb_i,sram1_wdata_i}=sram_ibus1;
assign   {sram2_req_i,sram2_rtype_i,sram2_raddr_i,
          sram2_wr_i,sram2_wtype_i,sram2_waddr_i,sram2_wstrb_i,sram2_wdata_i}=sram_ibus2;
/****************************************output code(输出解码)***************************************/
assign sram_obus1 = {sram1_rlast_o,1'b1,sram1_rvalid_o,sram1_rready_o,sram1_rdata_o};
assign sram_obus2 = {sram2_rlast_o,sram2_wready_o,sram2_rvalid_o,sram2_rready_o,sram2_rdata_o};


/****************************************output code(内部解码)***************************************/

/*******************************complete logical function (逻辑功能实现)*******************************/

//当前是在写空状态,sram发来写请求,则有写请求到达
assign now_write_arrive = (w_cs==WEmpty)  && sram2_wr_i;//有写请求来访
//当前不是在写空状态,
assign now_writing =  w_cs!=WEmpty;//已经开始执行写啦

assign now_read_arrive =  r_cs == REmpty && (sram2_req_i  || sram1_req_i);//读请求信号在当前时钟刚到
assign now_reading = r_cs != REmpty;//当前已经读状态

//读出的last信号
assign sram1_rlast_o = m_rlast;
assign sram2_rlast_o = m_rlast;

assign sram2_rdata_o   = m_rdata;//返回数据传给端口2
assign sram1_rdata_o   = m_rdata;

//确定du下一个状态//状态执行功能
/*
m_arvalid     
m_rready      
sram1_rvalid_o
sram2_rvalid_o
sram1_rready_o
sram2_rready_o
m_arlen
m_arsize
m_arid
m_araddr
r_ns
*/
//状态位和握手信号else必须写，数据域可以不写
always @ *begin
    case(r_cs)
        REmpty:begin
        //AXI握手信号
          m_arvalid      = 1'b0;  
          m_rready       = 1'b0;
          sram1_rvalid_o = 1'b0;
          sram2_rvalid_o = 1'b0;
          //当前没有正在进行的数据写,则响应数据读(数据读优先)
          if(!now_write_arrive && !now_writing)begin
                //对指令的读ready,只有在没有数据读请求的时钟是才为高电平
                sram1_rready_o  = ~sram2_req_i; 
                //数据ready时刻有效
                sram2_rready_o  = 1'b1;   
          //当有数据读请求,且没有数据写请求到,
                if(sram2_req_i) begin//数据读
                     //设置写的长度
                     if(sram2_rtype_i == 3'b000)begin//字节读
                         m_arlen  = 8'd0;//读出长度为32bit
                         m_arsize = 3'd0;//
                     end else if(sram2_rtype_i == 3'b001) begin//半字读
                         m_arlen  = 8'd0;   
                         m_arsize = 3'd1;   
                     end else if(sram2_rtype_i == 3'b010) begin//字读
                         m_arlen  = 8'd0;   
                         m_arsize = 3'd2;   
                     end else if(sram2_rtype_i == 3'b100)begin//行读
                         m_arlen  = 8'd3;   
                         m_arsize = 3'd2;   
                     end
                     m_arid   = 4'b1;//数据域
                     m_araddr = sram2_raddr_i;
                     r_ns     = RWaitExtAXIAcceptAddr;  //下一个状态
                //当有指令读请求,且没有数据写请求到,当前没有正在进行的数据写,则响应数据读(数据读次)                    
                end else if(sram1_req_i  )begin//指令读                
                    if(sram1_rtype_i == 3'b000)begin//半字读
                         m_arlen  = 8'd0;
                         m_arsize = 3'd0;
                     end else if(sram1_rtype_i == 3'b001) begin//字读
                         m_arlen  = 8'd0;   
                         m_arsize = 3'd1;   
                     end else if(sram1_rtype_i == 3'b010) begin//字读
                         m_arlen  = 8'd0;   
                         m_arsize = 3'd2;   
                     end else if(sram1_rtype_i == 3'b100)begin//行读
                         m_arlen  = 8'd3;   
                         m_arsize = 3'd2;   
                     end
                     m_arid   = 4'b0;
                     m_araddr = sram1_raddr_i;
                     r_ns = RWaitExtAXIAcceptAddr;
                end else begin
                    m_arlen  = 8'd0;
                    m_arsize = 3'd0;
                    m_arid   = 4'b0;
                    m_araddr = 32'd0;
                    r_ns = REmpty;              
                end
         end else begin
            m_arvalid     = 1'b0; 
            m_rready      = 1'b0;
             
            sram1_rvalid_o= 1'b0; 
            sram2_rvalid_o= 1'b0; 
            sram1_rready_o= 1'b0;
            sram2_rready_o= 1'b0;
            
            m_arlen  = 8'd0;
            m_arsize = 3'd0;
            m_arid   = 4'b0;
            m_araddr = 32'd0;
            
            r_ns = REmpty; 
                
         end
        end RWaitExtAXIAcceptAddr:begin//等待外部axi接收读地址
            //AXI
             m_arvalid = 1'b1; 
             m_rready = 1'b0;
             
             //CPU
             sram1_rready_o  = 1'b0; 
             sram2_rready_o  = 1'b0;
             sram1_rvalid_o  = 1'b0;    
             sram2_rvalid_o  = 1'b0;    
             
             
            if(m_arready)begin
                r_ns=RWaitExtAXIData;
            end else begin
                r_ns=RWaitExtAXIAcceptAddr;
            end
        end RWaitExtAXIData:begin//等待外部axi传入读出数据
           //AXI
            m_arvalid = 1'b0;
            m_rready  = 1'b1;
            
            //CPU
           sram1_rready_o  = 1'b0; 
           sram2_rready_o  = 1'b0;
            
           //数据读出
            if( m_rid==4'b1)begin
                
                sram1_rvalid_o  = 1'b0;   
               
                if(m_rvalid & m_rlast )begin//当前是最后一个字返回会,则返回data_ok,跳转到空状态
                     sram2_rvalid_o  = 1'b1;   
                    r_ns = REmpty;
                end else if(m_rvalid)begin
                    sram2_rvalid_o  = 1'b1;  
                    r_ns = RWaitExtAXIData;
                end else begin
                    sram2_rvalid_o  = 1'b0;  
                    r_ns = RWaitExtAXIData;
                end
            end else begin//又是忘记写else，导致双if
                sram2_rvalid_o  = 1'b0;  
                
                if(m_rvalid & m_rlast)begin//返回最后一个数据则下一个时钟回到初始状态,并会返回data_ok
                    sram1_rvalid_o  = 1'b1; 
                    r_ns = REmpty;
                end else if(m_rvalid) begin//如果不是最后一个返回数据,则值返回data_ok,保持在当前状态
                    sram1_rvalid_o  = 1'b1; 
                    r_ns = RWaitExtAXIData;//如果外部axi没有返回数据,则保持在当前状态,不返回data_ok
                end else begin
                    sram1_rvalid_o  = 1'b0; 
                    r_ns = RWaitExtAXIData;
                end
            end
        end default:begin
            
           sram1_rready_o  = 1'b0;    
           sram2_rready_o  = 1'b0;    
           sram1_rvalid_o  = 1'b0;    
           sram2_rvalid_o  = 1'b0;    
           m_arvalid = 1'b0;       
           m_rready = 1'b0;
           r_ns = REmpty;         
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
        WEmpty:begin//存数据和写字节长度,设置读地址接受finsih=0,写数据接受finish=0,根据写的长度设置写计数器初始值:len=0则初始值=,
            m_wvalid  = 1'b0;
            m_awvalid = 1'b0;
            m_bready  = 1'b0;
            mw_addr_finish_rst = 1'b1;
            mw_data_finish_rst = 1'b1;
            mw_addr_finish_we = 1'b0;
            mw_data_finish_we = 1'b0;
            //数据写
            if( !now_reading)begin//写ready逻辑有问题，当当前是写empty,且读状态机器没有执行（即也处于idle,）问题当前时钟读状态机有读请/写状态机有写请求是咋样的
                if(~now_read_arrive)begin//因为cache的设计，等到wready信号的下一个时钟周期表示接受写信号，且不会连续出现两次写，
                    sram2_wready_o = 1'b1;
                end else begin
                    sram2_wready_o = 1'b0;
                end
                 if(sram2_rtype_i == 3'b000)begin//半字读
                    m_awlen  = 8'd0;
                    m_awsize = 3'd0;
                end else if(sram2_rtype_i == 3'b001) begin//字读
                    m_awlen  = 8'd0;   
                    m_awsize = 3'd1;   
                end else if(sram2_rtype_i == 3'b010) begin//字读
                    m_awlen  = 8'd0;   
                    m_awsize = 3'd2;   
                end else if(sram2_rtype_i == 3'b100)begin//行读
                    m_awlen  = 8'd3;   
                    m_awsize = 3'd2;   
                end
                m_awaddr = sram2_waddr_i;
                {axi_w_data[3],axi_w_data[2],axi_w_data[1],axi_w_data[0]}  = sram2_wdata_i;
                m_wstrb  = sram2_wstrb_i;
                if(sram2_wtype_i==3'b100)begin//如果值=0则设在初始为0
                    write_count_reg_rst1=1'b0;
                    write_count_reg_rst3=1'b1;
                end else begin
                    write_count_reg_rst1=1'b1;
                    write_count_reg_rst3=1'b0;
                end
                
                if(sram2_wr_i)begin                 
                    w_ns = WWaitExtAXIAcceptAddrData;
                end else begin
                    w_ns = WEmpty;
                end                          
             end else begin
                sram2_wready_o = 1'b0;
                
                m_awlen  = 8'd0;                                                              
                m_awsize = 3'd0;                                                              
                m_awaddr = 32'd0;                                                             
                {axi_w_data[3],axi_w_data[2],axi_w_data[1],axi_w_data[0]}  = 128'd0;          
                m_wstrb  = 4'd0;     
                                                                                        
                write_count_reg_rst1=1'b1;                                                    
                write_count_reg_rst3=1'b0; 
                write_count_reg_sub = 1'b0;
                                                                                                                        
                w_ns = WEmpty;                                                                         
             end
         end WWaitExtAXIAcceptAddrData:begin//等待外部axi接收写数据和写地址
           //axi
            m_wvalid  = ~mw_data_finish;
            m_awvalid = ~mw_addr_finish;
            m_bready  = 1'b0;       
            //cpu
            sram2_wready_o = 1'b0;
            mw_addr_finish_rst = 1'b0;
            mw_data_finish_rst = 1'b0;
           
            if(m_awready)begin//标志信号要先清0,我没有导致错误
                mw_addr_finish_we = 1'b1;
            end else begin
                mw_addr_finish_we = 1'b0;
            end
            //如果计数器的值是00,表示当前只有一个数据要发,所以last=1
            if(write_count_reg==2'b00)begin//外部axi是不是接收一个数据要得等其能接受下一个数据就要在等一次ready对
                m_wlast = 1'b1;
            end else begin
                m_wlast = 1'b0;
            end
            write_count_reg_rst1=1'b0;                                                    
            write_count_reg_rst3=1'b0; 
            //如果收到一个ready信号,则计数器的值-1
            if(m_wready)begin
                write_count_reg_sub = 1'b1;
            end else begin
                write_count_reg_sub = 1'b0;
            end
            //如果当前计数器是00,且收到ready,则设置finshi信号
            if(write_count_reg==2'b00&m_wready)begin
                mw_data_finish_we = 1'b1;
            end else begin
                mw_data_finish_we = 1'b0;
            end
            //如果两个fishi信号都有效则转到下一个状态,否则保持在原态
            if( mw_data_finish & mw_addr_finish)begin        
                w_ns = WWaitExtAXIWriteFnish;                    
            end else begin                                  
                w_ns = WWaitExtAXIAcceptAddrData;                 
            end                                             
            
         end WWaitExtAXIWriteFnish:begin //等待写完成信号
          //axi
            m_wvalid = 1'b0;
            m_awvalid = 1'b0;
            m_bready = 1'b1;//
           //cpu
            sram2_wready_o = 1'b0;          
            
            m_awlen  = 8'd0;                                                              
            m_awsize = 3'd0;                                                              
            m_awaddr = 32'd0;                                                             
            {axi_w_data[3],axi_w_data[2],axi_w_data[1],axi_w_data[0]}  = 128'd0;          
            m_wstrb  = 4'd0;    
            
            write_count_reg_rst1=1'b1;   
            write_count_reg_rst3=1'b0;   
            write_count_reg_sub = 1'b0; 
            
            mw_addr_finish_rst = 1'b1;                                                    
            mw_data_finish_rst = 1'b1;                                                    
            mw_addr_finish_we = 1'b0;                                                     
            mw_data_finish_we = 1'b0;      
            
            
            if(m_bvalid)begin//axi输入写完成，则输出data_ok=1
                w_ns = REmpty;              
            end else begin//axi没有写完成，则data_ok=0
                w_ns = WWaitExtAXIWriteFnish;                
            end         
         end default:begin     
            m_wvalid  = 1'b0;
            m_awvalid = 1'b0;
            m_bready  = 1'b0;
            sram2_wready_o = 1'b0;
            
            m_awlen  = 8'd0;                                                              
            m_awsize = 3'd0;                                                              
            m_awaddr = 32'd0;                                                             
            {axi_w_data[3],axi_w_data[2],axi_w_data[1],axi_w_data[0]}  = 128'd0;          
            m_wstrb  = 4'd0;     
                                                                                    
            write_count_reg_rst1=1'b1;                                                    
            write_count_reg_rst3=1'b0; 
            write_count_reg_sub = 1'b0;
                                                               
            mw_addr_finish_rst = 1'b1;                                                    
            mw_data_finish_rst = 1'b1;                                                    
            mw_addr_finish_we = 1'b0;                                                     
            mw_data_finish_we = 1'b0; 
            
             w_ns = REmpty;                
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
 
 //写数据
 assign m_wdata = axi_w_data[write_count_reg];

endmodule
