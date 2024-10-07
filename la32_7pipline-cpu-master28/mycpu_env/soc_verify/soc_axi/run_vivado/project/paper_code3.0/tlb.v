`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/15 20:29:29
// Design Name: 
// Module Name: tlb
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

module tlb(
input wire clk,

input  wire [`TlbSearchIbusWidth]  s0_ibus         ,
input  wire [`TlbSearchIbusWidth]  s1_ibus         ,
input wire                         invtlb_valid_i  ,
input wire  [`TlbInvBusWidth]      invtlb_ibus     ,

output wire                        s0_found_o      ,//输出查找到啦,0则触发重填 
output wire [`TlbIndexWidth]       s0_index_o,     
output wire [`TlbSearchObusWidth]  s0_obus         ,
output wire                        s1_found_o      ,//输出查找到啦,0则触发重填  
output wire [`TlbIndexWidth]       s1_index_o      ,
output wire [`TlbSearchObusWidth]  s1_obus         ,

input  wire                        we_i            ,//写使能  
input  wire [`TlbIndexWidth]       w_index_i       ,//写地址 
input  wire [`TlbWriteBusWidth]    w_ibus          ,
input  wire [`TlbReadIbusWidth]    r_ibus          ,
output wire [`TlbReadObusWidth]    r_obus

    );
    
    
wire item0_s0_found_o ,item1_s0_found_o,item2_s0_found_o,item3_s0_found_o;
wire item0_s1_found_o ,item1_s1_found_o,item2_s1_found_o,item3_s1_found_o;

