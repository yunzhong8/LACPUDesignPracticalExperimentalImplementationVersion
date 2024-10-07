`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/16 19:45:31
// Design Name: 
// Module Name: TlbGroup
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
//bug查找的地址要单独分离使用其他线路传输数据，因为地址信息需要携带group信息
//复制粘贴的时候s0_plv_o忘记修改成s1_plv_o导致错误
module TlbGroup(
input wire clk,

input wire [`TlbSearchIbusWidth]  s0_ibus,
input wire [`TlbSearchIbusWidth]  s1_ibus,

input wire                         invtlb_valid_i  ,
input wire  [`TlbInvBusWidth]      invtlb_ibus     ,

output wire                       s0_found_o      ,//输出查找到啦,0则触发重填      
output wire [`TlbIndexWidth]      s0_index_o,           
output wire [`TlbSearchObusWidth] s0_obus,
output wire                       s1_found_o      ,//输出查找到啦,0则触发重填   
output wire [`TlbIndexWidth]      s1_index_o      ,  
output wire [`TlbSearchObusWidth] s1_obus,

input wire                        we_i            ,//写使能  
input wire [2:0]    w_index_i       ,//写地址  
input wire [`TlbWriteBusWidth]    w_ibus,
input wire [`TlbReadIbusWidth]    r_ibus,
output wire [`TlbReadObusWidth]   r_obus

    );
//虚地址查找实地址端口0                                                                                   
 wire [`VppnWidth]       s0_vppn_i       ;//虚页号                                             
 wire                    s0_va_bit12_i   ;//虚拟地址的第12bit位置，表示虚拟地址是奇偶性                        
 wire [`AsidWidth]       s0_asid_i       ;// 当前指令对应的asid，即CSR中的asid.用于和tlb项的asid进行比较 
        
                                

                                     
 wire [`PpnWidth]        s0_ppn_o        ;//输出物理页号                                          
 wire [`PsWidth]         s0_ps_o         ;//输出表项页大小                                         
 wire [`PlvWidth]        s0_plv_o        ;//输出物理页号对应权限                                      
 wire [`MatWidth]        s0_mat_o        ;//该表项对应的访存空间的存储访存类型                               
 wire                    s0_d_o          ;//found=1,v=1,d=0,则触发TLB修改例外                      
 wire                    s0_v_o          ;//found=1,v=0则触发TLB无效                             
                                                                                                
//虚地址查找实地址端口0                                                                                   
 wire [`VppnWidth]       s1_vppn_i       ;                                                  
 wire                    s1_va_bit12_i   ;                                                  
 wire [`AsidWidth]       s1_asid_i       ;   
                                                
                                                                                                 
 wire [`PpnWidth]        s1_ppn_o        ;                                                  
 wire [`PsWidth]         s1_ps_o         ;                                                  
 wire [`PlvWidth]        s1_plv_o        ;                                                  
 wire [`MatWidth]        s1_mat_o        ;                                                  
 wire                    s1_d_o          ;                                                  
 wire                    s1_v_o          ;                                                  
                                                                                                
//指令TLB重填                                                                                                                                  
                                            
 //重填虚拟                                       ;                                                  
 wire                     w_e_i           ;                                                  
 wire [`VppnWidth]        w_vppn_i        ;//写虚拟页号                                           
 wire [`PsWidth]          w_ps_i          ;                                                  
 wire [`AsidWidth]        w_asid_i        ;                                                  
 wire                     w_g_i           ;//全局使能位                                           
 //重填写实地址偶数页                                       ;                                                  
 wire [`PpnWidth]         w_ppn0_i        ;//物理偶页号                                           
 wire [`PlvWidth]         w_plv0_i        ;//                                                
 wire [`MatWidth]         w_mat0_i        ;//                                                
 wire                     w_d0_i          ;                                                  
 wire                     w_v0_i          ;                                                  
 //重填写实地址奇数页                                        ;                                                  
 wire [`PpnWidth]         w_ppn1_i        ;//物理奇页页号                                          
 wire [`PlvWidth]         w_plv1_i        ;                                                  
 wire [`MatWidth]         w_mat1_i        ;                                                  
 wire                     w_d1_i          ;                                                  
 wire                     w_v1_i          ;                                                  
                                                                                                
