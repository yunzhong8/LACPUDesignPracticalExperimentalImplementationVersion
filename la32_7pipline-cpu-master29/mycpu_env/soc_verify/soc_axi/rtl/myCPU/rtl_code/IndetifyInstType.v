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
mulhwu的控制信号写成modsign了导致exe阶段的reg控制写入信号错误
\*************/
`include "DefineModuleBus.h"
`include "DefineInstSign.h"
`include "DefineAluOp.h"
module IndetifyInstType(
    //input  wire [63:0] op_31_26_d_i_i_i;
    //input  wire [15:0] op_25_22_d_i_i_i;
    //input  wire [ 3:0] op_21_20_d_i_i_i;
    //input  wire [31:0] op_19_15_d_i_i;
    input  wire  [`OdToIspBusWidth]od_to_ibus,
    output  wire  [`SignWidth] inst_sign_o   ,
    output wire [`AluOpWidth] inst_aluop_o
);
/***************************************parameter define(常量定义)**************************************/

/***************************************variable define(变量定义)**************************************/
wire [63:0] op_31_26_d_i;
wire [15:0] op_25_22_d_i;
wire [ 3:0] op_21_20_d_i;
wire [31:0] op_19_15_d_i;
wire [31:0]rk_d_i;
wire [31:0]rd_d_i;
wire [31:0]rj_d_i;

