`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/19 18:27:27
// Design Name: 
// Module Name: cache_way
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
//g功能：1组1×256的D,1组{1,20}*256的tagb,4组32*256的data
//offset[3:2]相同的不能同时读写
//offset[3:2]不同的可以同时读写
//路大小:4KB
//这是单端口读写,所以应该设在读优先,因为不存在读写同时(对一个ip核是不会存在又读又写)
//双端口读写,需要设在写优先
//不同域的读写时机我没有分析清楚导致错误,cache的tag域在部分写的也是要写的

module cache_way(
input                           clk           ,
input  wire                     req_i         ,
input  wire [`CacheIndexWidth]  r_index_i     ,
output wire [149:0]             r_data_o      , //d_0,v,tag,data//1   1  20  128


//部分写
input wire  [`CacheIndexWidth]  w_index_i     ,//写地址
input wire  [1:0]               w_type_i      ,//10为全写，01为部分写，
input wire  [`CacheOffsetWidth] offset_i      ,//部分写的块内偏移地址                                             
input wire  [3:0]               wstrb_i       ,//部分写的字节使能
input wire  [149:0]             w_data_i       //发生部分写，则使用[31:0]位
                                                
    );
  /***************************************input variable define(输入变量定义)**************************************/
   //标记字段
   wire [20:0]tagv_wdata_i ;//{v,tag}=={1,20}
   wire d_i;//脏数据位
   wire [127:0]data_i;//写入数据
   wire [31:0]         dina0_i  ,dina1_i  , dina2_i  , dina3_i  , dina4_i  , dina5_i  , dina6_i  , dina7_i  ; 
  /***************************************output variable define(输出变量定义)**************************************/ 
   wire [20:0]tagv_rdata_o ;
   wire d_o;
  //data部分 
   wire [127:0]data_o;
  /***************************************inner variable define(内部变量定义)**************************************/ 
  reg d_reg[255:0];  
                                                                                                                                                                                                             
  wire [`CacheIndexWidth] data_addra0 , data_addra1 , data_addra2 , data_addra3 , data_addra4 , data_addra5 , data_addra6 , data_addra7 ;                 
  wire                    data_ena0   , data_ena1   , data_ena2   , data_ena3   , data_ena4   , data_ena5   , data_ena6   , data_ena7   ;
  wire [3:0]              data_wea0   , data_wea1   , data_wea2   , data_wea3   , data_wea4   , data_wea5   , data_wea6   , data_wea7   ;
  wire [31:0]             data_dina0  , data_dina1  , data_dina2  , data_dina3  , data_dina4  , data_dina5  , data_dina6  , data_dina7  ;   
  wire [31:0]             data_douta0 , data_douta1 , data_douta2 , data_douta3 , data_douta4 , data_douta5 , data_douta6 , data_douta7 ;                                                                                                
                                                                                                                               
  wire [`CacheIndexWidth] tagv_addra;
  
 
  
  /***************************************inner variable define(输入解码)**************************************/   
  assign {tagv_wdata_i,data_i,d_i} = w_data_i ;//这种划分方式就是为了省端口部分写值使用w_data_[32:0]这33个位 
  assign {dina3_i,dina2_i,dina1_i,dina0_i} = data_i;
  
  /***************************************inner variable define(输出解码)**************************************/ 
  assign data_o = {data_douta3,data_douta2,data_douta1,data_douta0};
  //d_0,v,tag,data
  //1   1  20  128
  assign r_data_o = {d_o,tagv_rdata_o,data_o};
  
 /***************************************inner variable define(逻辑实现)**************************************/  
   integer i;
    initial begin
        for(i=0;i<256;i=i+1) d_reg[i] = 0;   // 仿真使用，因为仿真中未初始化的reg初值为X (其实可综合)
    end
  //脏数据往位(只要发生store则写入1,否则保持原值,部分写和全写都可能是store请求)
  //读
  assign d_o =   d_reg[r_index_i];
  //写(部分写和全写都会设置其值,不同情况d的写入值由外部决定)
  always @(posedge clk)begin
    if(req_i && (w_type_i!=2'b00))begin
        d_reg[w_index_i]<= d_i;
    end
    
  end
  
  
//tagv只有在全写模式才会进行写
  assign tagv_wea =   req_i && w_type_i[1] ;
  assign tagv_addra = (w_type_i==2'd0) ? r_index_i :w_index_i;   
    
 tagv_ram tagv_ram_item (
  .clka             ( clk         ),    // input wire clka
  .ena              ( req_i       ),      // input wire ena
  .wea              ( tagv_wea    ),      // input wire [0 : 0] wea
  .addra            ( tagv_addra  ),  // input wire [7 : 0] addra
  .dina             ( tagv_wdata_i),    // input wire [20 : 0] dina
  .douta            ( tagv_rdata_o)  // output wire [20 : 0] douta
);
    
  
  //如果是全写，则写使能全有效，如果是部分写，如果是读                                                                                                                                                                                              
   assign {data_ena0,data_addra0,data_dina0,data_wea0} = w_type_i[1] ? {req_i,w_index_i,dina0_i,4'b1111} :(w_type_i[0] ? {req_i&&offset_i[3:2]==2'd0,w_index_i,dina0_i,wstrb_i}:{req_i,r_index_i,dina0_i,4'b0000});        
   assign {data_ena1,data_addra1,data_dina1,data_wea1} = w_type_i[1] ? {req_i,w_index_i,dina1_i,4'b1111} :(w_type_i[0] ? {req_i&&offset_i[3:2]==2'd1,w_index_i,dina0_i,wstrb_i}:{req_i,r_index_i,dina1_i,4'b0000});        
   assign {data_ena2,data_addra2,data_dina2,data_wea2} = w_type_i[1] ? {req_i,w_index_i,dina2_i,4'b1111} :(w_type_i[0] ? {req_i&&offset_i[3:2]==2'd2,w_index_i,dina0_i,wstrb_i}:{req_i,r_index_i,dina2_i,4'b0000});        
   assign {data_ena3,data_addra3,data_dina3,data_wea3} = w_type_i[1] ? {req_i,w_index_i,dina3_i,4'b1111} :(w_type_i[0] ? {req_i&&offset_i[3:2]==2'd3,w_index_i,dina0_i,wstrb_i}:{req_i,r_index_i,dina3_i,4'b0000});        
   //assign {data_ena4,data_addra4,data_dina4,data_wea4} = w_type_i[1] ? {req_i,w_index_i,dina4_i,4'b1111} :(w_type_i[0] ? {req_i&&offset_i==3'd4,w_index_i,req_i,r_index_i,dina0_i,wstrb_i}:36'd0);                       
   //assign {data_ena5,data_addra5,data_dina5,data_wea5} = w_type_i[1] ? {req_i,w_index_i,dina5_i,4'b1111} :(w_type_i[0] ? {req_i&&offset_i==3'd5,w_index_i,req_i,r_index_i,dina0_i,wstrb_i}:36'd0);                       
   //assign {data_ena6,data_addra6,data_dina6,data_wea6} = w_type_i[1] ? {req_i,w_index_i,dina6_i,4'b1111} :(w_type_i[0] ? {req_i&&offset_i==3'd6,w_index_i,req_i,r_index_i,dina0_i,wstrb_i}:36'd0);                       
   //assign {data_ena7,data_addra7,data_dina7,data_wea7} = w_type_i[1] ? {req_i,w_index_i,dina7_i,4'b1111} :(w_type_i[0] ? {req_i&&offset_i==3'd7,w_index_i,req_i,r_index_i,dina0_i,wstrb_i}:36'd0);                       
                                                                                                                                                                                                                              
    
//数据域    
  data_bank bank0 (  
    .clka         ( clk         )  ,    // input wire clka  
    .ena          ( data_ena0   )  ,    // input wire ena  
    .wea          ( data_wea0   )  ,    // input wire [3 : 0] wea  
    .addra        ( data_addra0 )  ,    // input wire [7 : 0] addra  
    .dina         ( data_dina0  )  ,    // input wire [31 : 0] dina  
    .douta        ( data_douta0 )       // output wire [31 : 0] douta  
  );
  
  data_bank bank1 (                                                          
    .clka         ( clk         )  ,    // input wire clka                  
    .ena          ( data_ena1   )  ,    // input wire ena                    
    .wea          ( data_wea1   )  ,    // input wire [3 : 0] wea           
    .addra        ( data_addra1 )  ,    // input wire [7 : 0] addra         
    .dina         ( data_dina1  )  ,    // input wire [31 : 0] dina         
    .douta        ( data_douta1 )       // output wire [31 : 0] douta       
  );           
  
  data_bank bank2 (                                                                                                                    
    .clka         ( clk         )  ,    // input wire clka                  
    .ena          ( data_ena2   )  ,    // input wire ena                   
    .wea          ( data_wea2   )  ,    // input wire [3 : 0] wea           
    .addra        ( data_addra2 )  ,    // input wire [7 : 0] addra         
    .dina         ( data_dina2  )  ,    // input wire [31 : 0] dina         
    .douta        ( data_douta2 )       // output wire [31 : 0] douta       
  );                                                                       
  
  
  data_bank bank3 (                                                        
    .clka         ( clk         )  ,    // input wire clka                  
    .ena          ( data_ena3   )  ,    // input wire ena                   
    .wea          ( data_wea3   )  ,    // input wire [3 : 0] wea           
    .addra        ( data_addra3 )  ,    // input wire [7 : 0] addra         
    .dina         ( data_dina3  )  ,    // input wire [31 : 0] dina         
    .douta        ( data_douta3 )       // output wire [31 : 0] douta       
  );                                                                       
  
//  data_bank bank4 (                                                        
//    .clka         (clk         )  ,    // input wire clka                  
//    .ena          (data_ena4   )  ,    // input wire ena                   
//    .wea          (data_wea4        )  ,    // input wire [3 : 0] wea           
//    .addra        (data_addra4 )  ,    // input wire [7 : 0] addra         
//    .dina         (data_dina4       )  ,    // input wire [31 : 0] dina         
//    .douta        (data_douta4      )       // output wire [31 : 0] douta       
//  );                                                                       
  
  
// data_bank bank5 (                                                                  
//   .clka         (clk         )  ,    // input wire clka                            
//   .ena          (data_ena5   )  ,    // input wire ena                             
//   .wea          (data_wea5        )  ,    // input wire [3 : 0] wea                     
//   .addra        (data_addra5 )  ,    // input wire [7 : 0] addra                   
//   .dina         (data_dina5       )  ,    // input wire [31 : 0] dina                   
//   .douta        (data_douta5      )       // output wire [31 : 0] douta                 
// );                                                                                 
                                                                                    
// data_bank bank6 (                                                                  
//   .clka         (clk              )  ,    // input wire clka                            
//   .ena          (data_ena6        )  ,    // input wire ena                             
//   .wea          (data_wea6        )  ,    // input wire [3 : 0] wea                     
//   .addra        (data_addra6      )  ,    // input wire [7 : 0] addra                   
//   .dina         (data_dina6       )  ,    // input wire [31 : 0] dina                   
//   .douta        (data_douta6      )       // output wire [31 : 0] douta                 
// );                                                                                 
                                                                                    
// data_bank bank7 (                                                                  
//   .clka         (clk         )  ,    // input wire clka                            
//   .ena          (data_ena7   )  ,    // input wire ena                             
//   .wea          (data_wea7        )  ,    // input wire [3 : 0] wea                     
//   .addra        (data_addra7 )  ,    // input wire [7 : 0] addra                   
//   .dina         (data_dina7       )  ,    // input wire [31 : 0] dina                   
//   .douta        (data_douta7      )       // output wire [31 : 0] douta                 
// );                                                                                 
                                                                                    
endmodule          