//指令读TLB                                                                                        
wire [`TlbIndexWidth]   r_index_i       ;//TLB表项地址                                         
//读虚拟                                      ;                                                  
wire                    r_e_o            ;                                                  
wire [`VppnWidth]       r_vppn_o         ;                                                  
wire [`PsWidth]         r_ps_o           ;                                                  
wire [`AsidWidth]       r_asid_o         ;                                                  
wire                    r_g_o            ;                                                  
//读写实地址偶数页                                      ;                                                  
wire [`PpnWidth]        r_ppn0_o         ;                                                  
wire [`PlvWidth]        r_plv0_o        ;                                                  
wire [`MatWidth]        r_mat0_o         ;                                                  
wire                    r_d0_o           ;                                                  
wire                    r_v0_o           ;                                                  
//读写实地址奇数页                                       ;                                                  
wire [`PpnWidth]        r_ppn1_o         ;                                                  
wire [`PlvWidth]        r_plv1_o         ;                                                  
wire [`MatWidth]        r_mat1_o         ;                                                  
wire                    r_d1_o           ;                                                  
wire                    r_v1_o           ;     
//TLB清理
wire [`InvtlbOpWidth]invtlb_op_i;
wire [`VppnWidth]invtlb_vppn_i;
wire [`AsidWidth]invtlb_asid_i;

parameter TlbSearchLen = `TlbIndexLen +`PpnLen +`PsLen +`PlvLen +`MatLen +`EnLen + `EnLen ;
 

//虚拟
 reg [`VppnWidth] TlbVppnRegs  [0:`TlbItemNum-1] ;
 reg [`PsWidth]   TlbPsRegs    [0:`TlbItemNum-1] ;
 reg [`GWidth]    TlbGRegs     [0:`TlbItemNum-1] ;
 reg [`AsidWidth] TlbAsidRegs  [0:`TlbItemNum-1] ;
 reg              TlbERegs     [0:`TlbItemNum-1] ;
 //实0
 reg [`PpnWidth]  TlbPpn0Regs   [0:`TlbItemNum-1] ; 
 reg [`PlvWidth]  TlbPlv0Regs   [0:`TlbItemNum-1] ; 
 reg [`MatWidth]  TlbMat0Regs   [0:`TlbItemNum-1] ; 
 reg [`DWidth]    TlbD0Regs     [0:`TlbItemNum-1] ; 
 reg [`VWidth]    TlbV0Regs     [0:`TlbItemNum-1] ; 
 //实1                   
 reg [`PpnWidth]  TlbPpn1Regs   [0:`TlbItemNum-1] ;      
 reg [`PlvWidth]  TlbPlv1Regs   [0:`TlbItemNum-1] ; 
 reg [`MatWidth]  TlbMat1Regs   [0:`TlbItemNum-1] ; 
 reg [`DWidth]    TlbD1Regs     [0:`TlbItemNum-1] ; 
 reg [`VWidth]    TlbV1Regs     [0:`TlbItemNum-1] ; 
 //查找信号
 wire s0_match0,s0_match1,s0_match2,s0_match3,s0_match4,s0_match5,s0_match6,s0_match7;    
 wire s1_match0,s1_match1,s1_match2,s1_match3,s1_match4,s1_match5,s1_match6,s1_match7; 
 wire s0_odd_page0,s0_odd_page1,s0_odd_page2,s0_odd_page3,s0_odd_page4,s0_odd_page5,s0_odd_page6,s0_odd_page7;   
 wire s1_odd_page0,s1_odd_page1,s1_odd_page2,s1_odd_page3,s1_odd_page4,s1_odd_page5,s1_odd_page6,s1_odd_page7;                                      
                                                                                                
assign   {s0_vppn_i,s0_va_bit12_i,s0_asid_i} =   s0_ibus;    
assign   {s1_vppn_i,s1_va_bit12_i,s1_asid_i} =   s1_ibus;   
   
assign   s0_obus = {s0_ppn_o,s0_ps_o,s0_plv_o,s0_mat_o,s0_d_o,s0_v_o};  
assign   s1_obus = {s1_ppn_o,s1_ps_o,s1_plv_o,s1_mat_o,s1_d_o,s1_v_o};//复制粘贴的时候s0_plv_o忘记修改成s1_plv_o导致错误   

assign  {
         w_e_i,w_vppn_i,w_ps_i,w_asid_i,w_g_i,
         w_ppn0_i,w_plv0_i,w_mat0_i,w_d0_i,w_v0_i,
         w_ppn1_i,w_plv1_i,w_mat1_i,w_d1_i,w_v1_i       } = w_ibus   ; 
         
assign   r_index_i = r_ibus;

assign   r_obus = {r_e_o,r_vppn_o,r_ps_o,r_asid_o,r_g_o,
          r_ppn0_o,r_plv0_o,r_mat0_o,r_d0_o,r_v0_o,
          r_ppn1_o,r_plv1_o,r_mat1_o,r_d1_o,r_v1_o};    
assign {invtlb_op_i,invtlb_vppn_i,invtlb_asid_i} = invtlb_ibus;
          
assign  s0_found_o =    s0_match0|s0_match1|s0_match2|s0_match3 | s0_match4 | s0_match5 | s0_match6 | s0_match7 ;
assign  s1_found_o =    s1_match0|s1_match1|s1_match2|s1_match3 | s1_match4 | s1_match5 | s1_match6 | s1_match7 ;

 //查找
 //表项存在，且是4k,即ps=12，则进行全序地在匹配，否则：进行部分虚地址匹配，和权限比较，看是否是全局页
 assign s0_match0 =  (TlbERegs[0 ]==1'b1) &&  ((TlbPsRegs[0 ] > 6'd12 &&(s0_vppn_i[18:10] ==TlbVppnRegs[0 ][18:10])) || (s0_vppn_i ==TlbVppnRegs[0 ])) &&  (TlbGRegs[0 ] || (s0_asid_i==TlbAsidRegs[0 ]))  ;
 assign s0_match1 =  (TlbERegs[1 ]==1'b1) &&  ((TlbPsRegs[1 ] > 6'd12 &&(s0_vppn_i[18:10] ==TlbVppnRegs[1 ][18:10])) || (s0_vppn_i ==TlbVppnRegs[1 ])) &&  (TlbGRegs[1 ] || (s0_asid_i==TlbAsidRegs[1 ]))  ;
 assign s0_match2 =  (TlbERegs[2 ]==1'b1) &&  ((TlbPsRegs[2 ] > 6'd12 &&(s0_vppn_i[18:10] ==TlbVppnRegs[2 ][18:10])) || (s0_vppn_i ==TlbVppnRegs[2 ])) &&  (TlbGRegs[2 ] || (s0_asid_i==TlbAsidRegs[2 ]))  ;
 assign s0_match3 =  (TlbERegs[3 ]==1'b1) &&  ((TlbPsRegs[3 ] > 6'd12 &&(s0_vppn_i[18:10] ==TlbVppnRegs[3 ][18:10])) || (s0_vppn_i ==TlbVppnRegs[3 ])) &&  (TlbGRegs[3 ] || (s0_asid_i==TlbAsidRegs[3 ]))  ;
 assign s0_match4 =  (TlbERegs[4 ]==1'b1) &&  ((TlbPsRegs[4 ] > 6'd12 &&(s0_vppn_i[18:10] ==TlbVppnRegs[4 ][18:10])) || (s0_vppn_i ==TlbVppnRegs[4 ])) &&  (TlbGRegs[4 ] || (s0_asid_i==TlbAsidRegs[4 ]))  ;
 assign s0_match5 =  (TlbERegs[5 ]==1'b1) &&  ((TlbPsRegs[5 ] > 6'd12 &&(s0_vppn_i[18:10] ==TlbVppnRegs[5 ][18:10])) || (s0_vppn_i ==TlbVppnRegs[5 ])) &&  (TlbGRegs[5 ] || (s0_asid_i==TlbAsidRegs[5 ]))  ;
 assign s0_match6 =  (TlbERegs[6 ]==1'b1) &&  ((TlbPsRegs[6 ] > 6'd12 &&(s0_vppn_i[18:10] ==TlbVppnRegs[6 ][18:10])) || (s0_vppn_i ==TlbVppnRegs[6 ])) &&  (TlbGRegs[6 ] || (s0_asid_i==TlbAsidRegs[6 ]))  ;
 assign s0_match7 =  (TlbERegs[7 ]==1'b1) &&  ((TlbPsRegs[7 ] > 6'd12 &&(s0_vppn_i[18:10] ==TlbVppnRegs[7 ][18:10])) || (s0_vppn_i ==TlbVppnRegs[7 ])) &&  (TlbGRegs[7 ] || (s0_asid_i==TlbAsidRegs[7 ]))  ;
                                                                                      
 assign s1_match0 =  (TlbERegs[0 ]==1'b1) &&  ((TlbPsRegs[0 ] > 6'd12 &&(s1_vppn_i[18:10] ==TlbVppnRegs[0 ][18:10])) || (s1_vppn_i ==TlbVppnRegs[0 ])) &&  (TlbGRegs[0 ] || (s1_asid_i==TlbAsidRegs[0 ]))  ; 
 assign s1_match1 =  (TlbERegs[1 ]==1'b1) &&  ((TlbPsRegs[1 ] > 6'd12 &&(s1_vppn_i[18:10] ==TlbVppnRegs[1 ][18:10])) || (s1_vppn_i ==TlbVppnRegs[1 ])) &&  (TlbGRegs[1 ] || (s1_asid_i==TlbAsidRegs[1 ]))  ; 
 assign s1_match2 =  (TlbERegs[2 ]==1'b1) &&  ((TlbPsRegs[2 ] > 6'd12 &&(s1_vppn_i[18:10] ==TlbVppnRegs[2 ][18:10])) || (s1_vppn_i ==TlbVppnRegs[2 ])) &&  (TlbGRegs[2 ] || (s1_asid_i==TlbAsidRegs[2 ]))  ; 
 assign s1_match3 =  (TlbERegs[3 ]==1'b1) &&  ((TlbPsRegs[3 ] > 6'd12 &&(s1_vppn_i[18:10] ==TlbVppnRegs[3 ][18:10])) || (s1_vppn_i ==TlbVppnRegs[3 ])) &&  (TlbGRegs[3 ] || (s1_asid_i==TlbAsidRegs[3 ]))  ; 
 assign s1_match4 =  (TlbERegs[4 ]==1'b1) &&  ((TlbPsRegs[4 ] > 6'd12 &&(s1_vppn_i[18:10] ==TlbVppnRegs[4 ][18:10])) || (s1_vppn_i ==TlbVppnRegs[4 ])) &&  (TlbGRegs[4 ] || (s1_asid_i==TlbAsidRegs[4 ]))  ; 
 assign s1_match5 =  (TlbERegs[5 ]==1'b1) &&  ((TlbPsRegs[5 ] > 6'd12 &&(s1_vppn_i[18:10] ==TlbVppnRegs[5 ][18:10])) || (s1_vppn_i ==TlbVppnRegs[5 ])) &&  (TlbGRegs[5 ] || (s1_asid_i==TlbAsidRegs[5 ]))  ; 
 assign s1_match6 =  (TlbERegs[6 ]==1'b1) &&  ((TlbPsRegs[6 ] > 6'd12 &&(s1_vppn_i[18:10] ==TlbVppnRegs[6 ][18:10])) || (s1_vppn_i ==TlbVppnRegs[6 ])) &&  (TlbGRegs[6 ] || (s1_asid_i==TlbAsidRegs[6 ]))  ; 
 assign s1_match7 =  (TlbERegs[7 ]==1'b1) &&  ((TlbPsRegs[7 ] > 6'd12 &&(s1_vppn_i[18:10] ==TlbVppnRegs[7 ][18:10])) || (s1_vppn_i ==TlbVppnRegs[7 ])) &&  (TlbGRegs[7 ] || (s1_asid_i==TlbAsidRegs[7 ]))  ; 
 
 
 assign s0_odd_page0 =  TlbPsRegs[0] > 6'd12 ?  s0_vppn_i[9] : s0_va_bit12_i;
 assign s0_odd_page1 =  TlbPsRegs[1] > 6'd12 ?  s0_vppn_i[9] : s0_va_bit12_i;
 assign s0_odd_page2 =  TlbPsRegs[2] > 6'd12 ?  s0_vppn_i[9] : s0_va_bit12_i;
 assign s0_odd_page3 =  TlbPsRegs[3] > 6'd12 ?  s0_vppn_i[9] : s0_va_bit12_i;
 assign s0_odd_page4 =  TlbPsRegs[4] > 6'd12 ?  s0_vppn_i[9] : s0_va_bit12_i;
 assign s0_odd_page5 =  TlbPsRegs[5] > 6'd12 ?  s0_vppn_i[9] : s0_va_bit12_i;
 assign s0_odd_page6 =  TlbPsRegs[6] > 6'd12 ?  s0_vppn_i[9] : s0_va_bit12_i;
 assign s0_odd_page7 =  TlbPsRegs[7] > 6'd12 ?  s0_vppn_i[9] : s0_va_bit12_i;
 
 assign s1_odd_page0 =  TlbPsRegs[0] > 6'd12 ?  s1_vppn_i[9] : s1_va_bit12_i;
 assign s1_odd_page1 =  TlbPsRegs[1] > 6'd12 ?  s1_vppn_i[9] : s1_va_bit12_i;
 assign s1_odd_page2 =  TlbPsRegs[2] > 6'd12 ?  s1_vppn_i[9] : s1_va_bit12_i;
 assign s1_odd_page3 =  TlbPsRegs[3] > 6'd12 ?  s1_vppn_i[9] : s1_va_bit12_i;
 assign s1_odd_page4 =  TlbPsRegs[4] > 6'd12 ?  s1_vppn_i[9] : s1_va_bit12_i;
 assign s1_odd_page5 =  TlbPsRegs[5] > 6'd12 ?  s1_vppn_i[9] : s1_va_bit12_i;
 assign s1_odd_page6 =  TlbPsRegs[6] > 6'd12 ?  s1_vppn_i[9] : s1_va_bit12_i; 
 assign s1_odd_page7 =  TlbPsRegs[7] > 6'd12 ?  s1_vppn_i[9] : s1_va_bit12_i;
 
 //4+20+6+2+2+2=36
 assign {s0_index_o,s0_ppn_o,s0_ps_o,s0_plv_o,s0_mat_o,s0_d_o,s0_v_o} = {TlbSearchLen{s0_match0 & ~s0_odd_page0} } & {4'd0,TlbPpn0Regs[0],TlbPsRegs[0],TlbPlv0Regs[0],TlbMat0Regs[0],TlbD0Regs[0],TlbV0Regs[0]}|
                                                                        {TlbSearchLen{s0_match1 & ~s0_odd_page1} } & {4'd1,TlbPpn0Regs[1],TlbPsRegs[1],TlbPlv0Regs[1],TlbMat0Regs[1],TlbD0Regs[1],TlbV0Regs[1]}|
                                                                        {TlbSearchLen{s0_match2 & ~s0_odd_page2} } & {4'd2,TlbPpn0Regs[2],TlbPsRegs[2],TlbPlv0Regs[2],TlbMat0Regs[2],TlbD0Regs[2],TlbV0Regs[2]}|
                                                                        {TlbSearchLen{s0_match3 & ~s0_odd_page3} } & {4'd3,TlbPpn0Regs[3],TlbPsRegs[3],TlbPlv0Regs[3],TlbMat0Regs[3],TlbD0Regs[3],TlbV0Regs[3]}|
                                                                        {TlbSearchLen{s0_match4 & ~s0_odd_page4} } & {4'd4,TlbPpn0Regs[4],TlbPsRegs[4],TlbPlv0Regs[4],TlbMat0Regs[4],TlbD0Regs[4],TlbV0Regs[4]}|
                                                                        {TlbSearchLen{s0_match5 & ~s0_odd_page5} } & {4'd5,TlbPpn0Regs[5],TlbPsRegs[5],TlbPlv0Regs[5],TlbMat0Regs[5],TlbD0Regs[5],TlbV0Regs[5]}|
                                                                        {TlbSearchLen{s0_match6 & ~s0_odd_page6} } & {4'd6,TlbPpn0Regs[6],TlbPsRegs[6],TlbPlv0Regs[6],TlbMat0Regs[6],TlbD0Regs[6],TlbV0Regs[6]}|
                                                                        {TlbSearchLen{s0_match7 & ~s0_odd_page7} } & {4'd7,TlbPpn0Regs[7],TlbPsRegs[7],TlbPlv0Regs[7],TlbMat0Regs[7],TlbD0Regs[7],TlbV0Regs[7]}|
                                                                        {TlbSearchLen{s0_match0 & s0_odd_page0 } } & {4'd0,TlbPpn1Regs[0],TlbPsRegs[0],TlbPlv1Regs[0],TlbMat1Regs[0],TlbD1Regs[0],TlbV1Regs[0]}|
                                                                        {TlbSearchLen{s0_match1 & s0_odd_page1 } } & {4'd1,TlbPpn1Regs[1],TlbPsRegs[1],TlbPlv1Regs[1],TlbMat1Regs[1],TlbD1Regs[1],TlbV1Regs[1]}|                                                                                             
                                                                        {TlbSearchLen{s0_match2 & s0_odd_page2 } } & {4'd2,TlbPpn1Regs[2],TlbPsRegs[2],TlbPlv1Regs[2],TlbMat1Regs[2],TlbD1Regs[2],TlbV1Regs[2]}|
                                                                        {TlbSearchLen{s0_match3 & s0_odd_page3 } } & {4'd3,TlbPpn1Regs[3],TlbPsRegs[3],TlbPlv1Regs[3],TlbMat1Regs[3],TlbD1Regs[3],TlbV1Regs[3]}|
                                                                        {TlbSearchLen{s0_match4 & s0_odd_page4 } } & {4'd4,TlbPpn1Regs[4],TlbPsRegs[4],TlbPlv1Regs[4],TlbMat1Regs[4],TlbD1Regs[4],TlbV1Regs[4]}|
                                                                        {TlbSearchLen{s0_match5 & s0_odd_page5 } } & {4'd5,TlbPpn1Regs[5],TlbPsRegs[5],TlbPlv1Regs[5],TlbMat1Regs[5],TlbD1Regs[5],TlbV1Regs[5]}|
                                                                        {TlbSearchLen{s0_match6 & s0_odd_page6 } } & {4'd6,TlbPpn1Regs[6],TlbPsRegs[6],TlbPlv1Regs[6],TlbMat1Regs[6],TlbD1Regs[6],TlbV1Regs[6]}|
                                                                        {TlbSearchLen{s0_match7 & s0_odd_page7 } } & {4'd7,TlbPpn1Regs[7],TlbPsRegs[7],TlbPlv1Regs[7],TlbMat1Regs[7],TlbD1Regs[7],TlbV1Regs[7]};
                                                             
 assign {s1_index_o,s1_ppn_o,s1_ps_o,s1_plv_o,s1_mat_o,s1_d_o,s1_v_o} = {TlbSearchLen{s1_match0 & ~s1_odd_page0} } & {4'd0,TlbPpn0Regs[0],TlbPsRegs[0],TlbPlv0Regs[0],TlbMat0Regs[0],TlbD0Regs[0],TlbV0Regs[0]}|
                                                                        {TlbSearchLen{s1_match1 & ~s1_odd_page1} } & {4'd1,TlbPpn0Regs[1],TlbPsRegs[1],TlbPlv0Regs[1],TlbMat0Regs[1],TlbD0Regs[1],TlbV0Regs[1]}|
                                                                        {TlbSearchLen{s1_match2 & ~s1_odd_page2} } & {4'd2,TlbPpn0Regs[2],TlbPsRegs[2],TlbPlv0Regs[2],TlbMat0Regs[2],TlbD0Regs[2],TlbV0Regs[2]}|
                                                                        {TlbSearchLen{s1_match3 & ~s1_odd_page3} } & {4'd3,TlbPpn0Regs[3],TlbPsRegs[3],TlbPlv0Regs[3],TlbMat0Regs[3],TlbD0Regs[3],TlbV0Regs[3]}|
                                                                        {TlbSearchLen{s1_match4 & ~s1_odd_page4} } & {4'd4,TlbPpn0Regs[4],TlbPsRegs[4],TlbPlv0Regs[4],TlbMat0Regs[4],TlbD0Regs[4],TlbV0Regs[4]}|
                                                                        {TlbSearchLen{s1_match5 & ~s1_odd_page5} } & {4'd5,TlbPpn0Regs[5],TlbPsRegs[5],TlbPlv0Regs[5],TlbMat0Regs[5],TlbD0Regs[5],TlbV0Regs[5]}|
                                                                        {TlbSearchLen{s1_match6 & ~s1_odd_page6} } & {4'd6,TlbPpn0Regs[6],TlbPsRegs[6],TlbPlv0Regs[6],TlbMat0Regs[6],TlbD0Regs[6],TlbV0Regs[6]}|
                                                                        {TlbSearchLen{s1_match7 & ~s1_odd_page7} } & {4'd7,TlbPpn0Regs[7],TlbPsRegs[7],TlbPlv0Regs[7],TlbMat0Regs[7],TlbD0Regs[7],TlbV0Regs[7]}|
                                                                        {TlbSearchLen{s1_match0 & s1_odd_page0 } } & {4'd0,TlbPpn1Regs[0],TlbPsRegs[0],TlbPlv1Regs[0],TlbMat1Regs[0],TlbD1Regs[0],TlbV1Regs[0]}|
                                                                        {TlbSearchLen{s1_match1 & s1_odd_page1 } } & {4'd1,TlbPpn1Regs[1],TlbPsRegs[1],TlbPlv1Regs[1],TlbMat1Regs[1],TlbD1Regs[1],TlbV1Regs[1]}|                                                                                             
                                                                        {TlbSearchLen{s1_match2 & s1_odd_page2 } } & {4'd2,TlbPpn1Regs[2],TlbPsRegs[2],TlbPlv1Regs[2],TlbMat1Regs[2],TlbD1Regs[2],TlbV1Regs[2]}|
                                                                        {TlbSearchLen{s1_match3 & s1_odd_page3 } } & {4'd3,TlbPpn1Regs[3],TlbPsRegs[3],TlbPlv1Regs[3],TlbMat1Regs[3],TlbD1Regs[3],TlbV1Regs[3]}|
                                                                        {TlbSearchLen{s1_match4 & s1_odd_page4 } } & {4'd4,TlbPpn1Regs[4],TlbPsRegs[4],TlbPlv1Regs[4],TlbMat1Regs[4],TlbD1Regs[4],TlbV1Regs[4]}|
                                                                        {TlbSearchLen{s1_match5 & s1_odd_page5 } } & {4'd5,TlbPpn1Regs[5],TlbPsRegs[5],TlbPlv1Regs[5],TlbMat1Regs[5],TlbD1Regs[5],TlbV1Regs[5]}|
                                                                        {TlbSearchLen{s1_match6 & s1_odd_page6 } } & {4'd6,TlbPpn1Regs[6],TlbPsRegs[6],TlbPlv1Regs[6],TlbMat1Regs[6],TlbD1Regs[6],TlbV1Regs[6]}|
                                                                        {TlbSearchLen{s1_match7 & s1_odd_page7 } } & {4'd7,TlbPpn1Regs[7],TlbPsRegs[7],TlbPlv1Regs[7],TlbMat1Regs[7],TlbD1Regs[7],TlbV1Regs[7]};
 
 
 //读
 
 assign {r_vppn_o ,r_ps_o,r_g_o,r_asid_o, r_e_o ,    
         r_ppn0_o,r_plv0_o ,r_mat0_o,r_d0_o ,r_v0_o,    
         r_ppn1_o,r_plv1_o,r_mat1_o ,r_d1_o ,r_v1_o} = {TlbVppnRegs[r_index_i[2:0]],TlbPsRegs  [r_index_i[2:0]],TlbGRegs    [r_index_i[2:0]],TlbAsidRegs[r_index_i[2:0]],TlbERegs [r_index_i[2:0]],
                                                        TlbPpn0Regs[r_index_i[2:0]],TlbPlv0Regs[r_index_i[2:0]],TlbMat0Regs [r_index_i[2:0]],TlbD0Regs  [r_index_i[2:0]],TlbV0Regs[r_index_i[2:0]],
                                                        TlbPpn1Regs[r_index_i[2:0]],TlbPlv1Regs[r_index_i[2:0]],TlbMat1Regs [r_index_i[2:0]],TlbD1Regs  [r_index_i[2:0]],TlbV1Regs[r_index_i[2:0]]   }   ;
//写
always @(posedge clk) begin
    if(we_i)begin
       TlbVppnRegs  [w_index_i] <= w_vppn_i    ;
       TlbPsRegs    [w_index_i] <= w_ps_i      ;
       TlbGRegs     [w_index_i] <= w_g_i       ;
       TlbAsidRegs  [w_index_i] <= w_asid_i    ;
     
                               
       TlbPpn0Regs  [w_index_i] <= w_ppn0_i ;
       TlbPlv0Regs  [w_index_i] <= w_plv0_i ;
       TlbMat0Regs  [w_index_i] <= w_mat0_i ;
       TlbD0Regs    [w_index_i] <= w_d0_i   ;
       TlbV0Regs    [w_index_i] <= w_v0_i   ;
                                
       TlbPpn1Regs  [w_index_i] <= w_ppn1_i ;
       TlbPlv1Regs  [w_index_i] <= w_plv1_i ;
       TlbMat1Regs  [w_index_i] <= w_mat1_i ;
       TlbD1Regs    [w_index_i] <= w_d1_i   ;
       TlbV1Regs    [w_index_i] <= w_v1_i   ;
    end 
end

//清理
generate 
genvar i ;
    for(i=0;i<8;i=i+1) begin : clear_loop
        always @(posedge clk) begin
            if(we_i && i== w_index_i) begin//发生写就执行写输入的
                TlbERegs     [i] <= w_e_i       ;
            end else if(invtlb_valid_i && invtlb_op_i<=`TlbInvOpMax)begin //发生清理就进行清理
                  if (invtlb_op_i == `InvtlbOpLen'd0 || invtlb_op_i == `InvtlbOpLen'd1) begin
                      // $display("[%t] d=%d invtlb_op_i=%d!!!",$time,i,invtlb_op_i);
                       TlbERegs     [i] <= 1'b0       ;
                  end else if (invtlb_op_i == `InvtlbOpLen'd2 && TlbGRegs[i]==1'b1) begin
                       TlbERegs     [i] <= 1'b0       ;
                  end else if (invtlb_op_i == `InvtlbOpLen'd3 && TlbGRegs[i]==1'b0)begin
                       TlbERegs     [i] <= 1'b0       ;
                  end else if (invtlb_op_i == `InvtlbOpLen'd4 && TlbGRegs[i]==1'b0 && TlbAsidRegs[i]==invtlb_asid_i )begin
                        TlbERegs     [i] <= 1'b0       ;
                  end else if (invtlb_op_i == `InvtlbOpLen'd5 && TlbGRegs[i]==1'b0 && TlbAsidRegs[i]==invtlb_asid_i && TlbVppnRegs[i] ==invtlb_vppn_i )begin
                       TlbERegs     [i] <= 1'b0       ;
                  end else if (invtlb_op_i == `InvtlbOpLen'd6 && (TlbGRegs[i]==1'b1 || TlbAsidRegs[i]==invtlb_asid_i) && TlbVppnRegs[i] ==invtlb_vppn_i )begin
                       TlbERegs     [i] <= 1'b0       ;
                  end else begin //漏了else导致错误，导致无法赋值
                     TlbERegs     [i] <=  TlbERegs[i]       ;
                  end 
             end else begin
                 TlbERegs     [i] <=  TlbERegs[i]       ;
             end          
        end
    end
endgenerate 
         
         
         
         
                     
         
         
         
         
         
        
         
         
         
         
         
 
 
 
    
    
endmodule