wire [`InstWidth]inst_i;
wire inst_add_w; 
wire inst_sub_w;  
wire inst_slt;    
wire inst_sltu;   
wire inst_nor;    
wire inst_and;    
wire inst_or;     
wire inst_xor;     
wire inst_lu12i_w;
wire inst_addi_w;
wire inst_slti;
wire inst_sltui;
wire inst_pcaddi;
wire inst_pcaddu12i;
wire inst_andn;
wire inst_orn;
wire inst_andi;
wire inst_ori;
wire inst_xori;
wire inst_mul_w;
wire inst_mulh_w;
wire inst_mulh_wu;
wire inst_div_w;
wire inst_mod_w;
wire inst_div_wu;
wire inst_mod_wu;

wire inst_slli_w;  
wire inst_srli_w;  
wire inst_srai_w;  
wire inst_sll_w;
wire inst_srl_w;
wire inst_sra_w;

wire inst_jirl;   
wire inst_b;      
wire inst_bl;     
wire inst_beq;    
wire inst_bne; 
wire inst_blt;
wire inst_bge;
wire inst_bltu;
wire inst_bgeu;

wire inst_ll_w;
wire inst_sc_w;
wire inst_ld_b;
wire inst_ld_bu;
wire inst_ld_h;
wire inst_ld_hu;
wire inst_ld_w;
wire inst_st_b;
wire inst_st_h;
wire inst_st_w;

wire inst_syscall;
wire inst_break;
wire inst_csrrd;
wire inst_csrwr;
wire inst_csrxchg;
wire inst_ertn;

wire inst_rdcntid_w;
wire inst_rdcntvl_w;
wire inst_rdcntvh_w;
wire inst_idle;

wire inst_tlbsrch;
wire inst_tlbrd;
wire inst_tlbwr;
wire inst_tlbfill;
wire inst_invtlb;

wire inst_cacop;
wire inst_preld;
wire inst_dbar;
wire inst_ibar;


/*******************************complete logical function (逻辑功能实现)*******************************/
assign {rk_d_i,rj_d_i,rd_d_i,op_31_26_d_i,op_25_22_d_i,op_21_20_d_i,op_19_15_d_i,inst_i}=od_to_ibus;





assign inst_add_w      = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h00];
assign inst_sub_w      = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h02];
assign inst_slt        = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h04];
assign inst_sltu       = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h05];
assign inst_nor        = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h08];
assign inst_and        = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h09];
assign inst_or         = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h0a];
assign inst_xor        = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h0b];
assign inst_orn        = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h0c];
assign inst_andn       = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h0d];
assign inst_sll_w      = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h0e];
assign inst_srl_w      = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h0f];
assign inst_sra_w      = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h10];
//assign inst_mul_w      = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h18];
assign inst_mul_w      = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h18];//原来18现在修改为24
assign inst_mulh_w     = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h19];
assign inst_mulh_wu    = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h1] & op_19_15_d_i[5'h1a];
assign inst_div_w      = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h2] & op_19_15_d_i[5'h00];
assign inst_mod_w      = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h2] & op_19_15_d_i[5'h01];
assign inst_div_wu     = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h2] & op_19_15_d_i[5'h02];
assign inst_mod_wu     = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h2] & op_19_15_d_i[5'h03];
assign inst_break      = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h2] & op_19_15_d_i[5'h14];
assign inst_syscall    = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h2] & op_19_15_d_i[5'h16];
assign inst_slli_w     = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h1] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h01];
assign inst_srli_w     = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h1] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h09];
assign inst_srai_w     = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h1] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h11];
assign inst_idle       = op_31_26_d_i[6'h01] & op_25_22_d_i[4'h9] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h11];
assign inst_invtlb     = op_31_26_d_i[6'h01] & op_25_22_d_i[4'h9] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h13];
assign inst_dbar       = op_31_26_d_i[6'h0e] & op_25_22_d_i[4'h1] & op_21_20_d_i[2'h3] & op_19_15_d_i[5'h04];
assign inst_ibar       = op_31_26_d_i[6'h0e] & op_25_22_d_i[4'h1] & op_21_20_d_i[2'h3] & op_19_15_d_i[5'h05];
assign inst_slti       = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h8];
assign inst_sltui      = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h9];
assign inst_addi_w     = op_31_26_d_i[6'h00] & op_25_22_d_i[4'ha];
assign inst_andi       = op_31_26_d_i[6'h00] & op_25_22_d_i[4'hd];
assign inst_ori        = op_31_26_d_i[6'h00] & op_25_22_d_i[4'he];
assign inst_xori       = op_31_26_d_i[6'h00] & op_25_22_d_i[4'hf];
assign inst_ld_b       = op_31_26_d_i[6'h0a] & op_25_22_d_i[4'h0];
assign inst_ld_h       = op_31_26_d_i[6'h0a] & op_25_22_d_i[4'h1];
assign inst_ld_w       = op_31_26_d_i[6'h0a] & op_25_22_d_i[4'h2];
assign inst_st_b       = op_31_26_d_i[6'h0a] & op_25_22_d_i[4'h4];
assign inst_st_h       = op_31_26_d_i[6'h0a] & op_25_22_d_i[4'h5];
assign inst_st_w       = op_31_26_d_i[6'h0a] & op_25_22_d_i[4'h6];
assign inst_ld_bu      = op_31_26_d_i[6'h0a] & op_25_22_d_i[4'h8];
assign inst_ld_hu      = op_31_26_d_i[6'h0a] & op_25_22_d_i[4'h9];
assign inst_cacop      = op_31_26_d_i[6'h01] & op_25_22_d_i[4'h8];
assign inst_preld      = op_31_26_d_i[6'h0a] & op_25_22_d_i[4'hb];
assign inst_jirl       = op_31_26_d_i[6'h13];
assign inst_b          = op_31_26_d_i[6'h14];
assign inst_bl         = op_31_26_d_i[6'h15];
assign inst_beq        = op_31_26_d_i[6'h16];
assign inst_bne        = op_31_26_d_i[6'h17];
assign inst_blt        = op_31_26_d_i[6'h18];
assign inst_bge        = op_31_26_d_i[6'h19];
assign inst_bltu       = op_31_26_d_i[6'h1a];
assign inst_bgeu       = op_31_26_d_i[6'h1b];
assign inst_lu12i_w    = op_31_26_d_i[6'h05] & ~inst_i[25];
assign inst_pcaddi     = op_31_26_d_i[6'h06] & ~inst_i[25];
assign inst_pcaddu12i  = op_31_26_d_i[6'h07] & ~inst_i[25];
assign inst_csrxchg    = op_31_26_d_i[6'h01] & ~inst_i[25] & ~inst_i[24] & (~rj_d_i[5'h00] & ~rj_d_i[5'h01]);  //rj != 0,1
assign inst_ll_w       = op_31_26_d_i[6'h08] & ~inst_i[25] & ~inst_i[24];
assign inst_sc_w       = op_31_26_d_i[6'h08] & ~inst_i[25] &  inst_i[24];
assign inst_csrrd      = op_31_26_d_i[6'h01] & ~inst_i[25] & ~inst_i[24] & rj_d_i[5'h00];
assign inst_csrwr      = op_31_26_d_i[6'h01] & ~inst_i[25] & ~inst_i[24] & rj_d_i[5'h01];
assign inst_rdcntid_w  = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h00] & rk_d_i[5'h18] & rd_d_i[5'h00];
assign inst_rdcntvl_w  = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h00] & rk_d_i[5'h18] & rj_d_i[5'h00] & !rd_d_i[5'h00];
assign inst_rdcntvh_w  = op_31_26_d_i[6'h00] & op_25_22_d_i[4'h0] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h00] & rk_d_i[5'h19] & rj_d_i[5'h00];

assign inst_ertn       = op_31_26_d_i[6'h01] & op_25_22_d_i[4'h9] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h10] & rk_d_i[5'h0e] & rj_d_i[5'h00] & rd_d_i[5'h00];

assign inst_tlbsrch    = op_31_26_d_i[6'h01] & op_25_22_d_i[4'h9] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h10] & rk_d_i[5'h0a] & rj_d_i[5'h00] & rd_d_i[5'h00];
assign inst_tlbrd      = op_31_26_d_i[6'h01] & op_25_22_d_i[4'h9] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h10] & rk_d_i[5'h0b] & rj_d_i[5'h00] & rd_d_i[5'h00];
assign inst_tlbwr      = op_31_26_d_i[6'h01] & op_25_22_d_i[4'h9] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h10] & rk_d_i[5'h0c] & rj_d_i[5'h00] & rd_d_i[5'h00];
assign inst_tlbfill    = op_31_26_d_i[6'h01] & op_25_22_d_i[4'h9] & op_21_20_d_i[2'h0] & op_19_15_d_i[5'h10] & rk_d_i[5'h0d] & rj_d_i[5'h00] & rd_d_i[5'h00];
   
    assign inst_sign_o =      inst_add_w      ? `AddwInstSign      :
                              inst_sub_w      ? `SubwInstSign      :
                              inst_slt        ? `SltInstSign       :
                              inst_sltu       ? `SltuInstSign      :
                              inst_nor        ? `NorInstSign       :
                              inst_and        ? `AndInstSign       :
                              inst_or         ? `OrInstSign        :
                              inst_xor        ? `XorInstSign       :

                              inst_orn        ? `NorInstSign       : //new
                              inst_andn       ? `NandInstSign      ://new不在基础指令集中
                              inst_sll_w      ? `SllwInstSign      :
                              inst_srl_w      ? `SrlwInstSign      :
                              inst_sra_w      ? `SrawInstSign      :
                              inst_mul_w      ? `MulwInstSign      :
                              inst_mulh_w     ? `MulhwInstSign     :
                              inst_mulh_wu    ? `MulhwuInstSign    :
                              inst_mod_w      ? `ModwInstSign      :
                              inst_div_w      ? `DivwInstSign      :
                              inst_div_wu     ? `DivwuInstSign     :
                              inst_mod_wu     ? `ModwuInstSign     :
                              inst_break      ? `BreakInstSign     :
                              inst_syscall    ? `SyscallInstSign   ://new

                              inst_slli_w     ? `SlliwInstSign     :
                              inst_srli_w     ? `SrliwInstSign     :
                              inst_srai_w     ? `SraiwInstSign     :

                              inst_idle       ? `IdleInstSign      :
                              inst_invtlb     ? `InvtlbInstSign    :  
                              inst_dbar       ? `DbarInstSign      :  
                              inst_ibar       ? `IbarInstSign      :  
                              inst_slti       ? `SltiInstSign      :
                             // inst_slti       ? 40'h0   :
                              inst_sltui      ? `SltuiInstSign     :

                              inst_addi_w     ? `AddiwInstSign     :

                              inst_andi       ? `AndiInstSign      :
                              inst_ori        ? `OriInstSign       :
                              inst_xori       ? `XoriInstSign      :
                              inst_ld_b       ? `LdbInstSign       :
                              inst_ld_h       ? `LdhInstSign       :
                              inst_ld_w       ? `LdwInstSign       :
                              inst_st_b       ? `StbInstSign       :
                              inst_st_h       ? `SthInstSign       :
                              inst_st_w       ? `StwInstSign       :
                              inst_ld_bu      ? `LdbuInstSign      :
                              inst_ld_hu      ? `LdhuInstSign      :
                              inst_cacop      ? `CacopInstSign     :
                              inst_preld      ? `PreldInstSign     :
                              
                              inst_st_w       ? `StwInstSign       :
                              inst_jirl       ? `JirlInstSign      :
                              inst_b          ?`BInstSign          :
                              inst_bl         ?`BlInstSign         :
                              inst_beq        ?`BeqInstSign        :
                              inst_bne        ?`BneInstSign        :
                              inst_blt        ?`BltInstSign        :        

                              inst_bge        ?`BgeInstSign        :
                              inst_bltu       ? `BltuInstSign      :      
                              inst_bgeu       ? `BgeuInstSign      :      
                              inst_lu12i_w    ? `Lu12iwInstSign    :   
                              inst_pcaddi     ? `PcaddiInstSign    ://不在基础指令集中  
                              inst_pcaddu12i  ? `Pcaddu12iInstSign : 
                              inst_csrxchg    ? `CsrxchgInstSign   :
                              inst_ll_w       ? `LlwInstSign       :
                              inst_sc_w       ? `ScwInstSign       :
                              inst_csrrd      ? `CsrrdInstSign     :
                              inst_csrwr      ? `CsrwrInstSign     :
                              inst_rdcntid_w  ? `RdcntidwInstSign  :
                              inst_rdcntvl_w  ? `RdcntvlwInstSign  :
                              inst_rdcntvh_w  ? `RdcntvhwInstSign  :
                              inst_ertn       ? `ErtnInstSign      :
                              inst_tlbsrch    ? `TlbsrchInstSign   :
                              inst_tlbrd      ? `TlbrdInstSign     :
                              inst_tlbwr      ? `TlbwrInstSign     :
                              inst_tlbfill    ? `TlbfillInstSign   : `NoExistInstSign;

    assign inst_aluop_o =     inst_add_w ? `AddAluOp   :
                              inst_sub_w ? `SubAluOp   :
                              inst_slt   ? `SltAluOp    :
                              inst_sltu  ? `SltuAluOp   :
                              inst_nor   ? `NorAluOp    :
                              inst_and   ? `AndAluOp    :
                              inst_or    ? `OrAluOp     :
                              inst_xor   ? `XorAluOp    : 

                              inst_orn   ? `NorAluOp   : //new
                              inst_andn  ? `AndAluOp    ://new
                              inst_sll_w  ? `SllAluOp:
                              inst_srl_w  ? `SrlAluOp    :
                              inst_sra_w  ? `SraAluOp    :
                              inst_mul_w ? `MulAluOp   :
                              inst_mulh_w ? `MulAluOp :
                              inst_mulh_wu  ? `MuluAluOp  :
                              inst_mod_w  ? `ModAluOp  :
                              inst_div_w  ? `DivAluOp :
                              inst_div_wu ? `DivuAluOp :
                              inst_mod_wu ? `ModuAluOp :
                              inst_break  ? `NoAluOp:
                              inst_syscall ? `NoAluOp ://new

                              inst_slli_w ? `SllAluOp :
                              inst_srli_w ? `SrlAluOp :
                              inst_srai_w ? `SraAluOp :

                              inst_idle     ? `NoAluOp :
                              inst_invtlb   ? `NoAluOp :
                              inst_dbar     ? `NoAluOp :
                              inst_ibar     ? `NoAluOp :
                              inst_slti     ? `SltAluOp:
                              inst_sltui    ? `SltuAluOp:


                              inst_addi_w ?`AddAluOp  :

                              inst_andi  ? `AndAluOp:
                              inst_ori   ? `OrAluOp :
                              inst_xori  ? `XorAluOp:
                              inst_ld_b  ? `AddAluOp:
                              inst_ld_h  ? `AddAluOp  :
                              inst_ld_w  ? `AddAluOp :
                              inst_st_b  ? `AddAluOp  :
                              inst_st_h  ? `AddAluOp  :
                              inst_st_w  ? `AddAluOp :
                              inst_ld_bu ? `AddAluOp:
                              inst_ld_hu ? `AddAluOp :
                              inst_cacop ? `NoAluOp  :
                              inst_preld ? `NoAluOp  :

                              inst_jirl ? `NoAluOp    :
                              inst_b ?`NoAluOp          :
                              inst_bl ?`NoAluOp         :
                              inst_beq ?`NoAluOp       :
                              inst_bne ?`NoAluOp      :

                              inst_bge ?`NoAluOp        :
                              inst_bltu ? `NoAluOp     :
                              inst_bgeu ? `NoAluOp     :

                              inst_lu12i_w  ?`NoAluOp :

                              inst_pcaddi   ? `AddAluOp  :
                              inst_pcaddu12i ? `AddAluOp  :
                              inst_csrxchg    ? `NoAluOp :
                              inst_ll_w       ? `NoAluOp    :
                              inst_sc_w       ? `NoAluOp    :
                              inst_csrrd      ? `NoAluOp  :
                              inst_csrwr      ? `NoAluOp  :
                              inst_rdcntid_w  ? `NoAluOp  :
                              inst_rdcntvl_w  ? `NoAluOp :
                              inst_rdcntvh_w  ? `NoAluOp :
                              inst_ertn       ? `NoAluOp :
                              inst_tlbsrch    ? `NoAluOp :
                              inst_tlbrd      ? `NoAluOp  :
                              inst_tlbwr      ? `NoAluOp  :
                              inst_tlbfill ? `NoAluOp : `NoAluOp;


endmodule

