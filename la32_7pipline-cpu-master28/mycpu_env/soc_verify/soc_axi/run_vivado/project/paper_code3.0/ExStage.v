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
\*************/
`include "DefineModuleBus.h"
module ExStage(
    //时钟
    input  wire  clk      ,
    input  wire  rst_n    ,
    //握手
    input  wire next_allowin_i  ,
    input  wire line1_pre_to_now_valid_i    ,
    input  wire line2_pre_to_now_valid_i    ,
    
    output  wire line1_now_to_next_valid_o    ,
    output  wire line2_now_to_next_valid_o    ,
    output  wire now_allowin_o  ,
    //冲刷
    input wire excep_flush_i,
     
    //数据域
    input  wire                   data_sram_addr_ok_i ,
    input  wire [`LaunchToNextBusWidth] pre_to_ibus         ,
    input  wire [`MmToPreBusWidth]     next_to_ibus         ,
    input wire inst_cache_free_i ,
    input wire data_cache_free_i ,
    
    output wire          inst_cacop_en_o,
    output wire  [13:0]  inst_cacop_obus,
    output wire          data_cacop_en_o,
    output wire   [13:0] data_cacop_obus,
    output wire [`PtoWbusWidth]      to_pr_obus    ,
    output wire [`ExForwardBusWidth] forward_obus  ,
    output wire [`ExToDataBusWidth]  to_data_obus  ,
    output wire [`ExToNextBusWidth]   to_next_obus      
   
);

/***************************************input variable define(输入变量定义)**************************************/


//EX
wire [`LineMemToPreBusWidth] line2_next_to_ibus,line1_next_to_ibus;
/***************************************output variable define(输出变量定义)**************************************/
wire [`LineExToNextBusWidth]line2_to_next_obus,line1_to_next_obus;
wire [`LineExForwardBusWidth]line2_ex_forward_obus,line1_ex_forward_obus;


/***************************************parameter define(常量定义)**************************************/
/***************************************inner variable define(内部变量定义)**************************************/
//除法
wire [31:0]quotient ,remainder; 
wire div_complete;
//ID_EX
wire [`LaunchToNextBusWidth] pre_to_bus;
wire line2_now_valid,line1_now_valid;
//EX
wire [`LineLaunchToNextBusWidth] line1_pre_to_bus, line2_pre_to_bus;
wire [`ExToDataBusWidth]line2_ex_to_data_bus,line1_ex_to_data_bus;
wire line2_now_to_next_valid,line1_now_to_next_valid;
//除法
wire       line2_div_en    , line1_div_en    ;
wire       line2_div_sign  , line1_div_sign  ;
wire [31:0]line2_divisor   , line1_divisor   ;
wire [31:0]line2_dividend  , line1_dividend  ;

//分支预测
wire line2_is_branch_inst,line1_is_branch_inst;
wire line2_branch_flush,line1_branch_flush;
wire [`PtoWbusWidth]line2_to_pr_bus  ,line1_to_pr_bus;   


//握手
wire line2_now_allowin,line1_now_allowin;

/****************************************input decode(输入解码)***************************************/
assign {line2_next_to_ibus,line1_next_to_ibus} = next_to_ibus ;

