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
//`include "DefineCsrAddr.h"
//`include "DefineModuleBus.h"
//`include "DefineSignLocation.h"
`include "define.v"
module IfTCb(
    input  wire                            rst_n                ,
    
    input wire                             next_allowin_i       ,//输入ex已经完成当前数据了,允许你清除id_ex锁存器中的数据，将新数据给ex执行，1为允许,由ex传入
    input wire                             now_valid_i          , //ID阶段流水是空的，没有要执行的数据，1为有效 ，由id_ex传入,
    
    output wire                            now_allowin_o        ,//传给if，和id_exe,id阶段已经完成数据，允许你清除if_id锁存器内容
    output wire                            now_to_next_valid_o  ,//传给exe_mem，id阶段已经完成当前数据，想要将运算结果写入id_ex锁存器中，
    output wire                            line2_now_to_next_valid_o,
    
    
    input wire                             excep_flush_i        ,
    
    input wire  [`IfToNextBusWidth]        pre_to_ibus          ,
    input wire  [63:0]                     inst_data_i          ,
    input wire                             inst_sram_data_ok_i  ,
   
    output wire                        puc_we_o   ,                   
    output wire [`PucAddrWidth]        puc_waddr_o, 
    output wire                        puc_wdata_o,                
    
    
    
    output wire  [`PucWbusWidth]            to_puc_obus,      
    output wire [`IftToNextBusWidth]        to_next_obus         ,
    output wire [`LineIftToPreBusWidth]     to_pre_obus          ,//无用
    output wire [`IftToPreifBusWidth]       to_preif_obus
    
);

/***************************************input variable define(输入变量定义)**************************************/
   
    wire [`PcWidth]pc1_i;
    wire [`PcWidth]pc2_i;
    wire [`InstWidth]inst1_i;
    wire [`InstWidth]inst2_i;
    wire inst_ram_req_i;
    wire pre_uncache_i;//预测的uncache
    wire uncache_i;
    
    
    
    //分支预测器
 wire branch_i ;//1为命中，0为没有命中则使用pc+4
 wire btb_hit_i;//btb没有命中则使用顺序地址
 wire [`PcWidth]btb_branch_pc_i;
 wire [`ScountStateWidth]pht_state_i;
    
    //例外信号
    wire [`ExceptionTypeWidth]line1_excep_type_i;
    wire line1_excep_en_i;
    wire [`ExceptionTypeWidth]line2_excep_type_i;
    wire line2_excep_en_i;
    
    
    
    

/***************************************ioutput variable define(输出变量定义)**************************************/
   
    wire [`LineIftToNextBusWidth] line2_to_next_bus,line1_to_next_bus;
    // 跳转   
    wire [`PcWidth]        branch_addr_o;//跳转转地址
//    //更新puc
//    wire puc_we_o;
//    wire [`PucAddrWidth]puc_waddr_o;
//    wire puc_wdata_o;
   
    //例外信号
    wire [`ExceptionTypeWidth]line1_excep_type_o;
    wire line1_excep_en_o;
    wire [`ExceptionTypeWidth]line2_excep_type_o;
    wire line2_excep_en_o;
    

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
// 握手信号
    wire now_ready_go;
// 当前控制信号有效(即输入的是有效的,但是输出则要看now_ctl_valid),if now_ctl_valid==0,则表明当前所有控制信号无效,即等于0,所以对控制信号的设置必须是高点平有效
 //依赖:valid(最基本的),flsuh信号(其有效是否页依赖当前指令是否是valid)   
 wire now_ctl_valid;  
 wire now_ctl_base_valid;  
 //流水线2有效
 wire line2_en;
 
//jmp信号
    wire branch_flush_flag;   
    
  wire line1_pc_is_odd=pc1_i[2];
/****************************************input decode(输入解码)***************************************/
   
    assign {pre_uncache_i,uncache_i,inst_ram_req_i,
            branch_i,btb_hit_i,pht_state_i,btb_branch_pc_i,
            line2_excep_en_i,line2_excep_type_i,pc2_i,
            line1_excep_en_i,line1_excep_type_i,pc1_i
    
    } = pre_to_ibus;
            
         
            
            
    
    assign inst1_i = ({32{line1_pc_is_odd}}&inst_data_i[63:32])|({32{~line1_pc_is_odd}}&inst_data_i[31:0]);
    assign inst2_i = inst_data_i[63:32];
/****************************************output code(输出解码)***************************************/
    assign to_pre_obus  = branch_flush_flag_o;
    assign line1_to_next_bus = {
        branch_i,btb_hit_i,pht_state_i,btb_branch_pc_i,
        line1_excep_en_o,line1_excep_type_o,pc1_i,inst1_i
        };
   assign line2_to_next_bus = {
        branch_i,btb_hit_i,pht_state_i,btb_branch_pc_i,
        line2_excep_en_o,line2_excep_type_o,pc2_i,inst2_i
        };
    assign to_next_obus = { line2_to_next_bus,line1_to_next_bus};
    
    assign to_preif_obus = {branch_flush_flag_o,branch_addr_o};

   assign to_puc_obus = {puc_we_o,puc_waddr_o,puc_wdata_o}; 
    
/*******************************complete logical function (逻辑功能实现)*******************************/

  //$$$$$$$$$$$$$$$（ 指令分解模块 模块调用）$$$$$$$$$$$$$$$$$$//
	 
    
   
    //uncache预测错误                                          
       assign branch_flush_flag   = line1_pc_is_odd?1'b0:pre_uncache_i^uncache_i;
                                                                           
       assign branch_flush_flag_o = branch_flush_flag & now_ctl_valid&now_allowin_o ; 
       //
       // 1 0 使用错误下指：line1_pc+8,改为line1_pc+4
       // 0 1 使用错误下指：line1_pc+4，改为line1_pc+8               
       assign branch_addr_o       = uncache_i&~pre_uncache_i ? pc2_i: pc2_i+32'd4;  
     
       //update pcu
       assign puc_we_o    = pre_uncache_i^uncache_i& now_ctl_valid;
       assign puc_waddr_o = pc1_i[16:12];
       assign puc_wdata_o = uncache_i;
     //例外
    
       
       assign line1_excep_en_o  = line1_excep_en_i && now_valid_i;
       assign line1_excep_type_o= line1_excep_type_i;
        
       assign line2_excep_en_o  =  line2_excep_en_i && now_valid_i;
       assign line2_excep_type_o=  line2_excep_type_i;
      //
      assign line2_en =  uncache_i?1'b0:( line1_pc_is_odd?1'b0:1'b1);
     //指令有效信号
     //必须是excep_en_o因为其携带了本级产生的例外信息(现在修改为excep_en,避免出现其他例外)
     assign now_ctl_valid      = now_ctl_base_valid &(~line1_excep_en_i);
     assign now_ctl_base_valid = now_valid_i & (~excep_flush_i);
    
     
     // 握手
      assign now_ready_go        = inst_ram_req_i ? (inst_sram_data_ok_i ? 1'b1:1'b0):1'b1; //id阶段的指令准备好了
      assign now_allowin_o       = !now_valid_i //本级数据为空，允许if阶段写入
                                   || (now_ready_go && next_allowin_i);//本级有数据要运行，本时钟周期，id阶段运算好了，exe也同时允许写入，同写，和取走数据
      assign now_to_next_valid_o       = now_valid_i && now_ready_go;//id阶段打算写入
      assign line2_now_to_next_valid_o = line2_en&now_valid_i && now_ready_go;
 
    

endmodule

