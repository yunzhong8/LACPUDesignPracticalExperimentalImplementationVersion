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
4.信号依赖出现问题，mem_we_o依赖例外信号，例外信号中的tlb的pis例外又依赖mem_we_o，这种相互依赖中间没有时序部件，导致出现组合逻辑环，所以哪些信号是基本信号，哪些信号是联合产生的
5. 为了避免错误地址发到外部存储器中：出现有exe及其以前的流水级出现例外的时候，当前指令是有效的：但是不能发地址请求出去
6.注意同一种例外可能在不同阶段产生要使用或|
\*************/
//`include "DefineModuleBus.h"
//`include "DefineAluOp.h"
`include "define.v"
module EX(
   
    input wire next_allowin_i,//输入ex已经完成当前数据了,允许你清除id_ex锁存器中的数据，将新数据给ex执行，1为允许,由ex传入
    input wire now_valid_i, //ID阶段流水是空的，没有要执行的数据，1为有效 ，由id_ex传入,
    
    //
    output wire now_allowin_o,//传给if，和id_exe,id阶段已经完成数据，允许你清除if_id锁存器内容
    output wire now_to_next_valid_o,//传给exe_mem，id阶段已经完成
    input wire excep_flush_i,
   
    input  wire next_stages_valid_i,
    input  wire  [`LineLaunchToNextBusWidth] pre_to_ibus        ,
    input  wire data_sram_addr_ok_i,
    input  wire next_to_ibus,
    input wire inst_cache_free_i ,
    input wire data_cache_free_i ,
    
    input  wire [31:0]quotient_i,
    input  wire [31:0]remainder_i,
    input  wire div_complete_i,
   

   
    output wire                           div_en_o            ,
    output wire                           div_sign_o          ,
    output wire [31:0]                    divisor_o           ,
    output wire [31:0]                    dividend_o          ,
    output wire                           branch_flush_o,
    output wire                           now_is_branch_inst_o,
    output wire [`PtoWbusWidth]           to_pr_obus,
    
    output wire          inst_cacop_req_o,   
    output wire   [13:0] inst_cacop_obus,   
    output wire          data_cacop_req_o,   
    output wire   [13:0] data_cacop_obus,   
                                              
    output wire  [`LineExForwardBusWidth] forward_obus,
    output wire  [`ExToDataBusWidth]      to_data_obus,
    output wire  [`LineExToNextBusWidth]   to_next_obus
    
);

/***************************************input variable define(输入变量定义)**************************************/

    wire [`PcWidth]                pc_i                  ;
    wire [`InstWidth]              inst_i                ;
//运算器
    wire [`AluOpWidth]             alu_op_i              ;
    wire [`AluOperWidth]           alu_oper1_i           ;
    wire [`AluOperWidth]           alu_oper2_i           ;
    wire [`spExeRegsWdataSrcWidth] exe_regs_wdata_src_i  ;
 //存储器
    wire                           mem_req_i             ;
    wire                           mem_we_i              ;
    wire [`spMemRegsWdataSrcWidth] mem_regs_wdata_src_i  ;
    wire [`spMemMemDataSrcWidth]   mem_mem_data_src_i    ;
    wire [31:0]                    mem_wdata_i           ;
//寄存器组
    wire                           regs_we_i             ;
    wire  [`RegsAddrWidth]         regs_waddr_i          ;
    wire  [`RegsDataWidth]         regs_wdata_i          ;
    wire  [`RegsDataWidth]         regs_rdata1_i         ;
    wire  [`RegsDataWidth]         regs_rdata2_i         ;
    //csr
    wire                           is_kernel_inst_i,wb_regs_wdata_src_i;
    wire                           csr_wdata_src_i       ;
    wire                           csr_raddr_src_i       ;
    wire                           csr_we_i              ;
    wire [`CsrAddrWidth]           csr_waddr_i           ;
    wire [`RegsDataWidth]          csr_wdata_i           ;
    //llbit
    wire                           llbit_we_i            ;
    wire                           llbit_wdata_i         ;
    //tlb
    wire                           tlb_re_i              ; 
    wire                           tlb_se_i              ;
    wire                           tlb_ie_i              ; 
    wire                           tlb_we_i              ; 
    wire                           tlb_fe_i              ;
    wire [4:0]                     tlb_op_i              ; 
    wire                           refetch_flush_i       ;
