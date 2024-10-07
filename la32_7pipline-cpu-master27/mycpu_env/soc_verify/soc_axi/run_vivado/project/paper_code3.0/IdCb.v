/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：本级要求返回的数据是寄存器中立马读出的，不能经过任何组合逻辑，这样时延就不会叠加
根据输入的指令立马解码出控制信号
*控制信号:


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
module IdCb(
    input  wire                            rst_n                ,
    
    input wire                             next_allowin_i       ,//输入ex已经完成当前数据了,允许你清除id_ex锁存器中的数据，将新数据给ex执行，1为允许,由ex传入
    input wire                             now_valid_i          , //ID阶段流水是空的，没有要执行的数据，1为有效 ，由id_ex传入,
    
    output wire                            now_allowin_o        ,//传给if，和id_exe,id阶段已经完成数据，允许你清除if_id锁存器内容
    output wire                            now_to_next_valid_o  ,//传给exe_mem，id阶段已经完成当前数据，想要将运算结果写入id_ex锁存器中，
    
    
    input wire                             excep_flush_i        ,
    
    input wire  [`LineIfToNextBusWidth]    pre_to_ibus          ,
    input wire  [63:0]                     inst_data_i          ,
    input wire                             inst_sram_data_ok_i  ,
   
    output wire [`LineIdToNextBusWidth]    to_next_obus         ,
    output wire [`LineIdToPreBusWidth]     to_pre_obus          ,
    output wire [`IdToPreifBusWidth]       to_preif_obus
    
);

/***************************************input variable define(输入变量定义)**************************************/
    wire [`PcWidth] pc_i;
    wire [`InstWidth]inst_i;
    wire inst_ram_req_i;
    
    //例外
    wire excep_en_i;
    wire [`ExceptionTypeWidth]excep_type_i;
   
    
    wire branch_i;
    wire btb_hit_i;
    wire [1:0]pht_state_i;
    wire [`PcWidth]pre_pc_i;
    
    

/***************************************ioutput variable define(输出变量定义)**************************************/
   

    // 跳转   
    wire [`PcWidth]        branch_addr_o;//跳转转地址
    //控制信号
    wire [`AluOpWidth]spExeAluOp;
    wire [`SignWidth]                sp_sign_o;
   
   
    //例外信号
    wire excep_en_o;
    wire [`ExceptionTypeWidth] excep_type_o;
    
    //预测的下指（因为btb的值不一定是预测下指）
    wire [`PcWidth]branch_inst_pre_next_pc_o;

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


 //指令控制信号产生模块定义
      wire [`IdToSpBusWidth] id_to_sp_ibus;
     
 
//jmp信号
    wire branch_flush_flag;
//顺序下指
    wire [`PcWidth]order_next_pc;    
    
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
   
    assign {inst_ram_req_i,
            branch_i,btb_hit_i,pht_state_i,pre_pc_i,
            excep_en_i,excep_type_i,
            pc_i} = pre_to_ibus;
    
    assign inst_i = ({32{pc_i[2]}}&inst_data_i[63:32])|({32{~pc_i[2]}}&inst_data_i[31:0]);
/****************************************output code(输出解码)***************************************/
    assign to_pre_obus  = branch_flush_flag_o;
    assign to_next_obus = {         
        branch_i,btb_hit_i,pht_state_i,branch_inst_pre_next_pc_o,//分支预测 
        excep_en_o,excep_type_o,
        spExeAluOp,sp_sign_o,      
        pc_i,inst_i};
    
    assign to_preif_obus = {branch_flush_flag_o,branch_addr_o};

     
    assign id_to_sp_ibus     = {rk,rj,rd,inst_i};
    
/*******************************complete logical function (逻辑功能实现)*******************************/

  //$$$$$$$$$$$$$$$（ 指令分解模块 模块调用）$$$$$$$$$$$$$$$$$$//
	 
     assign op = inst_i[31:10] ;

     assign rk = inst_i[14:10] ;
     assign rj = inst_i[9:5]   ;
     assign rd = inst_i[4:0]   ;
   //$$$$$$$$$$$$$$$（ 指令控制信号产生 模块调用）$$$$$$$$$$$$$$$$$$// 
        //模块输入：
        //模块调用：
             SignProduce sp(
             .id_to_ibus(id_to_sp_ibus),
             .inst_aluop_o(spExeAluOp),
             .inst_sign_o(sp_sign_o)
             );
             
     assign order_next_pc = pc_i+32'd4;
      
     //分支预测分支预测器版本
//     //当前指令是跳转指令    
//     assign is_branch_inst     = inst_i[30];
//     assign branch_flush_flag   =  is_branch_inst ? 1'b0 : 
//                                   pre_pc_i!= order_next_pc ? 1'b1:1'b0;
                                   
//     assign branch_flush_flag_o =  branch_flush_flag & now_ctl_valid ;
//     assign branch_addr_o = (pre_pc_i!= order_next_pc) ? order_next_pc : 32'd0;
    //分支预测，静态分支预测
       assign is_branch_inst     = inst_i[30];                                           
       assign branch_flush_flag  =  is_branch_inst & branch_i & btb_hit_i & (pre_pc_i !=order_next_pc );
                                                                           
       assign branch_flush_flag_o =  branch_flush_flag & now_ctl_valid ;                 
       assign branch_addr_o = branch_flush_flag ? pre_pc_i: 32'd0;  
       
       //只有pht预测跳转，且btb命中地址，跳转指令的预测下指令才是btb_pc
       assign branch_inst_pre_next_pc_o =  is_branch_inst & branch_i & btb_hit_i ?   pre_pc_i : order_next_pc; 
     
     //例外
       assign excep_en = excep_en_i;
       assign excep_en_o = excep_en &now_ctl_base_valid;
       assign excep_type_o = excep_type_i;
     //指令有效信号
     //必须是excep_en_o因为其携带了本级产生的例外信息(现在修改为excep_en,避免出现其他例外)
     assign now_ctl_valid      = now_ctl_base_valid &(~excep_en);
     assign now_ctl_base_valid = now_valid_i & (~excep_flush_i);
    
     
     // 握手
      assign now_ready_go        = inst_ram_req_i ? (inst_sram_data_ok_i ? 1'b1:1'b0):1'b1; //id阶段的指令准备好了
      assign now_allowin_o       = !now_valid_i //本级数据为空，允许if阶段写入
                                   || (now_ready_go && next_allowin_i);//本级有数据要运行，本时钟周期，id阶段运算好了，exe也同时允许写入，同写，和取走数据
      assign now_to_next_valid_o = now_valid_i && now_ready_go;//id阶段打算写入
 
    

endmodule

