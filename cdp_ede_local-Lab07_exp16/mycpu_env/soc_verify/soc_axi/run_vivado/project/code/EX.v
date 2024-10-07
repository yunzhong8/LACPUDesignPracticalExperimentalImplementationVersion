/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*当前指令无效通过reg_we=0体现
*/
/*************\
bug:
op_sb,op_sh信号截取错误，应该对应mem_data_src[2:1],不是mem_data_src[1:0],op_sh,op_sb的位置也凭借错了
mem_rwaddr_low2取错值，选用了inst,应该是alu的计算结果才对
3. 由于forward信号没有设在有效位，导致本来应该空的forward信号一直在向上一级传，由于我是根据forward信号设在是否阻塞，导致id阶段持续被阻塞
\*************/
`include "DefineModuleBus.h"
`include "DefineAluOp.h"
module EX(
   
    input wire mem_allowin_i,//输入ex已经完成当前数据了,允许你清除id_ex锁存器中的数据，将新数据给ex执行，1为允许,由ex传入
    input wire ex_valid_i, //ID阶段流水是空的，没有要执行的数据，1为有效 ，由id_ex传入,
    
    //
    output wire ex_allowin_o,//传给if，和id_exe,id阶段已经完成数据，允许你清除if_id锁存器内容
    output wire ex_to_mem_valid_o,//传给exe_mem，id阶段已经完成
    input wire excep_flush_i,
   
   
    input  wire  [`LineIdToExBusWidth] idex_to_ibus        ,
    input  wire data_sram_addr_ok_i,
    input  wire mem_to_ibus,
    input  wire [31:0]quotient_i,
    input  wire [31:0]remainder_i,
    input  wire div_complete_i,

   
     output wire       div_en_o            ,
     output wire       div_sign_o          ,
     output wire [31:0]divisor_o           ,
     output wire [31:0]dividend_o          ,
                                           
    output wire  [`LineExForwardBusWidth] forward_obus,
    output wire  [`ExToDataBusWidth] to_data_obus,
    output wire  [`LineExToMemBusWidth] to_exmen_obus
);

/***************************************input variable define(输入变量定义)**************************************/

    wire[`PcWidth] pc_i;
    wire [`InstWidth]inst_i;
//运算器
    wire [`AluOpWidth]         alu_op_i      ;
    wire[`AluOperWidth]        alu_oper1_i   ;
    wire[`AluOperWidth]        alu_oper2_i   ;
    wire[`spExeRegsWdataSrcWidth] exe_regs_wdata_src_i;
 //存储器
    wire                     mem_req_i     ;
    wire                     mem_we_i      ;
    wire [`spMemRegsWdataSrcWidth]                    mem_regs_wdata_src_i  ;
    wire [`spMemMemDataSrcWidth]                    mem_mem_data_src_i;
    wire [31:0]              mem_wdata_i   ;
//寄存器组
    wire                     regs_we_i     ;
    wire[`RegsAddrWidth]       regs_waddr_i  ;
    wire[`RegsDataWidth]       regs_wdata_i ;
    wire  [`RegsDataWidth]regs_rdata1_i;
    wire  [`RegsDataWidth]regs_rdata2_i;
    //csr
    wire is_kernel_inst_i,wb_regs_wdata_src_i;
    wire csr_wdata_src_i;
    wire csr_raddr_src_i;
    wire csr_we_i;
    wire [`CsrAddrWidth]csr_waddr_i;
    wire [`RegsDataWidth]csr_wdata_i;
    //llbit
    wire llbit_we_i;
    wire llbit_wdata_i;
