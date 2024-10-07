`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/07 20:07:06
// Design Name: 
// Module Name: Predactor_Btb
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
// hit,和branch_pc要往下传递，方便id阶段返回修正btb表
// tag=[31:11]//20位tag
//addr=pc[10:4]7位2^7-1=128个btb表,低4位没有用
//////////////////////////////////////////////////////////////////////////////////
//`include "DefineLoogLenWidth.h"
`include "define.v"
module Predactor_Btb(
input wire rst_n,
input wire clk,

input wire re_i,
input wire [`PcWidth]pc_i,



input wire [`BtbWbusWidth]w_ibus,

output wire hit_o,
output wire [`PcWidth]btb_branch_pc_o
    );
    
 /***************************************input variable define(输入变量定义)**************************************/
wire [`BiatWidth]pc_tag_i;
wire [`BtbAddrWidth]btb_raddr_i;

wire [`BtbDataWidth]btb_rdata;

//写使能
 wire we_i;      
 //写地址
 wire [`BtbAddrWidth]waddr_i;  
 //写标记
 wire [`BiatWidth]wtag_i;//22  
 //写预测地址
 wire [`PcWidth]w_predic_pc_i;    





/***************************************output variable define(输出变量定义)**************************************/

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//读出当前btb预测是否有效
wire valid;
//读出预测地址的标记值
wire [`BiatWidth]bia_tag;
//读出btb预测的地址
//读使能
 wire re;
 wire   rw_conflict ;
 assign rw_conflict = re_i&we_i&(waddr_i==btb_raddr_i);
 assign re = rw_conflict ? 1'b0 : re_i;
 
 reg  temp_we_i_reg;
 reg temp_wvalid_i_reg;
 reg [`BiatWidth]temp_wtag_i_reg;
 reg [`BiatWidth]temp_wpredic_pc_reg;
 
 always@(posedge clk)begin
    if(rst_n==`RstEnable)begin
        {temp_we_i_reg,temp_wvalid_i_reg,temp_wtag_i_reg,temp_wpredic_pc_reg}<=0;
    end else if(rw_conflict)begin
       {temp_we_i_reg,temp_wvalid_i_reg,temp_wtag_i_reg,temp_wpredic_pc_reg}<={we_i,wvalid_i,wtag_i,w_predic_pc_i};
    end else begin
        {temp_we_i_reg,temp_wvalid_i_reg,temp_wtag_i_reg,temp_wpredic_pc_reg}<=0;
    end 
end 
 
 
 
 
 //无用接口
 wire [54:0]douta;
 
 

/****************************************input decode(输入解码)***************************************/
assign {pc_tag_i,btb_raddr_i}=pc_i[31:3];//{31:10}{9:3}
assign {we_i,wvalid_i,waddr_i,wtag_i,w_predic_pc_i} = w_ibus;
/****************************************input decode(输入解码)***************************************/
//真双端口ram
//btb_ram btb_ram_item (
//  .clka(clk),    // input wire clka
//  .ena(we_i),      // input wire ena
//  .wea(we_i),      // input wire [0 : 0] wea
//  .addra(waddr_i),  // input wire [6 : 0] addra
//  .dina({wvalid_i,wtag_i,w_predic_pc_i}),    // input wire [43 : 0] dina 1+22+32=55
//  .douta(douta),
  
//  .clkb(clk),    // input wire clkb
//  .enb(re),      // input wire enb
//  .web(1'b0),      // input wire [0 : 0] web
//  .addrb(btb_raddr_i),  // input wire [6 : 0] addrb
//  .dinb(55'd0),    // input wire [54 : 0] dinb
//  .doutb(btb_rdata)  // output wire [43 : 0] doutb
//);

//伪双端口ram
btb_ram btb_ram_item (
  //写
  .clka(clk),    // input wire clka
  .ena(we_i),      // input wire ena
  .wea(we_i),      // input wire [0 : 0] wea
  .addra(waddr_i),  // input wire [6 : 0] addra
  .dina({wvalid_i,wtag_i,w_predic_pc_i}),    // input wire [54 : 0] dina
  //读
  .clkb(clk),    // input wire clkb
  .enb(re),      // input wire enb
  .addrb(btb_raddr_i),  // input wire [6 : 0] addrb
  .doutb(btb_rdata)  // output wire [54 : 0] doutb
);




//解压btb表读出数据
assign {valid,bia_tag,btb_branch_pc_o}= temp_we_i_reg?{temp_wvalid_i_reg,temp_wtag_i_reg,temp_wpredic_pc_reg}: btb_rdata;//1+22+32=55

//判断btb表示是否命中
assign hit_o=valid &&(bia_tag==pc_tag_i)?1'b1:1'b0;



endmodule
