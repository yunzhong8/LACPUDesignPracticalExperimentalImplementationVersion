/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*
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
    
    input wire ex_allowin_i,//输入ex已经完成当前数据了,允许你清除id_ex锁存器中的数据，将新数据给ex执行，1为允许,由ex传入
    input wire id_valid_i, //ID阶段流水是空的，没有要执行的数据，1为有效 ，由id_ex传入,
    
   
    output wire id_allowin_o,//传给if，和id_exe,id阶段已经完成数据，允许你清除if_id锁存器内容
    output wire id_to_ex_valid_o,//传给exe_mem，id阶段已经完成当前数据，想要将运算结果写入id_ex锁存器中，
    
    //output id_to_ex_staLineIdToRfbBusWidthll_o,//要求暂停exe阶段插入气泡
    input wire excep_flush_i,
    
   

    input wire   [`LineIfToIdBusWidth]if_to_ibus,
    input wire   [`LineRegsRigthReadBusWidth]regs_rigth_read_ibus        ,
    input wire  [`CoutToIdBusWidth]cout_to_ibus,
    
    output wire want_done_en_o,//输出当前指令是不访存指令
    output wire icache_find_o,//cache查找成功信号
    output wire [5:0]wregs_obus,
    
    output wire [`LineIdToExBusWidth]to_idex_obus,
    output wire [`IdToPreifBusWidth]to_preif_obus,
    output wire [`LineIdToRfbBusWidth]to_rfb_obus
);

/***************************************input variable define(输入变量定义)**************************************/
    wire [`PcWidth] pc_i;
    wire [`InstWidth]inst_i;
    
    //例外
    wire excep_en_i;
    wire [`ExceptionTypeWidth]excep_type_i;
    //icache
    wire icache_find_i;
    
    wire  [63:0] counter_i;
    wire  [31:0] counterid_i;
    //部件ready信号
    wire regs_read_ready_i;
    
    

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
    wire  [`spMemRegsWdataSrcWidth]                  mem_regs_wdata_src_o;//存储器读出数据类型
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
    wire                   jmp_flag_o;//跳转标志
    wire [`PcWidth]        jmp_addr_o;//跳转转地址
    
    //llbit
    wire llbit_we_o;
    wire llbit_wdata_o;
    //例外信号
    wire excep_en_o;
    wire [`ExceptionTypeWidth] excep_type_o;

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
// 握手信号
    wire id_ready_go;
   
    
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
     
     //MEM
     wire [`spMemReqWidth]            spMemReq;
     wire [`spMemMemWeWidth]          spMemMemWe;
     wire [`spMemRegsWdataSrcWidth]   spMemRegsWdataSrc;//mem阶段寄存器写入数据：是mem还是exe
     wire [`spMemMemDataSrcWidth]     spMemMemDataSrc;//mem阶段寄存器写入的数据类型000:来自alu,>1表示来着data_sram
     
     //WB
     wire [`EnWidth]  spWbRegsWe ;
     wire spIdLlbitWe;
     wire spWbRegWdataSrc;
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
     wire spkernelinst;
    
    
     wire [`SignWidth]                sp_sign_o;
 
//jmp信号
    reg jmp_flag;
    
//解决数据相关后寄存器组读出数据
    wire [`RegsDataWidth]regs_rdata1;
    wire [`RegsDataWidth]regs_rdata2;
    wire llbit_rdata;
 
 
/****************************************input decode(输入解码)***************************************/
   
    assign counter_i = cout_to_ibus;
    assign {icache_find_i,excep_en_i,excep_type_i,pc_i,inst_i} = if_to_ibus;
    assign {regs_read_ready_i,llbit_rdata,regs_rdata2,regs_rdata1} = regs_rigth_read_ibus;