/****************************************output code(输出解码)***************************************/
assign to_next_obus = {line2_to_next_obus,line1_to_next_obus};
assign forward_obus = {line2_ex_forward_obus,line1_ex_forward_obus};
/****************************************output code(内部解码)***************************************/
assign {line2_pre_to_bus, line1_pre_to_bus} = pre_to_bus;
/*******************************complete logical function (逻辑功能实现)*******************************/

 ID_EX IDEXI(
        .rst_n(rst_n),
        .clk(clk),
        //握手
        .line1_pre_to_now_valid_i(line1_pre_to_now_valid_i),
        .line2_pre_to_now_valid_i(line2_pre_to_now_valid_i),
        .now_allowin_i(now_allowin_o),
        
        .line1_now_valid_o(line1_now_valid),
        .line2_now_valid_o(line2_now_valid),
        
        .excep_flush_i(excep_flush_i),
        //数据域
        .pre_to_ibus(pre_to_ibus),
        
        .to_now_obus(pre_to_bus)
    );
    
    
    
 EX EXI1(
        //握手
        .next_allowin_i(next_allowin_i),
        //.ex_valid_i(line1_pre_to_now_valid_i),sb东西，没有经过时序电路直接传到啦，tm的，这行永不删除铭记，找了一整天，这bug
        .now_valid_i(line1_now_valid),
        
        .now_allowin_o(line1_now_allowin),
        .now_to_next_valid_o(line1_now_to_next_valid),
        
        .excep_flush_i(excep_flush_i),
        
        //数据域
        .pre_to_ibus  (line1_pre_to_bus),
        .data_sram_addr_ok_i(data_sram_addr_ok_i),
        .next_to_ibus   (line1_next_to_ibus),
        .inst_cache_free_i(inst_cache_free_i),
        .data_cache_free_i(data_cache_free_i),
        .quotient_i    (quotient)    ,  
        .remainder_i   (remainder)    , 
        .div_complete_i(div_complete),
       
        
        .div_en_o    (line1_div_en  ),
        .div_sign_o  (line1_div_sign),
        .divisor_o   (line1_divisor ),
        .dividend_o  (line1_dividend),
        
        .branch_flush_o      (line1_branch_flush  ),       
        .now_is_branch_inst_o(line1_is_branch_inst), 
        .to_pr_obus          (line1_to_pr_bus     ),           
        
        .inst_cacop_en_o  (inst_cacop_en_o),
        .inst_cacop_obus  (inst_cacop_obus),
        .data_cacop_en_o  (data_cacop_en_o),
        .data_cacop_obus  (data_cacop_obus),
        .forward_obus  (line1_ex_forward_obus),
        .to_data_obus  (line1_ex_to_data_bus),
        .to_next_obus (line1_to_next_obus)
        
    );                  

 EX EXI2(
        //握手
        .next_allowin_i(next_allowin_i),
        //.ex_valid_i   (line2_pre_to_now_valid_i),
        .now_valid_i   (line2_now_valid),
        
        .now_allowin_o(line2_now_allowin),
        .now_to_next_valid_o(line2_now_to_next_valid),
        
        //冲刷信号
        .excep_flush_i(excep_flush_i),
        
        //数据域
        .pre_to_ibus(line2_pre_to_bus),
        .data_sram_addr_ok_i(data_sram_addr_ok_i),
        .next_to_ibus(line2_next_to_ibus),
        .inst_cache_free_i(1'b1),
        .data_cache_free_i(1'b1),
        
        .quotient_i    (quotient)    ,   
        .remainder_i   (remainder)    ,  
        .div_complete_i(div_complete),
                                       
        .div_en_o    (line2_div_en   ), 
        .div_sign_o  (line2_div_sign ), 
        .divisor_o   (line2_divisor  ), 
        .dividend_o  (line2_dividend ), 
        
        .branch_flush_o      (line2_branch_flush),       
        .now_is_branch_inst_o(line2_is_branch_inst), 
        .to_pr_obus          (line2_to_pr_bus     ),  
              
        .forward_obus   (line2_ex_forward_obus),
        .to_data_obus   (line2_ex_to_data_bus),
        .to_next_obus  (line2_to_next_obus)
    );
//除法器
  Div Div_item(
     .clk              (clk)            ,
     .rst_n            (rst_n&~excep_flush_i)          ,
     
     .div_en_i         (line1_div_en  ) ,  //除法使能
     .div_signed_i     (line1_div_sign) ,  //有无符号除
     .divisor_i        (line1_divisor ) ,  //除数
     .dividend_i       (line1_dividend) , //被除数
     
     .quotient_o       (quotient)       , //商 
     .remainder_o      (remainder)      , //余数
     .finished_o       (div_complete)    
);
 
 //分支预测更新判断
    assign to_pr_obus  =   line1_is_branch_inst &  line1_branch_flush  ? line1_to_pr_bus  :
                           line2_is_branch_inst &  line2_branch_flush  ? line2_to_pr_bus  :
                           line1_is_branch_inst & ~line1_branch_flush  ? line1_to_pr_bus  :
                           line2_is_branch_inst & ~line2_branch_flush  ? line2_to_pr_bus  : `PtoWbusLen'd0;
 
 

//
assign to_data_obus = line1_ex_to_data_bus;

//握手
assign line1_now_to_next_valid_o = now_allowin_o && line1_now_to_next_valid;
assign line2_now_to_next_valid_o = now_allowin_o && line2_now_to_next_valid;
assign now_allowin_o  = line2_now_allowin && line1_now_allowin;




endmodule
