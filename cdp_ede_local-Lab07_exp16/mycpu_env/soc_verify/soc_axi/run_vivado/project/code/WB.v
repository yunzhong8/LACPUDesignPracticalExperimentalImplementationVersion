/*
*作者：zzq
*创建时间：2023-04-10
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*
*/
/*************\
bug:
excpcode忘记设置位宽导致，estate没有修改
1. 例外冲刷信号和wb_valid有关wb_flush_o即fulsh = wb_valid & except|ertn
\*************/
`include "DefineModuleBus.h"
module WB(
    input  wire rfb_allowin_i         ,
    input  wire wb_valid_i             ,

    output wire wb_allowin_o          ,
    output wire wb_to_rfb_valid_o     ,  
    //冲刷流水
    output wire wb_flush_o,  
    
    input  wire [`LineMemToWbBusWidth]mw_to_ibus,
    input  wire [`LineCsrToWbWidth]csr_to_ibus,
    
    output wire [`LineWbToDebugBusWidth]to_debug_obus,
    output wire [`LineRegsWriteBusWidth]   to_regs_obus    ,
    output wire [`LineWbToCsrWidth]   to_csr_obus          ,
    output wire [`ExcepToCsrWidth]excep_to_csr_obus    //发出当前要执行例外了
    
    
);

/***************************************input variable define(输入变量定义)**************************************/
wire [`PcWidth]pc_i;
 wire [`InstWidth]inst_i;

 //regs
 wire regs_we_i;
 wire [`RegsAddrWidth]regs_waddr_i;
 wire [`RegsDataWidth]regs_wdata_i;
//csr
 wire is_kernel_inst_i,wb_regs_wdata_src_i;   
 wire csr_we_i; 
 wire [`CsrAddrWidth]  csr_waddr_i;
 wire [`RegsDataWidth] csr_wdata_i;
 wire [`RegsDataWidth] csr_rdata_i;
 wire [1:0]cpu_level_i;
 
 //llbit
 wire llbit_we_i;
 wire llbit_wdata_i;
 //例外                                      
 wire [`ExceptionTypeWidth]excep_type_i;   
 wire excep_en_i;                 
/***************************************output variable define(输出变量定义)**************************************/
 wire    regs_we_o;
 wire  [`RegsAddrWidth]regs_waddr_o;
 wire  [`RegsDataWidth]regs_wdata_o;
 wire  [`RegsDataWidth]regs_rdata1_i;
 wire  [`RegsDataWidth]regs_rdata2_i;
 
 wire csr_wdata_src_i;
 wire csr_raddr_src_i; 
 wire csr_we_o; 
 wire [`CsrAddrWidth]csr_waddr_o;
 wire [`RegsDataWidth]csr_wdata_o;
 wire [`CsrAddrWidth]csr_raddr_o;
 
 //llbit                     
  wire llbit_we_o;            
  wire llbit_wdata_o;         
 //例外          
  wire excep_ipe;              
  wire excep_en_o;            
  wire [`EcodeWidth]excep_ecode_o;         
  wire [`EsubCodeWidth]excep_esubcode_o;      
  wire [`PcWidth]excep_pc_o;
  wire [`MemAddrWidth]mem_rwaddr_i;  
  
  wire excep_badv_we_o;//地址错误就要进行该操作
  wire [`PcWidth]exce_badv_wdata_o;
 //例外返回                      
  wire ertn_en_o;             
  
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
 wire wb_ready_go ;
 //csr
 wire csr_rere_i;//csr重读信号
 //
 wire excep_pc_error;
 wire excep_mem_addr_error;
 
  
/****************************************input decode(输入解码)***************************************/
assign {
        is_kernel_inst_i,
        csr_wdata_src_i,regs_rdata1_i,regs_rdata2_i,
        excep_en_i,excep_type_i,mem_rwaddr_i,
        llbit_we_i,llbit_wdata_i,
        csr_raddr_src_i,csr_we_i,csr_waddr_i,csr_wdata_i,
        wb_regs_wdata_src_i,regs_we_i,regs_waddr_i,regs_wdata_i,
        pc_i,inst_i} = mw_to_ibus;
assign {cpu_level_i,csr_rdata_i} = csr_to_ibus ;

/****************************************output code(输出解码)***************************************/
assign wb_flush_o = (excep_en_o|ertn_en_o)& wb_valid_i;
 
assign to_regs_obus       = {regs_we_o,regs_waddr_o,regs_wdata_o};

assign to_csr_obus        = {csr_raddr_o,
                            llbit_we_o,llbit_wdata_o,
                            csr_we_o,csr_waddr_o,csr_wdata_o};
assign excep_to_csr_obus  = { excep_badv_we_o,exce_badv_wdata_o,
                            ertn_en_o,
                            excep_en_o,excep_ecode_o,excep_esubcode_o,excep_pc_o};
                            
assign to_debug_obus      = {regs_we_o,regs_waddr_o,regs_wdata_o,pc_i};
/*******************************complete logical function (逻辑功能实现)*******************************/

assign regs_we_o    = regs_we_i && wb_valid_i && (!excep_en_o) && (!ertn_en_o);//本级不发生例外，返回，且数据有效才有效
assign regs_waddr_o = regs_waddr_i;
assign regs_wdata_o = wb_regs_wdata_src_i ? csr_rdata_i: regs_wdata_i ;

assign csr_we_o    = csr_we_i  & wb_valid_i && (!excep_en_o) && (!ertn_en_o);
assign csr_waddr_o = csr_waddr_i;
assign csr_wdata_o = csr_wdata_src_i ? ( (regs_rdata2_i & regs_rdata1_i) | (csr_rdata_i & (~regs_rdata1_i)) ) : regs_rdata2_i;
assign csr_raddr_o = csr_raddr_src_i ? csr_waddr_i : `TIdRegAddr;

//llbit
assign llbit_we_o = llbit_we_i& wb_valid_i && (!excep_en_o) && (!ertn_en_o);
assign llbit_wdata_o = llbit_wdata_i;

//例外
assign excep_ipe = (cpu_level_i==2'b11 && is_kernel_inst_i)? 1'b1 : 1'b0;//特权指令执行在核心态发生特权等级例外
assign excep_pc_error   = excep_en_o & excep_type_i[6];
assign excep_mem_addr_error = excep_en_o & excep_type_i[8] ;
assign excep_en_o = ( excep_ipe|| (excep_en_i && excep_type_i[15:0] != 16'h0) ) && wb_valid_i ?1'b1:1'b0;
assign excep_badv_we_o = excep_pc_error | excep_mem_addr_error;
assign exce_badv_wdata_o = excep_pc_error ? pc_i: mem_rwaddr_i;
assign excep_pc_o = pc_i;
assign {excep_ecode_o, excep_esubcode_o} = excep_type_i[0]  ? {`IntEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[1]  ? {`PilEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[2]  ? {`PisEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[3]  ? {`PifEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[4]  ? {`PmeEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[5]  ? {`PpiEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[6]  ? {`AdefEcode   ,`EsubCodeLen'h0} :
                                           excep_type_i[7]  ? {`AdemEcode   ,`EsubCodeLen'h1} :
                                           excep_type_i[8]  ? {`AleEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[9]  ? {`SysEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[10] ? {`BrkEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[11] ? {`IneEcode    ,`EsubCodeLen'h0} :
                                           excep_ipe        ? {`IpeEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[13] ? {`FpdEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[14] ? {`FpeEcode    ,`EsubCodeLen'h0} :
                                           excep_type_i[15] ? {`TlbrEcode   ,`EsubCodeLen'h0} :15'h0;
 //返回
 assign ertn_en_o =   excep_en_i & excep_type_i[16] & wb_valid_i;                                   
                                           
                                        
                                           
                                    
                                           
                                           
                                           
                                           
                                           
                                           
                                                                           
//握手
    assign wb_ready_go   = 1'b1; //id阶段数据是否运算好了，1：是
    
    assign wb_allowin_o  = !wb_valid_i //本级数据为空，允许if阶段写入
                             || (wb_ready_go && rfb_allowin_i);//本级有数据要运行，本时钟周期，id阶段运算好了，exe也同时允许写入，同写，和取走数据
    assign wb_to_rfb_valid_o = wb_valid_i && wb_ready_go;//id阶段打算写入


endmodule