//例外                                      
   wire [`ExceptionTypeWidth]excep_type_i;   
   wire excep_en_i;                    
                   
/***************************************output variable define(输出变量定义)**************************************/

    //存储器
    wire                               mem_req_o       ;
    wire                             mem_we_o        ;
    wire [1:0]                     mem_size_o;
    wire [`MemWeWidth]             mem_wstrb_o;
    wire [`spMemRegsWdataSrcWidth]     mem_regs_wdata_src_o   ;
    wire [`spMemMemDataSrcWidth]       mem_mem_data_src_o;
    wire [`MemAddrWidth]               mem_rwaddr_o    ;
    wire [`MemDataWidth]               mem_wdata_o     ;
    //寄存器组
    wire                     regs_we_o      ;
    wire[`RegsAddrWidth]     regs_waddr_o   ;
    reg[`RegsDataWidth]      regs_wdata_o   ;
    wire  [`RegsDataWidth]regs_rdata1_o;
    wire  [`RegsDataWidth]regs_rdata2_o;
    //csr
   
    wire csr_raddr_src_o;
    wire csr_we_o;
    wire [`CsrAddrWidth]csr_waddr_o;
    wire [`RegsDataWidth]csr_wdata_o;
    //llbit
    wire llbit_we_o;
    wire llbit_wdata_o;
    //alu
    wire div_en;
    //指令功能完成信号      
    wire alu_complete;
    //例外信号                                        
     wire  excep_en_o;                         
     wire [`ExceptionTypeWidth] excep_type_o;   
    //当前数据还没计算出
     wire dr_stall_o;   

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//XXXX 模块变量定义
         
         
         wire alu_equ_o;
         wire [`AluOperWidth]alu_rl_o;
         wire [`AluOperWidth]alu_rh_o;
          
         wire [1:0] mem_rwaddr_low2;
         wire op_sh;
         wire op_sb;
      
         //暂停信号
         wire mem_stall;
         //例外
         wire data_w_error;
         wire data_h_error;
         wire data_addr_error;
         //握手
         wire ex_ready_go;
         
/****************************************input decode(输入解码)***************************************/
    assign {is_kernel_inst_i,
            csr_wdata_src_i,regs_rdata1_i,regs_rdata2_i,
            excep_en_i,excep_type_i,
            llbit_we_i,llbit_wdata_i,
            csr_raddr_src_i,csr_we_i,csr_waddr_i,csr_wdata_i,//csr写使能
            exe_regs_wdata_src_i,alu_op_i,alu_oper1_i,alu_oper2_i,
            mem_regs_wdata_src_i,mem_mem_data_src_i,mem_req_i,mem_we_i,mem_wdata_i,
            wb_regs_wdata_src_i,regs_we_i,regs_waddr_i,regs_wdata_i,
            pc_i,inst_i} = idex_to_ibus;
/****************************************output code(输出解码)***************************************/
assign to_exmen_obus={is_kernel_inst_i,
                     csr_wdata_src_i,regs_rdata1_i,regs_rdata2_i,
                     excep_en_o,excep_type_o,
                     llbit_we_o,llbit_wdata_o,
                     csr_raddr_src_o,csr_we_o,csr_waddr_o,csr_wdata_o,//csr写使能
                     mem_regs_wdata_src_o,mem_mem_data_src_o,mem_req_o,mem_wstrb_o,mem_rwaddr_o,mem_wdata_o,
                     wb_regs_wdata_src_i,regs_we_o,regs_waddr_o,regs_wdata_o,
                     pc_i,inst_i};//32+1+5+32

assign forward_obus={llbit_we_o,llbit_wdata_o,
                     regs_we_o,regs_waddr_o,regs_wdata_o,
                     dr_stall_o};

assign to_data_obus={mem_req_o,mem_we_o,mem_size_o,mem_wstrb_o,mem_rwaddr_o,mem_wdata_o};
/*******************************complete logical function (逻辑功能实现)*******************************/
assign mem_stall = mem_to_ibus;


  Arith_Logic_Unit ALU(
                            .x(alu_oper1_i),
                            .y(alu_oper2_i),
                            .aluop(alu_op_i),
                            .quotient_i    (quotient_i)    ,    
                            .remainder_i   (remainder_i)    ,   
                            .div_complete_i(div_complete_i), 
                            
                            .div_en_o    (div_en   ),  
                            .div_sign_o  (div_sign_o ),  
                            .divisor_o   (divisor_o  ),    
                            .dividend_o  (dividend_o ), 
                            .complete_o  (alu_complete),                            
                            .alu_rl_o(alu_rl_o),
                            .alu_rh_o(alu_rh_o)
                            );
   
                                                                                                                
     assign div_en_o = div_en & ex_valid_i;                                                                                                                           
 
 
 
 
    //forward
    assign dr_stall_o = (wb_regs_wdata_src_i |mem_regs_wdata_src_o) & ex_valid_i;
    
    //存储器
    assign mem_rwaddr_low2 = mem_rwaddr_o[1:0];
    assign {op_sb,op_sh}  =  mem_mem_data_src_i[2:1]; 
    //请求信号必须在,mem阶段允许不被写入的时候才能有效 ，当前流水级有效
    assign mem_req_o      =   mem_req_i & mem_allowin_i & (~excep_flush_i) & ex_valid_i;//当前wb没有发出例外信号
   
    assign {mem_we_o,mem_size_o,mem_wstrb_o}      =   !(mem_we_i && ex_valid_i && (!excep_flush_i) && (!mem_stall) && (!excep_en_o))?{ 1'b0,2'b0,4'b0000 }://只有当前wb不是例外，本级是不因为mem阶段指令携带了例外信息要暂停，exe阶段数据有效，本没有携带例外信息，且写使能有效，mem_we才可以生产有效信号
                             op_sb ? {mem_rwaddr_low2[1:0] == 2'b00 ? {1'b1,2'b0,4'b0001 }:
                                      mem_rwaddr_low2[1:0] == 2'b01 ? {1'b1,2'b0,4'b0010 }:
                                      mem_rwaddr_low2[1:0] == 2'b10 ? {1'b1,2'b0,4'b0100} : {1'b1,2'b0,4'b1000} }:
                             op_sh ? {mem_rwaddr_low2[1] ? {1'b1,2'd1,4'b1100} : {1'b1,2'd1,4'b0011} } : {1'b1,2'd2,4'b1111} ;
                             
    assign mem_regs_wdata_src_o   =   mem_regs_wdata_src_i;
    assign mem_mem_data_src_o     =   mem_mem_data_src_i;
    assign mem_rwaddr_o           =   mem_req_i?alu_rl_o:32'h0000_0000;
    
    assign mem_wdata_o            =  op_sb ? {4{mem_wdata_i[7:0]}}  :
                                     op_sh ? {4{mem_wdata_i[15:0]}} : mem_wdata_i;
  
  
  
 //寄存器组
    always @(*)begin
        case(exe_regs_wdata_src_i)
            `spExeRegsWdataSrcLen'd0: regs_wdata_o = regs_wdata_i;
            `spExeRegsWdataSrcLen'd1: regs_wdata_o = alu_rl_o;
            `spExeRegsWdataSrcLen'd2: regs_wdata_o = alu_rh_o;
            default: regs_wdata_o = `ZeroWord32B;
        endcase
    end
 	assign regs_waddr_o    =  regs_waddr_i;
    assign regs_we_o       =  regs_we_i && ex_valid_i && (!excep_flush_i) && (!mem_stall) && (!excep_en_o);//其实可以不考虑例外使能和me_空_stall,flush,携带了例外信息错误的id阶段指令会被冲刷掉的，mem_空_stall也会暂停id阶段
    
  //CSR 
    assign csr_raddr_src_o =  csr_raddr_src_i;
    assign csr_we_o        =  csr_we_i && ex_valid_i && (!excep_flush_i) && (!mem_stall) && (!excep_en_o);
    assign csr_waddr_o     =  csr_waddr_i;
    assign csr_wdata_o     =  csr_wdata_i;
    //llbit
    assign llbit_we_o    =   llbit_we_i && ex_valid_i && (!excep_flush_i) && (!mem_stall) && (!excep_en_o); 
    assign llbit_wdata_o =  llbit_wdata_i;
    
    //例外
     assign data_h_error = (mem_req_o && op_sh && mem_rwaddr_low2[0] !=1'b0 )? 1'b1 : 1'b0;
     assign data_w_error = (mem_req_o && (!op_sh) && (!op_sb) && mem_rwaddr_low2 !=2'b00) ? 1'b1 : 1'b0;
     assign data_addr_error = data_w_error | data_h_error ;
     assign excep_en_o =  (excep_en_i | data_addr_error) & ex_valid_i;
     assign excep_type_o[`AleLocation-1:0] = excep_type_i[`AleLocation-1:0]; 
     //地址不对齐
     assign excep_type_o[`AleLocation] = data_addr_error;
        
     assign excep_type_o[`ErtnLocation:`AleLocation+1] = excep_type_i[`ErtnLocation:`AleLocation+1]; 
    
    // 握手
    //如果mem阶段要求暂停本即则，ready不能=1,当不暂停的时候，本机是访存指令时候，要等发出req和收到addr_ok=1则ready.否则看alu_complete
      assign ex_ready_go   = !mem_stall ? (mem_req_i  ? (mem_req_o&data_sram_addr_ok_i ? 1'b1 : 1'b0) :alu_complete) :1'b0 ; //ifmem阶段指令携带了例外信息则，暂停本级流水
      assign ex_allowin_o  = !ex_valid_i //本级数据为空，允许if阶段写入
                           || (ex_ready_go && mem_allowin_i);//本级有数据要运行，本时钟周期，id阶段运算好了，exe也同时允许写入，同写，和取走数据
                           
      assign ex_to_mem_valid_o = ex_valid_i && ex_ready_go;//id阶段打算写入


endmodule