wire [`TlbSearchObusWidth] item0_s0_obus,item1_s0_obus,item2_s0_obus,item3_s0_obus;
wire [`TlbSearchObusWidth] item0_s1_obus,item1_s1_obus,item2_s1_obus,item3_s1_obus;
wire [`TlbIndexWidth]      item0_s0_index_o,item1_s0_index_o,item2_s0_index_o,item3_s0_index_o;
wire [`TlbIndexWidth]      item0_s1_index_o,item1_s1_index_o,item2_s1_index_o,item3_s1_index_o;
wire [`TlbReadObusWidth] item0_r_obus,item1_r_obus,item2_r_obus,item3_r_obus;

wire item0_we_i,item1_we_i,item2_we_i,item3_we_i;

    
TlbGroup TlbGroup_item0(
 .clk      (clk) ,
 
 .s0_ibus  (s0_ibus) ,
 .s1_ibus  (s1_ibus) ,
 
 .invtlb_valid_i(invtlb_valid_i     ),   
 .invtlb_ibus   (invtlb_ibus    ),     
   
 .s0_found_o(item0_s0_found_o),
 .s0_index_o(item0_s0_index_o),
 .s0_obus   (item0_s0_obus) ,
 .s1_found_o(item0_s1_found_o),
 .s1_index_o(item0_s1_index_o),
 .s1_obus   (item0_s1_obus) ,
 
 .we_i     (item0_we_i),
 .w_index_i(w_index_i[2:0]),  
 .w_ibus   (w_ibus ) ,
 .r_ibus   (r_ibus ) ,
 .r_obus   (item0_r_obus ) 

    );    
 TlbGroup TlbGroup_item1(     
  .clk      (clk) ,           
                              
  .s0_ibus  (s0_ibus) ,       
  .s1_ibus  (s1_ibus) ,   
  
  
  .invtlb_valid_i(invtlb_valid_i     ),      
  .invtlb_ibus   (invtlb_ibus    ),    
  
  .s0_found_o(item1_s0_found_o),   
  .s0_index_o(item1_s0_index_o),                         
  .s0_obus   (item1_s0_obus) , 
  .s1_found_o(item1_s1_found_o),
  .s1_index_o(item1_s1_index_o),
  .s1_obus   (item1_s1_obus) , 
  
  .we_i     (item1_we_i),
  .w_index_i(w_index_i[2:0]),                              
  .w_ibus   (w_ibus ) ,       
  .r_ibus   (r_ibus ) ,       
  .r_obus   (item1_r_obus )   
                              
     );                       
 
 
// TlbGroup TlbGroup_item2(     
//  .clk      (clk) ,           
                              
//  .s0_ibus  (s0_ibus) ,       
//  .s1_ibus  (s1_ibus) ,       
    
//  .s0_found_o(item2_s0_found),                            
//  .s0_obus   (item2_s0_obus) , 
//  .s1_found_o(item2_s1_found),
//  .s1_obus   (item2_s1_obus) , 
   
//  .we_i     (item2_we_i),  
//  .w_index_i(w_index_i[2:0]),                            
//  .w_ibus   (w_ibus ) ,       
//  .r_ibus   (r_ibus ) ,       
//  .r_obus   (item2_r_obus )   
                              
//     );                       
 
// TlbGroup TlbGroup_item3(     
//  .clk      (clk) ,           
                              
//  .s0_ibus  (s0_ibus) ,       
//  .s1_ibus  (s1_ibus) ,       
  
//  .s0_found_o(item3_s0_found),                            
//  .s0_obus   (item3_s0_obus) , 
//  .s1_found_o(item3_s1_found),
//  .s1_obus   (item3_s1_obus) , 
   
//  .we_i     (item3_we_i),    
//  .w_index_i(w_index_i[2:0]),                        
//  .w_ibus   (w_ibus ) ,       
//  .r_ibus   (r_ibus ) ,       
//  .r_obus   (item3_r_obus )   
                              
//     );                       
 
// assign item0_we_i = ~w_index_i[4]& ~w_index_i[3] & we_i; 
// assign item1_we_i = ~w_index_i[4]&  w_index_i[3] & we_i; 
// assign item2_we_i =  w_index_i[4]& ~w_index_i[3] & we_i; 
// assign item3_we_i =  w_index_i[4]&  w_index_i[3] & we_i;
  
// assign s0_found_o = item0_s0_found_o |item1_s0_found_o|item2_s0_found_o|item3_s0_found_o;
// assign s1_found_o = item0_s1_found_o |item1_s1_found_o|item2_s1_found_o|item3_s1_found_o;
 
// assign s0_obus = item0_s0_found ? item0_s0_obus : 
//                  item1_s0_found ? item1_s0_obus : 
//                  item2_s0_found ? item2_s0_obus : 
//                  item3_s0_found ? item3_s0_obus : `TlbSearchObusLen'd0; 
                  
//assign s1_obus = item0_s1_found ? item0_s1_obus :                        
//                 item1_s1_found ? item1_s1_obus :                         
//                 item2_s1_found ? item2_s1_obus :                            
//                 item3_s1_found ? item3_s1_obus : `TlbSearchObusLen'd0;    
//assign  r_obus =  r_ibus[4]? (r_ibus[3] ? item3_r_obus :item2_r_obus) : (r_ibus[3] ? item2_r_obus :item1_r_obus);
assign item0_we_i =  ~w_index_i[3] & we_i; 
assign item1_we_i =   w_index_i[3] & we_i; 

assign s0_found_o = item0_s0_found_o |item1_s0_found_o;
assign s1_found_o = item0_s1_found_o |item1_s1_found_o;
 
assign s0_obus = item0_s0_found_o ? item0_s0_obus : 
                  item1_s0_found_o ? item1_s0_obus : `TlbSearchObusLen'd0; 
                  
assign s1_obus = item0_s1_found_o ? item0_s1_obus :                        
                 item1_s1_found_o ? item1_s1_obus : `TlbSearchObusLen'd0;    
assign  r_obus =  r_ibus[3] ? item1_r_obus :item0_r_obus;

assign s0_index_o = item0_s0_found_o ? {1'b0,item0_s0_index_o[2:0]} :
                    item1_s0_found_o ? {1'b1,item1_s0_index_o[2:0]} : `TlbIndexLen'd0; 
                    
assign s1_index_o = item0_s1_found_o ? {1'b0,item0_s1_index_o[2:0]} :
                    item1_s1_found_o ? {1'b1,item1_s1_index_o[2:0]} : `TlbIndexLen'd0; 
 
endmodule