/****************************************output code(输出解码)***************************************/
    assign to_rfb_obus = {regs_re2_o,regs_raddr2_o,regs_re1_o,regs_raddr1_o};
    
    assign to_idex_obus = { 
        is_kernel_inst_o,
        csr_wdata_src_o,regs_rdata1_o,regs_rdata2_o,
        excep_en_o,excep_type_o,//例外
        llbit_we_o,llbit_wdata_o,//llbit写
        csr_raddr_src_o,csr_we_o,csr_waddr_o,csr_wdata_o,//csr写使能
        exe_regs_wdata_src_o,alu_op_o,alu_oper1_o,alu_oper2_o,
        mem_regs_wdata_src_o,mem_mem_data_src_o,mem_req_o,mem_we_o,mem_wdata_o,
        wb_regs_wdata_src_o,regs_we_o,regs_waddr_o,regs_wdata_o,
        pc_i,inst_i};
    
    assign to_preif_obus = {jmp_flag_o,jmp_addr_o};
    assign wregs_obus    = {regs_we_o ,regs_waddr_o};
   //当前指令有效，且不是访存和除法类指令，这条指令就可以被双发射
   //当id_valid_i无效的时候，是想被执行的
    assign want_done_en_o    = (!(spMemReq || div_en ) && id_valid_i ) ||  ~id_valid_i    ;    
    assign id_to_sp_ibus     = {rk,rj,rd,inst_i};
    //icache查找失败
    
    
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
     
     assign zero_ext_imm5 = {27'd0,imm5};
     assign zero_ext_imm12 = {20'h0_0000,imm12};
     assign zero_ext_imm16 = {16'h0000,imm16};
     assign zero_ext_imm20 = {12'h000,imm20};
     assign zero_ext_imm26 = {6'd0,imm26};
    	

   //$$$$$$$$$$$$$$$（ 指令控制信号产生 模块调用）$$$$$$$$$$$$$$$$$$// 
        //模块输入：
        //模块调用：
             SignProduce sp(
             .id_to_ibus(id_to_sp_ibus),
             .inst_aluop_o(spExeAluOp),
             .inst_sign_o(sp_sign_o)
             );
             //ID阶段信号spIdRegsWdataSrc为最高位，高位 次高位 次低位 低位
                   assign {spIdCsrRaddrSrc,spIdCsrWdataSrc,
                           spIdLlbitwdataSrc,
                           spIdRegsWdataSrc,spIdRegsWaddrSrc,
                           spIdAluOpbSrc,spIdAluOpaSrc,
                           spIdRegsRead2Src,spIdRegsRead1Src} = sp_sign_o[`ID_SIGN_LOCATION];
            //跳转信号
                   assign {spIdJmpOffsAddrSrc,spIdJmpBaseAddrSrc,
                           spIdJmp,spIdBtype
                           }= sp_sign_o[`B_SIGN_LOCATION];
            //获取EXE阶段信号
                 assign spExeRegsWdataSrc = sp_sign_o[`EXE_SIGN_LOCATION];
             //MEM
              assign {spMemReq,spMemMemDataSrc,spMemRegsWdataSrc,spMemMemWe}=sp_sign_o[`MEM_SIGN_LOCATION];
              //assign spMemReq=1'b1;
              
            //WB
              assign {spWbRegWdataSrc,spIdLlbitWe,spWbCsrWe,spWbRegsWe}=sp_sign_o[`WB_SIGN_LOCATION];
            //例外信号
              assign {spkernelinst,spexcep}=sp_sign_o[`EXCEP_SIGN_LOCATION];
    
 	
   //$$$$$$$$$$$$$$$（ B类跳转指令 模块）$$$$$$$$$$$$$$$$$$//     
        //比较
        always @(*)begin
            if(rst_n == `RstEnable)begin
                jmp_flag = 1'b0;
            end else if (spIdJmp == 1'b1)begin//无条件跳转
                jmp_flag = 1'b1;
            end else begin
                case(spIdBtype)
                    `spIdBtypeLen'd1:begin
                        jmp_flag = regs_rdata1 == regs_rdata2?1'b1:1'b0;
                     end
                     `spIdBtypeLen'd2:begin
                        jmp_flag = regs_rdata1 != regs_rdata2?1'b1:1'b0;
                     end
                     `spIdBtypeLen'd3:begin
                        jmp_flag = $signed(regs_rdata1) <$signed(regs_rdata2)?1'b1:1'b0;
                      end
                     `spIdBtypeLen'd4:begin
                        jmp_flag = $signed(regs_rdata1) <$signed(regs_rdata2)?1'b0:1'b1;
                      end
                     `spIdBtypeLen'd5:begin
                        jmp_flag = $unsigned(regs_rdata1) <$unsigned(regs_rdata2)?1'b1:1'b0;
                      end
                      `spIdBtypeLen'd6:begin
                        jmp_flag = $unsigned(regs_rdata1) <$unsigned(regs_rdata2)?1'b0:1'b1;
                      end
                      default: jmp_flag = 1'b0;  
                endcase
            end
        end
        assign jmp_flag_o = jmp_flag && id_valid_i && (!excep_en_o) && (!excep_flush_i);//本级携带了例外信息，不应该有执行效果，例外冲刷不应该有关执行小哥哥
 //*******************************************计算输出***********************************************//
//ID阶段使用
     //################计算寄存器读输出################//
    //ID阶段
    assign regs_rdata1_o = regs_rdata1;
    assign regs_rdata2_o  = regs_rdata2;
      //寄存器读地址1
      assign {regs_re1_o,regs_raddr1_o } = !id_valid_i ? {1'b0,5'd0} :
                                           (spIdRegsRead1Src == 1'b1) ? {1'b1,rj} :{1'b0,5'd0};
           
      //寄存器读地址2
      assign {regs_re2_o,regs_raddr2_o} = !id_valid_i ? {1'b0,5'd0} :
                                          (spIdRegsRead2Src == 2'b01) ? {1'b1,rk} :
                                          (spIdRegsRead2Src == 2'b10) ? {1'b1,rd} :{1'b0,5'd0};
                                        
                                 
       
       //assign csr_raddr_o =  spIdCsrRaddrSrc ? imm14 : `TIdRegAddr;
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
                assign div_en = (alu_op_o == `DivAluOp) || (alu_op_o == `ModAluOp) || (alu_op_o == `DivuAluOp) || (alu_op_o == `ModuAluOp) ? 1'b1 : 1'b0;                                                     
    //mem阶段
            
            assign mem_req_o            = spMemReq          ; //存储器使能
            assign mem_we_o             =  (spIdLlbitWe&&(spIdLlbitwdataSrc == 1'b0)) ? (spMemMemWe & llbit_rdata):spMemMemWe; //if是scw指令，如果llbit——rdata=0，则mem_we写使能失效
            assign mem_regs_wdata_src_o = spMemRegsWdataSrc ; //存储阶段寄存器写入类型选择
            assign mem_mem_data_src_o   = spMemMemDataSrc   ;
            assign mem_wdata_o          = regs_rdata2       ; //存储器写入数据
            
  //  ################计算WB(regs_write)输出################//         
        assign regs_we_o = spWbRegsWe & id_valid_i;//wb阶段寄存器写使能
    //寄存器组写入地址
//         always@(*)begin
//                if(rst_n==`RstEnable)begin
//                    regs_waddr_o =`RegsAddrLen'd0;
//                end else begin
//                    case(spIdRegsWaddrSrc)
//                        2'd0:regs_waddr_o = rd;
//                        2'd1:regs_waddr_o = rj;
//                        2'd2:regs_waddr_o = `RegsAddrLen'd1;
//                        default: regs_waddr_o = `RegsAddrLen'd0;
//                    endcase
//                end
//         end
         
      assign    regs_waddr_o = (spIdRegsWaddrSrc== 2'd1)   ? rj :
                               (spIdRegsWaddrSrc == 2'd2)  ? `RegsAddrLen'd1 : rd;
                               
         
     //寄存器写回数据
//       assign counterid_i = 32'h0;
//        always @(*)begin
//            if(rst_n == `RstEnable)begin
//                regs_wdata_o = `RegsDataLen'd0;
//            end else begin
//                case(spIdRegsWdataSrc)
//                        3'd0:regs_wdata_o = {imm20,12'b0};//装在指令
//                        3'd1:regs_wdata_o = pc_i+32'd4;
//                        3'd2:regs_wdata_o = counter_i[31:0];
//                        3'd3:regs_wdata_o = counter_i[63:32];
//                        3'd4:regs_wdata_o = counterid_i;
//                        3'd5:regs_wdata_o = 32'h0;
//                        default:regs_wdata_o = `RegsDataLen'd0;
//                endcase
//            end
//        end
        
        assign regs_wdata_o = (spIdRegsWdataSrc == 3'd0) ? {imm20,12'b0} :
                              (spIdRegsWdataSrc == 3'd1) ? pc_i+32'd4     :
                              (spIdRegsWdataSrc == 3'd2) ? {counter_i[31:0]} :
                              (spIdRegsWdataSrc == 3'd3) ? {counter_i[63:32]} :`RegsDataLen'd0;
                            
        
        
        
        
        //CSR
        assign is_kernel_inst_o = spkernelinst;//当前在指令是不是内核指令
        assign csr_we_o    = spWbCsrWe;
        assign wb_regs_wdata_src_o = spWbRegWdataSrc;
        
        
  

    //################跳转计算################//         
      wire [`PcWidth] jmp_base_addr;
      wire [`PcWidth] jmp_offs_addr;
      assign jmp_base_addr = spIdJmpBaseAddrSrc ? regs_rdata1: pc_i;
      assign jmp_offs_addr = spIdJmpOffsAddrSrc ? { {4{imm26[25]}},imm26,2'h0 } : { {14{imm16[15]}},imm16,2'h0 };
      assign jmp_addr_o = jmp_base_addr + jmp_offs_addr;
     
     //################原子访存
     assign llbit_we_o = spIdLlbitWe;
     assign llbit_wdata_o = spIdLlbitwdataSrc ? 1'b1 : 1'b0;
     
     //例外
     wire sys_excep_en;
     wire brk_excep_en;
     wire ertn_en;
     wire ine_excep_en;
     assign sys_excep_en = (spexcep ==`spExcepTypeLen'd2)? 1'b1:1'b0;//sys指令例外
     assign brk_excep_en = (spexcep ==`spExcepTypeLen'd1)? 1'b1:1'b0;//break例外
     assign ine_excep_en = (spexcep ==`spExcepTypeLen'd5)? 1'b1:1'b0;//指令非法例外
     assign ertn_en = (spexcep ==`spExcepTypeLen'd3)? 1'b1:1'b0;//返回指令例外
      assign excep_en_o = (excep_en_i | sys_excep_en | brk_excep_en | ine_excep_en|ertn_en) & id_valid_i;
      assign excep_type_o[`SysLocation-1:0] = excep_type_i[`SysLocation-1:0];
      //ID阶段中断
      assign excep_type_o[`SysLocation] = sys_excep_en;
      assign excep_type_o[`BrkLocation] = brk_excep_en;
      assign excep_type_o[`IneLocation] = ine_excep_en;
      assign excep_type_o[`ErtnLocation-1:`IneLocation+1] = excep_type_i[`ErtnLocation-1:`IneLocation+1];
      //返回指令
      assign excep_type_o[`ErtnLocation]= ertn_en;
      //icache 
      assign icache_find_o = icache_find_i;
     
     // 握手
      assign id_ready_go   = regs_read_ready_i; //id阶段数据是否运算好了，要求
      assign id_allowin_o  = !id_valid_i //本级数据为空，允许if阶段写入
                           || (id_ready_go && ex_allowin_i);//本级有数据要运行，本时钟周期，id阶段运算好了，exe也同时允许写入，同写，和取走数据
      assign id_to_ex_valid_o = id_valid_i && id_ready_go;//id阶段打算写入
 
   

endmodule

