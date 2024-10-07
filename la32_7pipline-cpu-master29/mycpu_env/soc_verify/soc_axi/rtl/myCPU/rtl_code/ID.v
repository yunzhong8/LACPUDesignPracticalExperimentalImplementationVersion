/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*控制信号:
*jmp_flag_o:是否发生跳转
*llbit_we_o:是否写llbit寄存器
regs_we_o
mem_we_o
mem_req_o
regs_re1_o
regs_re2_o
tlb_re_o
tlb_se_o
tlb_ie_o
tlb_we_o
tlb_fe_o
csr_we_o


*/
/*************\
bug:
1. jmp_flag_o这个跳转修改信号是会修改cpu状态的，所以要和id_valid_i相与
2. pcaddii12:运算数写错了alu_oper2_o = {imm20,12'd0};不是{12imm[19],00}
3. slli,srai的对应的oper2写错了，是lmm5进行0扩展
4. 位宽访问的时候是高位：低位，我经常写成低位：高位
5. csr_raddr的地址设置错误，一直设置为`LlbCtlRegAddr ，实际·只有csr读写指令有csr读需求，所以读地址只能是imm14
6. to_csr_obus顺序写错了，这个总线顺序对标有问题呢，llbit_we,llbit_wdata,在csr_we,waddr,wdata拼接
7. ll,sw的第二个操作数数是S(imm14<<00)与其他load，store指令的运算数是不同的
8. pc = 1c075250 是syscall指令，没有实现例外导致没有跳转到pc=1000_00008
9. csr的读写不在同一个时钟周期确实造成了问题，目前csr的forward很麻烦，怕自己考虑不全，导致后续启操作系统出现难以查找的bug,
将csr的读写移动到wb阶段
10. id阶段发出分支错误的冲刷信号有问题，这个冲刷信号是有条件的，造成错的根本原因就是阻塞，必须在本级下一个时钟周期一定写入exe，且本级数据有效且是跳转才行，
且如果if阶段会存在阻塞，id阶段流的话，本处还有考虑,之前没考虑阻塞，直接有跳转信号就冲刷，到id阶段是阻塞，到阻塞的指令被冲刷了
11. 设计是不合理的，不应该在其他地方引入加法器，应该alu的加法
*****************启发*******应该对每一段流水发生阻塞进行讨论，if段阻塞，if,id段阻塞，if,id,ex发生阻塞，if,id,ex,mem,发生阻塞，if,id,ex,mem,wb发生阻塞
************对携带例外信息造成分段讨论
11.rdcntid.w 的寄存器组写地址是rj,我设置错了，在execle的中写成$1
12.在双发设的逻辑中使用到了读地址和写地址，如果没有读写使能的话是无法判断出当前line1和line2是否发生相关，所以需要引入读使能，在当前数据有效的情况下有效，
同时一些不读寄存器的指令也应该设置为读无效，避免造成发射堵塞，减低双发射的概率，读使能需要设在两个
\*************/
`include "DefineCsrAddr.h"
`include "DefineModuleBus.h"
`include "DefineSignLocation.h"
module ID(
    input  wire  rst_n    ,
    
    input wire  next_allowin_i,//输入ex已经完成当前数据了,允许你清除id_ex锁存器中的数据，将新数据给ex执行，1为允许,由ex传入
    input wire  now_valid_i, //ID阶段流水是空的，没有要执行的数据，1为有效 ，由id_ex传入,
    
   
    output wire now_allowin_o,//传给if，和id_exe,id阶段已经完成数据，允许你清除if_id锁存器内容
    output wire now_to_next_valid_o,//传给exe_mem，id阶段已经完成当前数据，想要将运算结果写入id_ex锁存器中，
    
    //output id_to_ex_staLineIdToRfbBusWidthll_o,//要求暂停exe阶段插入气泡
    input wire excep_flush_i,
    
   

    input wire  [`LineIdToNextBusWidth]        pre_to_ibus,
    input wire  [`LineRegsRigthReadBusWidth] regs_rigth_read_ibus        ,
    input wire  [`CoutToIdBusWidth]          cout_to_ibus,
    
    output wire                              want_done_en_o,//输出当前指令是不访存指令
    
    output wire [5:0]                        wregs_obus,
    
    output wire [`LineLaunchToNextBusWidth]        to_next_obus,
   
   
    output wire [`LineRegsReadIbusWidth]       to_rfb_obus
);