//例外                                      
   wire [`ExceptionTypeWidth]      excep_type_i          ;   
   wire                            excep_en_i            ;   
   
   wire idle_en_i,cacop_en_i;
   wire [4:0]cacop_code_i;   
  
/***************************************output variable define(输出变量定义)**************************************/

    //存储器
    wire                               mem_req_o              ;
    wire                               mem_we_o               ;
    wire [1:0]                         mem_size_o             ;
    wire [`MemWeWidth]                 mem_wstrb_o            ;
    wire [`spMemRegsWdataSrcWidth]     mem_regs_wdata_src_o   ;
    wire [`spMemMemDataSrcWidth]       mem_mem_data_src_o     ;
    wire [`MemAddrWidth]               mem_rwaddr_o           ;
   
    wire [`MemDataWidth]               mem_wdata_o            ;
    //寄存器组
    wire                               regs_we_o              ;
    wire[`RegsAddrWidth]               regs_waddr_o           ;
    reg [`RegsDataWidth]               regs_wdata_o           ;
   
    //csr
   
    wire                               csr_raddr_src_o        ;
    wire                               csr_we_o               ;
    wire [`CsrAddrWidth]               csr_waddr_o            ;
    wire [`RegsDataWidth]              csr_wdata_o            ;
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
     //tlb
     wire [1:0]tlb_search_type_o;
     wire tlb_re_o         ; 
     wire tlb_se_o         ;
     wire tlb_ie_o         ; 
     wire tlb_we_o         ; 
     wire tlb_fe_o         ;
     wire [4:0]tlb_op_o    ;
     wire refetch_flush_o;
     //cache
     wire sotre_buffer_we_o;
     wire idle_en_o,cacop_en_o;
     
     //跳转指令
     wire [`spIdBtypeWidth]              spIdBtype_i;
     wire [`spIdJmpWidth]                spIdJmp_i;
     wire is_branch_inst_i;
     wire [`PcWidth]        jmp_base_addr_i;
     wire [`PcWidth]        jmp_offs_addr_i;
     
     wire branch_i;          
     wire btb_hit_i;         
     wire [`ScountStateWidth]pht_state_i;  
     wire [`PcWidth]pre_pc_i;
     
     wire [`PcWidth] jmp_addr_o;

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//暂停信号
         wire stall;//mem要求exe级不能修改CPU状态，就是不能发出存储器写请求
//
wire now_ctl_valid;
wire now_ctl_base_valid;
wire excep_en;
//XXXX 模块变量定义       
         wire alu_equ_o;
         wire [`AluOperWidth]alu_rl_o;
         wire [`AluOperWidth]alu_rh_o;
          
         wire [1:0] mem_rwaddr_low2;
         wire op_sh;
         wire op_sb;
      
         
         //例外
         wire data_w_error;
         wire data_h_error;
         wire data_addr_error;
         //cache指令
         wire cacop_ready;
         wire cacop_inst;
         wire cacop_data;
        
         //握手
         wire now_ready_go;
         
/****************************************input decode(输入解码)***************************************/
    assign {
            idle_en_i,cacop_en_i,cacop_code_i,
            spIdBtype_i,spIdJmp_i,is_branch_inst_i,jmp_base_addr_i,jmp_offs_addr_i,  
            branch_i,btb_hit_i,pht_state_i,pre_pc_i,                          
            refetch_flush_i,
            tlb_fe_i,tlb_se_i,tlb_re_i,tlb_we_i,tlb_ie_i,
            tlb_op_i,
            is_kernel_inst_i,
            csr_wdata_src_i,regs_rdata1_i,regs_rdata2_i,
            excep_en_i,excep_type_i,
            llbit_we_i,llbit_wdata_i,
            csr_raddr_src_i,csr_we_i,csr_waddr_i,csr_wdata_i,//csr写使能
            exe_regs_wdata_src_i,alu_op_i,alu_oper1_i,alu_oper2_i,
            mem_regs_wdata_src_i,mem_mem_data_src_i,mem_req_i,mem_we_i,mem_wdata_i,
            wb_regs_wdata_src_i,regs_we_i,regs_waddr_i,regs_wdata_i,
            pc_i,inst_i} = pre_to_ibus;
            
            //15,1,2,4,5
/****************************************output code(输出解码)***************************************/
assign to_next_obus={
                     idle_en_o,cacop_en_o,cacop_code_i,
                     branch_flush_o,jmp_addr_o,
                     refetch_flush_o,sotre_buffer_we_o,
                     tlb_fe_o,tlb_se_o,tlb_re_o,tlb_we_o,tlb_ie_o,
                     tlb_op_o,tlb_search_type_o,
                     is_kernel_inst_i,csr_wdata_src_i,regs_rdata1_i,regs_rdata2_i,
                     excep_en_o,excep_type_o,
                     llbit_we_o,llbit_wdata_o,
                     csr_raddr_src_o,csr_we_o,csr_waddr_o,csr_wdata_o,//csr写使能
                     mem_regs_wdata_src_o,mem_mem_data_src_o,mem_req_o,mem_we_o,mem_rwaddr_o,
                     wb_regs_wdata_src_i,regs_we_o,regs_waddr_o,regs_wdata_o,
                     pc_i,inst_i};//32+1+5+32

assign forward_obus={
                     regs_we_o,regs_waddr_o,regs_wdata_o,
                     dr_stall_o};
//exe级需要传给cache的数据有哪些
//虚索引[11:0],load的请求,(目前打算写的信息还是exe级传输到D-cache的storebuffer,同时往下一个级传入一个storebuffer_we,)
//storebuffer_we如果有效且流到wb级,将其传给D-cache要求当前立即执行写状态,将store_buffer中数据写入到cache中
assign to_data_obus={mem_req_o,mem_we_o,mem_size_o,mem_wstrb_o,mem_rwaddr_o[11:0],mem_wdata_o};
assign sotre_buffer_we_o = mem_we_o;
//cacop指令请求
assign inst_cacop_req_o = cacop_inst & now_ctl_valid& (!stall);
assign data_cacop_req_o = cacop_data & now_ctl_valid& (!stall);

assign inst_cacop_obus = {cacop_code_i[4:3],alu_rl_o [11:0]};//虚拟地址
assign data_cacop_obus = {cacop_code_i[4:3],alu_rl_o [11:0]};
/*******************************complete logical function (逻辑功能实现)*******************************/
assign stall = cacop_en_i&now_ctl_base_valid&next_stages_valid_i;

assign cacop_inst = ~cacop_code_i[0]&cacop_en_i;
assign cacop_data = cacop_code_i[0]&cacop_en_i;
//当前发了请求，且收到free表示这个信号被接收了
assign cacop_ready = cacop_data ? data_cache_free_i:
                   cacop_inst ? inst_cache_free_i :1'b1;

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
   
                                                                                                                
     assign div_en_o = div_en & now_valid_i;                                                                                                                           
 
 
 
 
    //forward
    //如果exe级的数据必须等到mem级或者wb才能计算出则要阻塞id级
    assign dr_stall_o = (wb_regs_wdata_src_i |mem_regs_wdata_src_i) & now_valid_i;
    
    //存储器
    assign mem_rwaddr_low2 = mem_rwaddr_o[1:0];
    assign {op_sb,op_sh}  =  mem_mem_data_src_i[2:1]; 
    //请求信号必须在,mem阶段允许不被写入的时候才能有效 ，当前流水级有效
    //为了避免错误地址发到外部存储器中：出现有例外的时候，当前指令是有效的：但是不能发地址请求出去（由于例外把mem_req关闭了所以下一级不知道自己是不是访存指令）
    //assign mem_req_o      =   mem_req_i & mem_allowin_i & (~excep_flush_i) & ex_valid_i& (~excep_en_o);//当前wb没有发出例外信号
    assign mem_req_o      =   mem_req_i & next_allowin_i & (~excep_flush_i) & now_valid_i;//当前wb没有发出例外信号
    //只有当前wb不是例外，本级是不因为mem阶段指令携带了例外信息要暂停，exe阶段数据有效，且没有携带例外信息，且写使能输入有效，mem_we_o才可以生产有效信号
    assign {mem_we_o,mem_size_o,mem_wstrb_o}      =   !(mem_we_i && now_valid_i && (!excep_flush_i) && (!stall) && (!excep_en_o))?{ 1'b0,2'b0,4'b0000 }:
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
    assign regs_we_o       =  regs_we_i & now_ctl_valid & (!stall);//其实可以不考虑例外使能和me_空_stall,flush,携带了例外信息错误的id阶段指令会被冲刷掉的，mem_空_stall也会暂停id阶段
    
  //CSR 
    assign csr_raddr_src_o =  csr_raddr_src_i;
    assign csr_we_o        =  csr_we_i & now_ctl_valid & (!stall) ;
    assign csr_waddr_o     =  csr_waddr_i;
    assign csr_wdata_o     =  csr_wdata_i;
    //llbit
    assign llbit_we_o    =   llbit_we_i &now_ctl_valid& (!stall); 
    assign llbit_wdata_o =  llbit_wdata_i;
    //TLB
    //当前允许发出mem读请求:当前指令有效，当前没有流水线冲刷信号，mem_req_i有效,因为是查找地址（在准备访问地址），所以可以不考虑，下一级是否允许输入
    assign tlb_search_type_o = (mem_req_i & now_ctl_base_valid) ? (mem_we_i ? 2'b11 : 2'b10) : (tlb_se_i ? 2'b01:2'b00) ;
    assign tlb_re_o = tlb_re_i & now_ctl_valid & (!stall) ;
    assign tlb_se_o = tlb_se_i & now_ctl_valid & (!stall) ;
    assign tlb_ie_o = tlb_ie_i & now_ctl_valid & (!stall) ;
    assign tlb_we_o = tlb_we_i & now_ctl_valid & (!stall) ;
    assign tlb_fe_o = tlb_fe_i & now_ctl_valid & (!stall) ;
    assign tlb_op_o = tlb_op_i;
    
 //例外信息
    //内部例外
    //cache维护指令不触发地址不对齐例外
     assign data_h_error = cacop_en_i? 1'b0:(mem_req_o && op_sh && mem_rwaddr_low2[0] !=1'b0 )? 1'b1 : 1'b0;
     assign data_w_error = (mem_req_o && (!op_sh) && (!op_sb) && mem_rwaddr_low2 !=2'b00) ? 1'b1 : 1'b0;
     assign data_addr_error = data_w_error | data_h_error ;
     //例外信息输出
     assign excep_type_o[`IntLocation]  = excep_type_i[`IntLocation] ; //0
     assign excep_type_o[`PilLocation]  = excep_type_i[`PilLocation];//1
     assign excep_type_o[2]             = excep_type_i[2];
     assign excep_type_o[`PifLocation]  = excep_type_i[`PifLocation] ; //3
     assign excep_type_o[4]             = excep_type_i[4];
     assign excep_type_o[5]             = excep_type_i[5];
     assign excep_type_o[`AdefLocation] = excep_type_i[`AdefLocation]; //6
     assign excep_type_o[`AdemLocation] = excep_type_i[`AdemLocation]; //7
     //地址不对齐
     assign excep_type_o[`AleLocation] = data_addr_error & now_ctl_base_valid;//8
     assign excep_type_o[`FpeLocation:`SysLocation] = excep_type_i[`FpeLocation:`SysLocation]; //14：9
     assign excep_type_o[`TlbrLocation] = excep_type_i[`TlbrLocation];//15
     assign excep_type_o[`IfPpiLocation:`ErtnLocation] = excep_type_i[`IfPpiLocation:`ErtnLocation];//19：16 
     //例外使能输出
     assign excep_en   = excep_en_i | data_addr_error ;
     assign excep_en_o = excep_en &  now_ctl_base_valid;
     //重取冲刷
     assign refetch_flush_o = refetch_flush_i &now_ctl_valid;
     //跳转判断,分支预测更新
     Branch_Unit Branch_Unit_item(
        .rst_n             (rst_n ),
        //当前指令pc
        .pc_i              (pc_i),                     
        .inst_i            (inst_i),                  
        //B类跳转指令的类型                  (),      
        .spIdBtype_i       (spIdBtype_i),             
        //直接跳转指令信号                  (),       
        .spIdJmp_i         (spIdJmp_i ),               
        //寄存器1的值                   (),       
        .regs_rdata1_i     (regs_rdata1_i),                 
        //寄存器2的地址                    (),            
        .regs_rdata2_i     (regs_rdata2_i),                 
         //当前指令是跳转在指令                   (),                  
        .is_branch_inst_i  (is_branch_inst_i),         
         //跳转地址                    (),       
        .jmp_base_addr_i   (jmp_base_addr_i),          
        .jmp_offs_addr_i   (jmp_offs_addr_i),          
         //分支预测输入                  (),                                                         
        .branch_i          (branch_i   ),
        .btb_hit_i         (btb_hit_i  ),
        .pht_state_i       (pht_state_i),
        .branch_inst_pre_next_pc_i          (pre_pc_i   ),
        //当前阶段控制信号有效                   (),                   
        .now_ctl_valid_i      (now_ctl_valid),      
        .now_is_branch_inst_o (now_is_branch_inst_o),                                                    
        //是否更新跳转地址的使能信                  (),                  
        .branch_flush_o       (branch_flush_o),  
        //跳转转地址                       
        .jmp_addr_o           (jmp_addr_o),                                             
        //更新分支预测                      (),                   
        .to_pr_obus           (to_pr_obus)                      
   
   );
     //idle
     assign idle_en_o =  idle_en_i&now_ctl_valid;
     //cache
     assign cacop_en_o= cacop_en_i&now_ctl_valid;
     
     
     
      
     
     //信号有效
     assign now_ctl_valid = now_ctl_base_valid &(~excep_en);
     assign now_ctl_base_valid = now_valid_i&(~excep_flush_i);
    
    // 握手
    //如果mem阶段要求暂停本即则，ready不能=1,当不暂停的时候，本机是访存指令时候，要等发出req和收到addr_ok=1则ready.否则看alu_complete
      assign now_ready_go   = !stall ? (mem_req_i  ? (mem_req_o&data_sram_addr_ok_i ? 1'b1 : 1'b0) :((inst_cacop_req_o|data_cacop_req_o)?cacop_ready:alu_complete) ) :1'b0 ; //ifmem阶段指令携带了例外信息则，暂停本级流水
      assign now_allowin_o  = !now_valid_i //本级数据为空，允许if阶段写入
                           || (now_ready_go && next_allowin_i);//本级有数据要运行，本时钟周期，id阶段运算好了，exe也同时允许写入，同写，和取走数据
                           
      assign now_to_next_valid_o = now_valid_i && now_ready_go;//id阶段打算写入


endmodule