/***************************************input variable define(输入变量定义)**************************************/
    //数据部分
    wire [`PcWidth] pc_i;
    wire [`InstWidth]inst_i;
    wire [`SignWidth]                sp_sign_i;
    
    //例外
    wire excep_en_i;
    wire [`ExceptionTypeWidth]excep_type_i;
    
    wire  [63:0] counter_i;
    wire  [31:0] counterid_i;
    //部件ready信号
    wire regs_read_ready_i;
    
    wire branch_i;
    wire btb_hit_i;
    wire [1:0]pht_state_i;
    wire [`PcWidth]pre_pc_i;
    
    

/***************************************ioutput variable define(输出变量定义)**************************************/
    wire regs_re1_o;
    wire regs_re2_o;
    wire [`RegsAddrWidth]    regs_raddr1_o;//寄存器组读地址1
    wire [`RegsAddrWidth]    regs_raddr2_o;//寄存器组读地址2
    wire [`AluOpWidth]       alu_op_o             ;
    wire [`AluOperWidth]     alu_oper1_o          ;
    reg [`AluOperWidth]      alu_oper2_o          ;
    wire [`spExeRegsWdataSrcWidth]                exe_regs_wdata_src_o;
    //存储器输出
    wire                   mem_req_o;
    wire                   mem_we_o;//存储器写使能信号
    wire  [`spMemRegsWdataSrcWidth]               mem_regs_wdata_src_o;//存储器读出数据类型
    wire  [`spMemMemDataSrcWidth]                 mem_mem_data_src_o;
    wire  [`MemDataWidth]           mem_wdata_o;
    //寄存器输出
    wire                       regs_we_o     ;//寄存器组写使能
    wire  [`RegsAddrWidth]     regs_waddr_o  ;//寄存器写地址
    wire  [`RegsDataWidth]     regs_wdata_o  ;//寄存器写入数据
    wire  [`RegsDataWidth]     regs_rdata1_o ;
    wire  [`RegsDataWidth]     regs_rdata2_o ;
    //csr
    //wire [`CsrAddrWidth]csr_raddr_o;
    wire is_kernel_inst_o;
    wire csr_wdata_src_o;
    wire csr_raddr_src_o;
    wire csr_we_o;
    wire [`CsrAddrWidth]csr_waddr_o;
    wire [`RegsDataWidth]csr_wdata_o;
    wire wb_regs_wdata_src_o;

    // 跳转   
    wire [`PcWidth]        jmp_base_addr;
    wire [`PcWidth]        jmp_offs_addr;
    
    //llbit
    wire llbit_we_o;
    wire llbit_wdata_o;
    //例外信号
    wire excep_en_o;
    wire [`ExceptionTypeWidth] excep_type_o;
    wire refetch_flush_o;
    wire idle_en_o;
    wire cacop_en_o;
    wire [4:0]cacop_code_o;
    wire [31:0]cache_va_o;
    //tlb
    wire tlb_re_o         ;
    wire tlb_se_o         ;
    wire tlb_ie_o         ;
    wire tlb_we_o         ;
    wire tlb_fe_o         ;
    wire [4:0]tlb_op_o    ;
    
    //分支预测
   
    wire pht_we_o;
    wire [`ScountAddrWidth]pht_waddr_o;
    wire [`ScountStateWidth]pht_wdata_o;
    
    wire btb_we_o;
    wire btb_wvalid_o;
    wire [`BtbAddrWidth] btb_waddr_o;
    wire [`BiatWidth] btb_wtag_o;
    wire [31:0]btb_wdata_o;//位宽是多少
   
    

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
// 握手信号
    wire now_ready_go;
// 当前控制信号有效(即输入的是有效的,但是输出则要看now_ctl_valid),if now_ctl_valid==0,则表明当前所有控制信号无效,即等于0,所以对控制信号的设置必须是高点平有效
 //依赖:valid(最基本的),flsuh信号(其有效是否页依赖当前指令是否是valid)   
 wire now_ctl_valid;  
 wire now_ctl_base_valid;  
 
 
//指令分解 模块变量定义
     wire   [21:0]    op               ;
    
     wire   [4:0]     rj               ;
     wire   [4:0]     rk               ;
     wire   [4:0]     rd               ;
    
     wire   [4:0]     imm5;
     wire   [11:0]    imm12            ;
     wire   [13:0]    imm14            ;
     wire    [15:0]   imm16;
     wire   [19:0]    imm20;
     
     wire   [25:0]    imm26            ;

     wire   [31:0]    sign_ext_imm12   ;
     wire    [31:0]   sign_ext_imm16   ;
     wire   [31:0]    sign_ext_imm20  ;
     wire   [31:0]    sign_ext_imm26   ;
     
     wire   [31:0]    zero_ext_imm5;
     wire   [31:0]    zero_ext_imm12   ;
     wire    [31:0]   zero_ext_imm16   ;
     wire   [31:0]    zero_ext_imm20  ;
     wire   [31:0]    zero_ext_imm26   ;



 //指令控制信号产生模块定义
      wire [`IdToSpBusWidth] id_to_sp_ibus;
     //Id阶段
     wire                             spIdRegsRead1Src;//id阶段使用的控制寄存器组第二读端口的读地址
     wire [`spIdRegsRead2SrcWidth]    spIdRegsRead2Src;//id阶段使用的控制寄存器组第二读端口的读地址
    
     wire [`spIdAluOpaSrcWidth]       spIdAluOpaSrc;
     wire [`spIdAluOpbSrcWidth]       spIdAluOpbSrc;
     
     wire [`spIdRegsWaddrSrcWidth]    spIdRegsWaddrSrc;
     wire [`spIdRegsWdataSrcWidth]    spIdRegsWdataSrc;
     
     //llbit
     
     wire spIdLlbitwdataSrc;
     wire spIdCsrWdataSrc;
     wire spIdCsrRaddrSrc;
    
     

     //EXE
     wire [`spExeRegsWdataSrcWidth]   spExeRegsWdataSrc;
     wire [`AluOpWidth]               spExeAluOp;
     wire                             spTlbSe;
     
     //MEM
     wire [`spMemReqWidth]            spMemReq;
     wire [`spMemMemWeWidth]          spMemMemWe;
     wire [`spMemRegsWdataSrcWidth]   spMemRegsWdataSrc;//mem阶段寄存器写入数据：是mem还是exe
     wire [`spMemMemDataSrcWidth]     spMemMemDataSrc;//mem阶段寄存器写入的数据类型000:来自alu,>1表示来着data_sram
     
     //WB
     wire [`EnWidth]  spWbRegsWe ;
     wire             spIdLlbitWe;
     wire             spWbRegWdataSrc;
     
     wire             spTlbRe;
     wire             spTlbWe;
     wire             spTlbIe;
     wire             spTlbFe;
     
      //CSR
     wire             spWbCsrWe;
     //分支
     //wire spIdB;
     wire [`spIdBtypeWidth]              spIdBtype;
     wire [`spIdJmpWidth]                spIdJmp;
     wire [`spIdJmpBaseAddrSrcWidth]     spIdJmpBaseAddrSrc;
     wire [`spIdJmpOffsAddrSrcWidth]     spIdJmpOffsAddrSrc;
    //Excep
     wire [`spExcepTypeWidth]spexcep ;
     wire                    spkernelinst;
     wire spflush;
     wire spidle;
     wire spcache;
    
    
//解决数据相关后寄存器组读出数据
    wire [`RegsDataWidth]regs_rdata1;
    wire [`RegsDataWidth]regs_rdata2;
    wire llbit_rdata;
//内部例外
    wire sys_excep_en;
    wire brk_excep_en;
    wire ertn_en;
    wire ine_excep_en;//这个例外信息作用在下一条指令
    
    wire excep_en;
    wire is_branch_inst;
 //除法
    wire div_en;   
 
/****************************************input decode(输入解码)***************************************/
   
    assign counter_i = cout_to_ibus;
    assign {branch_i,btb_hit_i,pht_state_i,pre_pc_i,
            excep_en_i,excep_type_i,
            spExeAluOp,sp_sign_i,
            pc_i,inst_i} = pre_to_ibus;
    assign {regs_read_ready_i,regs_rdata2,regs_rdata1} = regs_rigth_read_ibus;
    

/****************************************output code(输出解码)***************************************/
    assign to_rfb_obus = {regs_re2_o,regs_raddr2_o,regs_re1_o,regs_raddr1_o};
    assign to_if_obus = 1'b0;
    assign to_next_obus = {   
        idle_en_o,cacop_en_o,cacop_code_o,
        spIdBtype,spIdJmp,is_branch_inst,jmp_base_addr,jmp_offs_addr,
        branch_i,btb_hit_i,pht_state_i,pre_pc_i,
        refetch_flush_o,
        tlb_fe_o,tlb_se_o,tlb_re_o,tlb_we_o,tlb_ie_o,
        tlb_op_o,
        is_kernel_inst_o,
        csr_wdata_src_o,regs_rdata1_o,regs_rdata2_o,
        excep_en_o,excep_type_o,//例外
        llbit_we_o,llbit_wdata_o,//llbit写
        csr_raddr_src_o,csr_we_o,csr_waddr_o,csr_wdata_o,//csr写使能
        exe_regs_wdata_src_o,alu_op_o,alu_oper1_o,alu_oper2_o,
        mem_regs_wdata_src_o,mem_mem_data_src_o,mem_req_o,mem_we_o,mem_wdata_o,
        wb_regs_wdata_src_o,regs_we_o,regs_waddr_o,regs_wdata_o,
        pc_i,inst_i};
    
    assign wregs_obus    = {regs_we_o ,regs_waddr_o};
     
    assign id_to_sp_ibus     = {rk,rj,rd,inst_i};
    
/*******************************complete logical function (逻辑功能实现)*******************************/

  //$$$$$$$$$$$$$$$（ 指令分解模块 模块调用）$$$$$$$$$$$$$$$$$$// 
	//模块输入：
	//模块调用：
	 
     assign op = inst_i[31:10] ;

     assign rk = inst_i[14:10] ;
     assign rj = inst_i[9:5]   ;
     assign rd = inst_i[4:0]   ;

     assign imm5 = rk;
     assign imm12 = inst_i[21:10] ;  //21-10=11+1=12
     assign imm16 = inst_i[25:10];
     assign imm14 = inst_i[23:10];
     assign imm20 = inst_i[24:5];
     assign imm26 = {inst_i[9:0],inst_i[25:10]};

     assign sign_ext_imm12 = {{20{imm12[11]}},imm12};
     assign sign_ext_imm16 = {{16{imm16[15]}},imm16};
     assign sign_ext_imm20 = {{12{imm20[19]}},imm20};
     assign sign_ext_imm26 = {{6{imm26[25]}},imm26};
     
     assign zero_ext_imm5 =  {27'd0,imm5};
     assign zero_ext_imm12 = {20'h0_0000,imm12};
     assign zero_ext_imm16 = {16'h0000,imm16};
     assign zero_ext_imm20 = {12'h000,imm20};
     assign zero_ext_imm26 = {6'd0,imm26};
    	

   //$$$$$$$$$$$$$$$（ 指令控制信号拆分）$$$$$$$$$$$$$$$$$$// 
     
       //ID阶段信号spIdRegsWdataSrc为最高位，高位 次高位 次低位 低位
             assign {spIdCsrRaddrSrc,spIdCsrWdataSrc,
                     spIdLlbitwdataSrc,
                     spIdRegsWdataSrc,spIdRegsWaddrSrc,
                     spIdAluOpbSrc,spIdAluOpaSrc,
                     spIdRegsRead2Src,spIdRegsRead1Src} = sp_sign_i[`ID_SIGN_LOCATION];
      //跳转信号
             assign {spIdJmpOffsAddrSrc,spIdJmpBaseAddrSrc,
                     spIdJmp,spIdBtype
                     }= sp_sign_i[`B_SIGN_LOCATION];
      //获取EXE阶段信号
           assign {spTlbSe,spExeRegsWdataSrc} = sp_sign_i[`EXE_SIGN_LOCATION];
       //MEM
        assign {spMemReq,spMemMemDataSrc,spMemRegsWdataSrc,spMemMemWe}=sp_sign_i[`MEM_SIGN_LOCATION];
        //assign spMemReq=1'b1;
        
      //WB
        assign {spTlbFe,spTlbIe,spTlbWe,spTlbRe,
                spWbRegWdataSrc,spIdLlbitWe,spWbCsrWe,spWbRegsWe}=sp_sign_i[`WB_SIGN_LOCATION];
      //例外信号
        assign {spcache,spidle,spflush,spkernelinst,spexcep}=sp_sign_i[`EXCEP_SIGN_LOCATION];
    
 //*******************************************计算输出***********************************************//
//ID阶段使用
     //################计算寄存器读输出################//
    //ID阶段
    assign regs_rdata1_o  = regs_rdata1;
    assign regs_rdata2_o  = regs_rdata2;
      //寄存器读地址1
      assign {regs_re1_o,regs_raddr1_o } = !now_valid_i ? {1'b0,5'd0} :
                                           (spIdRegsRead1Src == 1'b1) ? {1'b1,rj} :{1'b0,5'd0};
           
      //寄存器读地址2
      assign {regs_re2_o,regs_raddr2_o} = !now_valid_i ? {1'b0,5'd0} :
                                          (spIdRegsRead2Src == 2'b01) ? {1'b1,rk} :
                                          (spIdRegsRead2Src == 2'b10) ? {1'b1,rd} :{1'b0,5'd0};
                                        
                                 
       
  
       assign csr_raddr_src_o = spIdCsrRaddrSrc;
       assign csr_waddr_o =  imm14;
       assign csr_wdata_o =  32'b0;
       assign csr_wdata_src_o = spIdCsrWdataSrc;
       
   //################计算寄ALU(EXE)输出################//
          //ALU运算类型
             assign alu_op_o = spExeAluOp;
         //ALu_oper1运算器运算数1
             assign alu_oper1_o = spIdAluOpaSrc ? pc_i : regs_rdata1;
            
        //ALu_oper2运算器运算数2
             always@(*)begin
                 if(rst_n == `RstEnable)begin
                     alu_oper2_o = `AluOperLen'd0;
                 end else begin
                     case(spIdAluOpbSrc)
                         `spIdAluOpbSrcLen'd0: alu_oper2_o = regs_rdata2;
                         `spIdAluOpbSrcLen'd1: alu_oper2_o = zero_ext_imm12;
                         `spIdAluOpbSrcLen'd2: alu_oper2_o = sign_ext_imm12;
                         `spIdAluOpbSrcLen'd3: alu_oper2_o = {imm20,12'd0};
                         `spIdAluOpbSrcLen'd4: alu_oper2_o = zero_ext_imm5;
                         `spIdAluOpbSrcLen'd5: alu_oper2_o = { {16{imm14[13]}},imm14,2'b00};
                         default: alu_oper2_o = `AluOperLen'd0; 
                     endcase
                 end
             end
                assign exe_regs_wdata_src_o = spExeRegsWdataSrc;
             
                assign div_en = (alu_op_o == `DivAluOp) || (alu_op_o == `ModAluOp) || (alu_op_o == `DivuAluOp) || (alu_op_o == `ModuAluOp) ? now_ctl_valid : 1'b0;                                                     
    //mem阶段
            
            assign mem_req_o            = spMemReq|(spcache&&rd[4:3]==2'd2) & now_ctl_valid    ; //存储器使能
            
             //sc的写使能取消放在wb阶段,不用在id阶段就判断出,因为采用store_buffer机制
            assign mem_we_o             =  spMemMemWe & now_ctl_valid ;
            assign mem_regs_wdata_src_o = spMemRegsWdataSrc ; //存储阶段寄存器写入类型选择
            assign mem_mem_data_src_o   = spMemMemDataSrc   ;
            assign mem_wdata_o          = regs_rdata2       ; //存储器写入数据
            
  //  ################计算WB(regs_write)输出################//         
        assign regs_we_o = spWbRegsWe & now_ctl_valid;//wb阶段寄存器写使能
    //寄存器组写入地址         
       assign  regs_waddr_o =  (spIdRegsWaddrSrc== 2'd1)   ? rj :
                               (spIdRegsWaddrSrc == 2'd2)  ? `RegsAddrLen'd1 : rd;
                               
         
     //寄存器写回数据
        assign regs_wdata_o = (spIdRegsWdataSrc == 3'd0) ? {imm20,12'b0} :
                              (spIdRegsWdataSrc == 3'd1) ? pc_i+32'd4     :
                              (spIdRegsWdataSrc == 3'd2) ? {counter_i[31:0]} :
                              (spIdRegsWdataSrc == 3'd3) ? {counter_i[63:32]} :`RegsDataLen'd0;
                            
        
        //tlb
        assign tlb_re_o = spTlbRe & now_ctl_valid;
        assign tlb_se_o = spTlbSe & now_ctl_valid;
        assign tlb_ie_o = spTlbIe & now_ctl_valid;
        assign tlb_we_o = spTlbWe & now_ctl_valid;
        assign tlb_fe_o = spTlbFe & now_ctl_valid;
        assign tlb_op_o = rd;
        
        
        //CSR
        assign is_kernel_inst_o = spkernelinst;//当前在指令是不是内核指令
        assign csr_we_o    = spWbCsrWe & now_ctl_valid;
        assign wb_regs_wdata_src_o = spWbRegWdataSrc;
        
        
  

    //################跳转计算################//         
      assign jmp_base_addr = spIdJmpBaseAddrSrc ? regs_rdata1: pc_i;
      assign jmp_offs_addr = spIdJmpOffsAddrSrc ? { {4{imm26[25]}},imm26,2'h0 } : { {14{imm16[15]}},imm16,2'h0 };
     
     //################原子访存
     assign llbit_we_o = spIdLlbitWe & now_ctl_valid;
     assign llbit_wdata_o = spIdLlbitwdataSrc ? 1'b1 : 1'b0;
     
     //例外(本级内容的例外信息)
     assign sys_excep_en = (spexcep ==`spExcepTypeLen'd2)? 1'b1:1'b0;//sys指令例外
     assign brk_excep_en = (spexcep ==`spExcepTypeLen'd1)? 1'b1:1'b0;//break例外
     assign ine_excep_en = (spexcep ==`spExcepTypeLen'd5)||(spTlbIe&& rd>`TlbInvOpMax)? 1'b1:1'b0;//指令非法例外
     assign ertn_en = (spexcep ==`spExcepTypeLen'd3)? 1'b1:1'b0;//返回指令例外
    
     //例外
     assign excep_type_o[`SysLocation-1:0] = excep_type_i[`SysLocation-1:0];
     //ID阶段中断
     assign excep_type_o[`SysLocation] = sys_excep_en & now_ctl_base_valid;
     assign excep_type_o[`BrkLocation] = brk_excep_en & now_ctl_base_valid;
     assign excep_type_o[`IneLocation] = ine_excep_en & now_ctl_base_valid;
     assign excep_type_o[`ErtnLocation-1:`IneLocation+1] = excep_type_i[`ErtnLocation-1:`IneLocation+1];
     //返回指令
     assign excep_type_o[`ErtnLocation]= ertn_en & now_ctl_base_valid;
     assign excep_type_o[`IfPpiLocation:`IfTlbrLocation] = excep_type_i[`IfPpiLocation:`IfTlbrLocation];
     
     assign excep_en   = (excep_en_i | sys_excep_en | brk_excep_en | ine_excep_en|ertn_en);  
     assign excep_en_o =  excep_en & now_ctl_base_valid;
    
     //重取
     assign refetch_flush_o = spflush & now_ctl_base_valid;
     //idle指令
     assign idle_en_o = spidle&now_ctl_valid; 
     assign cacop_en_o= spcache&now_ctl_valid;
     assign cacop_code_o = rd;
     //分支预测    
     assign is_branch_inst = inst_i[30];
      
      

     
     //指令有效信号
     //必须是excep_en_o因为其携带了本级产生的例外信息(现在修改为excep_en,避免出现其他例外)
     assign now_ctl_valid      = now_ctl_base_valid &(~excep_en);
     assign now_ctl_base_valid = now_valid_i & (~excep_flush_i);
     
     //当前指令有效，且不是访存和除法类指令，这条指令就可以被双发射
    //当id_valid_i无效的时候，是想被执行的
    assign want_done_en_o    = (!(spMemReq || div_en||spTlbRe||spTlbSe||spTlbIe||spTlbWe||spTlbFe) && now_valid_i ) ||  ~now_valid_i    ; 
     
     // 握手
      assign now_ready_go   = regs_read_ready_i; //id阶段数据是否运算好了，要求
      assign now_allowin_o  = !now_valid_i //本级数据为空，允许if阶段写入
                           || (now_ready_go && next_allowin_i);//本级有数据要运行，本时钟周期，id阶段运算好了，exe也同时允许写入，同写，和取走数据
      assign now_to_next_valid_o = now_valid_i && now_ready_go;//id阶段打算写入
 
   
   
   
   
   
   
   
   
     

endmodule

