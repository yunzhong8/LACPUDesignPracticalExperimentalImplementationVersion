/*
*作者：zzq
*创建时间：2023-04-09
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：实现csr寄存器组
*
*/
/*************\
bug:
1. crmd有初始化值的忘记rstl复位的是赋值
2. we使用的是waddr比较，re使用raddr比较，我使用raddr作为比较输出waddr，raddr,真呆
3. 手册说没有规定复位值的寄存器的初始值都是未知的结果crmd初始值是xxxx_xxx8结果错了,因为样例cpu的初始值是0000_0008
4. crmd的赋值使用了=不是<=，导致其寄存器的值立马被修改为0，00，prmd的中断的时候保存的是修改后的值即0，00，一直错误
5. error:miss compiler directive 的原因是我的宏定义在值哪一部分的多了一个“`”,eg:`define TcfgInitValLocation `TimeValLen-1:2`,这个就会报错
7. 定时计算的时钟周期不对齐，我设置的定时器的时钟周期和他们设置的不一样，tm，我咋知道时钟定时开始和时钟定时结束的时间呢和
8. 忘记清理ti的中断信号了，清理的条件是：ticlr_we=1&&ticlr_wdata[0]=1,我写成了ticlr_we=1& ticlr_wdata

9. 定时中断设置和定时中断清理是有优先级的，清理的优先级高于设置的，设置的要求是：tcfg.en=1 && tval=0,这个信号好像会一直持续直到tcfg.en=0,对吗
而，tcfg.en只能通过csr_wc指令设置为0，这？问题在tval值没有再次赋值的时候默认是-1.

10. ti,pi中断忘记写屏蔽位了，导致错误找了2023.4.20一中午
\*************/
`include "DefineModuleBus.h"
`include "DefineCsrAddr.h"
module Csr(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
    input  wire [`ExcepToCsrWidth] excep_to_ibus,
    input  wire [`WbToCsrWidth] wb_to_ibus ,
    input  wire [7:0] hardware_interrupt_data_i,
    
    output wire [`CsrToIdWidth] to_id_obus,
    output wire [`CsrToWbWidth] to_wb_obus ,
    output wire interrupt_en_o             ,
    output wire [`CsrToPreifWidth]          to_preif_obus 
);

/***************************************input variable define(输入变量定义)**************************************/
    wire [`CsrAddrWidth]  line2_csr_raddr_i;
    wire [`CsrAddrWidth]  line2_csr_waddr_i;
    wire [`RegsDataWidth] line2_csr_wdata_i;
    wire line2_csr_we_i;
    //llbit
    wire line2_llbit_we_i;
    wire line2_llbit_wdata_i;
    
    wire [`CsrAddrWidth]  line1_csr_raddr_i;
    wire [`CsrAddrWidth]  line1_csr_waddr_i;
    wire [`RegsDataWidth] line1_csr_wdata_i;
    wire line1_csr_we_i;
    //llbit
    wire line1_llbit_we_i;
    wire line1_llbit_wdata_i;
    
    
    
    
    //例外
    wire excep_en_i;
    wire [`EcodeWidth]excep_ecode_i;
    wire [`EsubCodeWidth]excep_esubcode_i;
    wire [`PcWidth]excep_pc_i;
    wire excep_badv_we_i;
    wire [`PcWidth]excep_badv_wdata_i;
    //例外返回
    wire ertn_en_i;
/***************************************output variable define(输出变量定义)**************************************/
    wire [`RegsDataWidth]line1_csr_rdata_o;
    wire [`RegsDataWidth]line2_csr_rdata_o;
    wire [`PcWidth]excep_entry_pc_o;
    wire [`PcWidth]ertn_pc_o       ;
    
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//写使能
wire line1_crmd_we;
wire line1_prmd_we,line1_euen_we,line1_ecfg_we,line1_estat_we, line1_era_we,line1_badv_we,line1_eentry_we;
//tlb
wire line1_tlbidx_we,line1_tlbehi_we,line1_tlbelo0_we,line1_tlbelo1_we;
//目录
wire line1_asid_we,line1_pgdl_we,line1_pgdh_we,line1_pgd_we;
//处理器编号
wire line1_cpuid_we;
//数据保存
wire line1_save0_we,line1_save1_we,line1_save2_we,line1_save3_we;
//定时
wire line1_tid_we,line1_tcfg_we,line1_tval_we,line1_ticlr_we;
//原子访存
wire line1_llbctl_we;
// 
wire line1_tlbrentry_we;
wire line1_ctag_we;
//直接映射配置窗口
wire line1_dmw0_we,line1_dmw1_we;


//写使能
wire line2_crmd_we;
wire line2_prmd_we,line2_euen_we,line2_ecfg_we,line2_estat_we, line2_era_we,line2_badv_we,line2_eentry_we;
//tlb
wire line2_tlbidx_we,line2_tlbehi_we,line2_tlbelo0_we,line2_tlbelo1_we;
//目录
wire line2_asid_we,line2_pgdl_we,line2_pgdh_we,line2_pgd_we;
//处理器编号
wire line2_cpuid_we;
//数据保存
wire line2_save0_we,line2_save1_we,line2_save2_we,line2_save3_we;
//定时
wire line2_tid_we,line2_tcfg_we,line2_tval_we,line2_ticlr_we;
//原子访存
wire line2_llbctl_we;
// 
wire line2_tlbrentry_we;
wire line2_ctag_we;
//直接映射配置窗口
wire line2_dmw0_we,line2_dmw1_we;


//读使能
wire line1_crmd_re;
wire line1_prmd_re,line1_euen_re,line1_ecfg_re,line1_estat_re, line1_era_re,line1_badv_re,line1_eentry_re;
//tlb
wire line1_tlbidx_re,line1_tlbehi_re,line1_tlbelo0_re,line1_tlbelo1_re;
//目录
wire line1_asid_re,line1_pgdl_re,line1_pgdh_re,line1_pgd_re;
//处理器编号
wire line1_cpuid_re;
//数据保存
wire line1_save0_re,line1_save1_re,line1_save2_re,line1_save3_re;
//定时
wire line1_tid_re,line1_tcfg_re,line1_tval_re,line1_ticlr_re;
//原子访存
wire line1_llbctl_re;
// 
wire line1_tlbrentry_re;
wire line1_ctag_re;
//直接映射配置窗口
wire line1_dmw0_re,line1_dmw1_re;


//读使能
wire line2_crmd_re;
wire line2_prmd_re,line2_euen_re,line2_ecfg_re,line2_estat_re, line2_era_re,line2_badv_re,line2_eentry_re;
//tlb
wire line2_tlbidx_re,line2_tlbehi_re,line2_tlbelo0_re,line2_tlbelo1_re;
//目录
wire line2_asid_re,line2_pgdl_re,line2_pgdh_re,line2_pgd_re;
//处理器编号
wire line2_cpuid_re;
//数据保存
wire line2_save0_re,line2_save1_re,line2_save2_re,line2_save3_re;
//定时
wire line2_tid_re,line2_tcfg_re,line2_tval_re,line2_ticlr_re;
//原子访存
wire line2_llbctl_re;
// 
wire line2_tlbrentry_re;
wire line2_ctag_re;
//直接映射配置窗口
wire line2_dmw0_re,line2_dmw1_re;



//寄存器
reg [31:0] crmd_reg;
reg [31:0] prmd_reg,euen_reg,ecfg_reg,estat_reg, era_reg,badv_reg,eentry_reg;
//tlb
reg [31:0] tlbidx_reg,tlbehi_reg,tlbelo0_reg,tlbelo1_reg;
//目录
reg [31:0] asid_reg,pgdl_reg,pgdh_reg,pgd_reg;
//处理器编号
reg [31:0] cpuid_reg;
//数据保存
reg [31:0] save0_reg,save1_reg,save2_reg,save3_reg;
//定时
reg [31:0] tid_reg,tcfg_reg,tval_reg,ticlr_reg;
//原子访存
reg [31:0] llbctl_reg;
// 
reg [31:0] tlbrentry_reg;
reg [31:0] ctag_reg;
//直接映射配置窗口
reg [31:0] dmw0_reg,dmw1_reg;

//其他寄存器
reg llbit_reg;
reg excep_en_reg;
reg ertn_en_reg;
reg timer_en;

//硬件中断使能信号
wire hardware_interrupt_en;
wire software_interrupt_en;
wire ti_interrupt_en;
wire pi_interrupt_en;
wire ie;//全局使能为

/****************************************input decode(输入解码)***************************************/
  
  assign {excep_badv_we_i,excep_badv_wdata_i, 
          ertn_en_i,//例外返回                                                
          excep_en_i,excep_ecode_i,excep_esubcode_i,excep_pc_i//例外       
         } = excep_to_ibus;
  
 //csr读
    assign { 
            line2_csr_raddr_i,                    
            line2_llbit_we_i,line2_llbit_wdata_i,//原子指令写
            line2_csr_we_i,line2_csr_waddr_i,line2_csr_wdata_i,
            
            line1_csr_raddr_i,                    
            line1_llbit_we_i,line1_llbit_wdata_i,//原子指令写
            line1_csr_we_i,line1_csr_waddr_i,line1_csr_wdata_i} = wb_to_ibus;
             
/****************************************output code(输出解码)***************************************/
    assign to_wb_obus    = {crmd_reg[`CrmdPlvLocation],line2_csr_rdata_o,crmd_reg[`CrmdPlvLocation],line1_csr_rdata_o};     
    assign to_preif_obus = {excep_en_reg,ertn_en_reg,excep_entry_pc_o,ertn_pc_o };   
    assign to_id_obus    = llbit_reg;
/*******************************complete logical function (逻辑功能实现)*******************************/
//Line1
    assign { line1_crmd_we     ,line1_crmd_re       } = (line1_csr_raddr_i== `CrmdRegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_prmd_we     ,line1_prmd_re       } = (line1_csr_raddr_i== `PrmdRegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_euen_we     ,line1_euen_re       } = (line1_csr_raddr_i== `EuenRegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_ecfg_we     ,line1_ecfg_re       } = (line1_csr_raddr_i== `ECfgRegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_estat_we    ,line1_estat_re      } = (line1_csr_raddr_i== `EStatRegAddr                ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
 
    assign { line1_era_we      ,line1_era_re        } = (line1_csr_raddr_i== `ERARegAddr                  ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_badv_we     ,line1_badv_re       } = (line1_csr_raddr_i== `BAdVRegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_eentry_we   ,line1_eentry_re     } = (line1_csr_raddr_i== `EentryRegAddr               ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
 
    assign { line1_tlbidx_we   ,line1_tlbidx_re     } = (line1_csr_raddr_i== `TlbIdxRegAddr               ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_tlbehi_we   ,line1_tlbehi_re     } = (line1_csr_raddr_i== `TlbEhiRegAddr               ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_tlbelo0_we  ,line1_tlbelo0_re    } = (line1_csr_raddr_i== `TlbElo0RegAddr              ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_tlbelo1_we  ,line1_tlbelo1_re    } = (line1_csr_raddr_i== `TlbElo1RegAddr              ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
  
    assign { line1_asid_we     ,line1_asid_re       } = (line1_csr_raddr_i== `AsIdRegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_pgdl_we     ,line1_pgdl_re       } = (line1_csr_raddr_i== `PgdLRegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_pgdh_we     ,line1_pgdh_re       } = (line1_csr_raddr_i== `PgdHtRegAddr                ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_pgd_we      ,line1_pgd_re        } = (line1_csr_raddr_i== `PgdRegAddr                  ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
   
    assign { line1_cpuid_we    ,line1_cpuid_re      } = (line1_csr_raddr_i== `CpuIdRegAddr                ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
          
    assign { line1_save0_we    ,line1_save0_re      } = (line1_csr_raddr_i== `Save0RegAddr                ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_save1_we    ,line1_save1_re      } = (line1_csr_raddr_i== `Save1RegAddr                ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_save2_we    ,line1_save2_re      } = (line1_csr_raddr_i== `Save2RegAddr                ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_save3_we    ,line1_save3_re      } = (line1_csr_raddr_i== `Save3RegAddr                ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
   
    assign { line1_tid_we      ,line1_tid_re        } = (line1_csr_raddr_i== `TIdRegAddr                  ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_tcfg_we     ,line1_tcfg_re       } = (line1_csr_raddr_i== `TCfgRegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_tval_we     ,line1_tval_re       } = (line1_csr_raddr_i== `TValRegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_ticlr_we    ,line1_ticlr_re      } = (line1_csr_raddr_i== `TiClrRegAddr                ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
        
    assign { line1_llbctl_we   ,line1_llbctl_re     } = (line1_csr_raddr_i== `LlbCtlRegAddr               ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_tlbrentry_we,line1_tlbrentry_re  } = (line1_csr_raddr_i== `TlbRentryRegAddr            ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_ctag_we     ,line1_ctag_re       } = (line1_csr_raddr_i== `CTagRegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_dmw0_we     ,line1_dmw0_re       } = (line1_csr_raddr_i== `DmW0RegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    assign { line1_dmw1_we     ,line1_dmw1_re       } = (line1_csr_raddr_i== `DmW1RegAddr                 ) ? { line1_csr_we_i, 1'b1 }: 2'b0;
    
    
 //Line2
    assign { line2_crmd_we     ,line2_crmd_re       } = (line2_csr_raddr_i== `CrmdRegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_prmd_we     ,line2_prmd_re       } = (line2_csr_raddr_i== `PrmdRegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_euen_we     ,line2_euen_re       } = (line2_csr_raddr_i== `EuenRegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_ecfg_we     ,line2_ecfg_re       } = (line2_csr_raddr_i== `ECfgRegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_estat_we    ,line2_estat_re      } = (line2_csr_raddr_i== `EStatRegAddr                ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
                                                                                                                   
    assign { line2_era_we      ,line2_era_re        } = (line2_csr_raddr_i== `ERARegAddr                  ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_badv_we     ,line2_badv_re       } = (line2_csr_raddr_i== `BAdVRegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_eentry_we   ,line2_eentry_re     } = (line2_csr_raddr_i== `EentryRegAddr               ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
                                                 
    assign { line2_tlbidx_we   ,line2_tlbidx_re     } = (line2_csr_raddr_i== `TlbIdxRegAddr               ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_tlbehi_we   ,line2_tlbehi_re     } = (line2_csr_raddr_i== `TlbEhiRegAddr               ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_tlbelo0_we  ,line2_tlbelo0_re    } = (line2_csr_raddr_i== `TlbElo0RegAddr              ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_tlbelo1_we  ,line2_tlbelo1_re    } = (line2_csr_raddr_i== `TlbElo1RegAddr              ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
                                                                                                                    
    assign { line2_asid_we     ,line2_asid_re       } = (line2_csr_raddr_i== `AsIdRegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_pgdl_we     ,line2_pgdl_re       } = (line2_csr_raddr_i== `PgdLRegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_pgdh_we     ,line2_pgdh_re       } = (line2_csr_raddr_i== `PgdHtRegAddr                ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_pgd_we      ,line2_pgd_re        } = (line2_csr_raddr_i== `PgdRegAddr                  ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
                                                                                                                    
    assign { line2_cpuid_we    ,line2_cpuid_re      } = (line2_csr_raddr_i== `CpuIdRegAddr                ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
                                                                                                                    
    assign { line2_save0_we    ,line2_save0_re      } = (line2_csr_raddr_i== `Save0RegAddr                ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_save1_we    ,line2_save1_re      } = (line2_csr_raddr_i== `Save1RegAddr                ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_save2_we    ,line2_save2_re      } = (line2_csr_raddr_i== `Save2RegAddr                ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_save3_we    ,line2_save3_re      } = (line2_csr_raddr_i== `Save3RegAddr                ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
                                                                                                                    
    assign { line2_tid_we      ,line2_tid_re        } = (line2_csr_raddr_i== `TIdRegAddr                  ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_tcfg_we     ,line2_tcfg_re       } = (line2_csr_raddr_i== `TCfgRegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_tval_we     ,line2_tval_re       } = (line2_csr_raddr_i== `TValRegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_ticlr_we    ,line2_ticlr_re      } = (line2_csr_raddr_i== `TiClrRegAddr                ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
                                                                                                                    
    assign { line2_llbctl_we   ,line2_llbctl_re     } = (line2_csr_raddr_i== `LlbCtlRegAddr               ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_tlbrentry_we,line2_tlbrentry_re  } = (line2_csr_raddr_i== `TlbRentryRegAddr            ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_ctag_we     ,line2_ctag_re       } = (line2_csr_raddr_i== `CTagRegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_dmw0_we     ,line2_dmw0_re       } = (line2_csr_raddr_i== `DmW0RegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    assign { line2_dmw1_we     ,line2_dmw1_re       } = (line2_csr_raddr_i== `DmW1RegAddr                 ) ? { line2_csr_we_i, 1'b1 }: 2'b0;
    
    
    
    
    
 
    
// csr读出数据
   // assign csr_rdata_o = ( (csr_raddr_i == csr_waddr_i) && csr_we_i )? csr_wdata_i : //写优先
    assign line1_csr_rdata_o = 
                         ( {32{     line1_crmd_re        }} &  crmd_reg       |  
                           {32{     line1_prmd_re        }} &  prmd_reg       |
                           {32{     line1_euen_re        }} &  euen_reg       |
                           {32{     line1_ecfg_re        }} &  ecfg_reg       |
                           {32{     line1_estat_re       }} &  estat_reg      |
//                           {32{   line1_                 }} &                |
                           {32{     line1_era_re         }} &  era_reg        |
                           {32{     line1_badv_re        }} &  badv_reg       |
                           {32{     line1_eentry_re      }} &  eentry_reg     |
 //                          {32{   line1_                 }} &                |
                           {32{     line1_tlbidx_re      }} &  tlbidx_reg     |
                           {32{     line1_tlbehi_re      }} &  tlbehi_reg     |
                           {32{     line1_tlbelo0_re     }} &  tlbelo0_reg    |
                           {32{     line1_tlbelo1_re     }} &  tlbelo1_reg    |
//                           {32{   line1_                 }} &                |
                           {32{     line1_asid_re        }} &  asid_reg       |
                           {32{     line1_pgdl_re        }} &  pgdl_reg       |
                           {32{     line1_pgdh_re        }} &  pgdh_reg       |
                           {32{     line1_pgd_re         }} &  pgd_reg        |
//                           {32{   line1_                 }} &                |
                           {32{     line1_cpuid_re       }} &  cpuid_reg      |
//                           {32{   line1_                 }} &                |
                           {32{     line1_save0_re       }} &  save0_reg      |
                           {32{     line1_save1_re       }} &  save1_reg      |
                           {32{     line1_save2_re       }} &  save2_reg      |
                           {32{     line1_save3_re       }} &  save3_reg      |
//                           {32{   line1_    excep_entry_pc_o             }} &                |
                           {32{     line1_tid_re         }} &  tid_reg        |
                           {32{     line1_tcfg_re        }} &  tcfg_reg       |
                           {32{     line1_tval_re        }} &  tval_reg       |
                           {32{     line1_ticlr_re       }} &  ticlr_reg      |
 //                                 line1_
                           {32{     line1_llbctl_re       }} &  llbctl_reg      |
                           {32{     line1_tlbrentry_re   }} &  tlbrentry_reg  |
                           {32{     line1_ctag_re        }} &  ctag_reg       |
                           {32{     line1_dmw0_re        }} &  dmw0_reg       |
                           {32{     line1_dmw1_re        }} &  dmw1_reg       );
                           
assign line2_csr_rdata_o = ( (line2_csr_raddr_i == line1_csr_waddr_i) && line1_csr_we_i )? line1_csr_wdata_i : //写优先
                         ( {32{     line2_crmd_re        }} &  crmd_reg       |  
                           {32{     line2_prmd_re        }} &  prmd_reg       |
                           {32{     line2_euen_re        }} &  euen_reg       |
                           {32{     line2_ecfg_re        }} &  ecfg_reg       |
                           {32{     line2_estat_re       }} &  estat_reg      |
//                           {32{   line2_                 }} &                |
                           {32{     line2_era_re         }} &  era_reg        |
                           {32{     line2_badv_re        }} &  badv_reg       |
                           {32{     line2_eentry_re      }} &  eentry_reg     |
 //                          {32{   line2_                 }} &                |
                           {32{     line2_tlbidx_re      }} &  tlbidx_reg     |
                           {32{     line2_tlbehi_re      }} &  tlbehi_reg     |
                           {32{     line2_tlbelo0_re     }} &  tlbelo0_reg    |
                           {32{     line2_tlbelo1_re     }} &  tlbelo1_reg    |
//                           {32{   line2_                 }} &                |
                           {32{     line2_asid_re        }} &  asid_reg       |
                           {32{     line2_pgdl_re        }} &  pgdl_reg       |
                           {32{     line2_pgdh_re        }} &  pgdh_reg       |
                           {32{     line2_pgd_re         }} &  pgd_reg        |
//                           {32{   line2_                 }} &                |
                           {32{     line2_cpuid_re       }} &  cpuid_reg      |
//                           {32{   line2_                 }} &                |
                           {32{     line2_save0_re       }} &  save0_reg      |
                           {32{     line2_save1_re       }} &  save1_reg      |
                           {32{     line2_save2_re       }} &  save2_reg      |
                           {32{     line2_save3_re       }} &  save3_reg      |
//                           {32{   line2_    excep_entry_pc_o             }} &                |
                           {32{     line2_tid_re         }} &  tid_reg        |
                           {32{     line2_tcfg_re        }} &  tcfg_reg       |
                           {32{     line2_tval_re        }} &  tval_reg       |
                           {32{     line2_ticlr_re       }} &  ticlr_reg      |
 //                                 line2_
                           {32{     line2_llbctl_re       }} &  llbctl_reg      |
                           {32{     line2_tlbrentry_re   }} &  tlbrentry_reg  |
                           {32{     line2_ctag_re        }} &  ctag_reg       |
                           {32{     line2_dmw0_re        }} &  dmw0_reg       |
                           {32{     line2_dmw1_re        }} &  dmw1_reg       );
                                                        
  
  
  
  //例外
  assign excep_entry_pc_o      = eentry_reg;
  assign ertn_pc_o             = era_reg;
  assign ie = crmd_reg[`CrmdIeLocation];
  assign hardware_interrupt_en = (estat_reg[`EstatIsHwiLocation] & ecfg_reg[`EstatIsHwiLocation])!= 8'h0 ? 1'b1 :1'b0;
  assign software_interrupt_en = (estat_reg[`EstatIsSwiLocation] & ecfg_reg[`EstatIsSwiLocation])  != 2'h0 ? 1'b1 :1'b0;
  assign ti_interrupt_en       = estat_reg[`EstatIsTiLocation]&ecfg_reg[`EstatIsTiLocation];
  assign pi_interrupt_en       = estat_reg[`EstatIsIpiLocation]&ecfg_reg[`EstatIsIpiLocation];
  
  assign interrupt_en_o        = (hardware_interrupt_en|software_interrupt_en | ti_interrupt_en | pi_interrupt_en ) & ie;
  
  
 /*******************************complete logical function (寄存器堆)*******************************/  
  
  always@(posedge clk)begin
    if(rst_n == `RstEnable)begin
        llbit_reg <= 1'b1;
    end else if (ertn_en_i && !llbctl_reg[`LlbctlKloLocation])begin//例外返回处理
        llbit_reg <= 1'b0; 
    end else if(line2_llbit_we_i)begin
        llbit_reg <= line2_llbit_wdata_i;
    end else if(line1_llbit_we_i)begin
        llbit_reg <= line1_llbit_wdata_i;
    end else begin
        llbit_reg <= llbit_reg;
    end
 end
 //例外跳转使能
 always@(posedge clk)begin
    if(rst_n == `RstEnable)begin   
       excep_en_reg <= 1'b0;
    end else begin
       excep_en_reg <= excep_en_i;
    end
 end
  //例外跳转使能
 always@(posedge clk)begin
    if(rst_n == `RstEnable)begin   
       ertn_en_reg <= 1'b0;
    end else begin
       ertn_en_reg <= ertn_en_i;
    end
 end
                         
                         
 /*******************************complete logical function (寄存器堆)*******************************/ 
 //CRMD当前模式信息寄存器
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        crmd_reg[`CrmdPlvLocation]  <=   2'b00;
        crmd_reg[`CrmdIeLocation]   <=   1'b0 ;
        crmd_reg[`CrmdDaLocation]   <=   1'b1 ;
        crmd_reg[`CrmdPgLocation]   <=   1'b0 ;
        crmd_reg[`CrmdDatfLocation] <=   2'b00;
        crmd_reg[`CrmdDatmLocation] <=   2'b00;
        crmd_reg[31:9] <= 23'd0;
    end else if(excep_en_i)begin//例外处理，例外指令不允许修改csr，所以优先判断例外
        crmd_reg[`CrmdPlvLocation] <=  2'b00;
        crmd_reg[`CrmdIeLocation]  <=  1'b0 ;//处理例外的时候不发出中断信号
    end else if(ertn_en_i)begin//例外返回处理
        crmd_reg[`CrmdPlvLocation] <= prmd_reg[`PrmdPllvLocation] ;
        crmd_reg[`CrmdIeLocation]  <= prmd_reg[`PrmdPieLocation] ;
    end else if(line2_crmd_we) begin
        crmd_reg <= line2_csr_wdata_i;
    end else if(line1_crmd_we) begin
        crmd_reg <= line1_csr_wdata_i;
    end else begin
        crmd_reg <=crmd_reg;
    end
 end
 
  //例外当期模式信息
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        prmd_reg <=`ZeroWord32B;
    end else if(excep_en_i)begin//例外处理，例外指令不允许修改csr，所以优先判断例外
        //prmd_reg[`PrmdPllvLocation] <= crmd_reg[`CrmdPlvLocation];
        //prmd_reg[`PrmdPieLocation]  <= crmd_reg[`CrmdIeLocation];
        prmd_reg[1:0] <= crmd_reg[1:0];
        prmd_reg[2]  <= crmd_reg[2];
    end else if(line2_prmd_we) begin
        prmd_reg <= line2_csr_wdata_i;
     end else if(line1_prmd_we) begin
        prmd_reg <= line1_csr_wdata_i;
    end else begin
        prmd_reg <=prmd_reg;
    end
 end
 
  //EUEN扩展部件使能
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        euen_reg <= `ZeroWord32B;
    end else if(line2_euen_we) begin
        euen_reg <= line2_csr_wdata_i;
    end else if(line1_euen_we) begin
        euen_reg <= line1_csr_wdata_i;
    end else begin
        euen_reg <= euen_reg;
    end
 end
  //ECFG例外扩展
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        ecfg_reg <=`ZeroWord32B;
    end else if(line2_ecfg_we) begin
        ecfg_reg <= line2_csr_wdata_i;
    end else if(line1_ecfg_we) begin
        ecfg_reg <= line1_csr_wdata_i;
    end else begin
        ecfg_reg <= ecfg_reg;
    end
 end
 
//ESTAT例外状态
//最开始没有拆分成多个if语句的，结果发现不同字段要在不同条件下赋值，在不拆分就要出现多驱动了
 always @(posedge clk)begin
    //软件中断
    if(rst_n == `RstEnable)begin
         estat_reg[`EstatIsSwiLocation] <=2'b00;
    end else if(line2_estat_we) begin
        estat_reg[`EstatIsSwiLocation] <= line2_csr_wdata_i[`EstatIsSwiLocation];
    end else if(line1_estat_we) begin
        estat_reg[`EstatIsSwiLocation] <= line1_csr_wdata_i[`EstatIsSwiLocation];
    end else begin
        estat_reg[`EstatIsSwiLocation] <= estat_reg[`EstatIsSwiLocation];
    end
    
//    //硬件中断位，样例版本
//    if(rst_n == `RstEnable)begin
//         estat_reg[`EstatIsHwiLocation] <=8'd0;
//    end else begin
//        estat_reg[`EstatIsHwiLocation] <= hardware_interrupt_data_i;
//    end
    //硬件中断位，郑忠强通过毕设版本,只有中断信号有效的时候才采样外部中断源
    if(rst_n == `RstEnable)begin
         estat_reg[`EstatIsHwiLocation] <=8'd0;
    end else if (crmd_reg[`CrmdIeLocation]) begin
         estat_reg[`EstatIsHwiLocation] <= hardware_interrupt_data_i;
    end else begin
        estat_reg[`EstatIsHwiLocation] <= estat_reg[`EstatIsHwiLocation];
    end
    
    //单独设置ti字段
    if(rst_n == `RstEnable)begin
        estat_reg[`EstatIsTiLocation] <= 1'b0;
    end else if(line2_ticlr_we & line2_csr_wdata_i[0])begin//如果tictl && csr_wdata_i[0]==1 then 要清空定时中断
        estat_reg[`EstatIsTiLocation] <= 1'b0;
    end else if(line1_ticlr_we & line1_csr_wdata_i[0])begin//如果tictl && csr_wdata_i[0]==1 then 要清空定时中断
        estat_reg[`EstatIsTiLocation] <= 1'b0;
    end else if(tcfg_reg[`TcfgEnLocation] == 1'b1 && tval_reg[`TvalTimeValLocation] == `TimeValLen'd0)begin//tctl=1&&计数器值==0则发起定时中断
        estat_reg[`EstatIsTiLocation] <= 1'b1;
    end
    
    //核间中断
    if(rst_n == `RstEnable)begin
        estat_reg[`EstatIsIpiLocation] <= 1'b0;
    end else begin
        estat_reg[`EstatIsIpiLocation] <= estat_reg[`EstatIsIpiLocation];
    end
    
    
    //例外序号设置
    if(rst_n == `RstEnable)begin
         estat_reg [`EstatEcodeLocation]    <= `EcodeLen'd0;   
        estat_reg [`EstatEsubCodeLocation] <= `EsubCodeLen'd0;
    end else if(excep_en_i)begin//例外处理，例外指令不允许修改csr，所以优先判断例外
        estat_reg [`EstatEcodeLocation]    <= excep_ecode_i;   
        estat_reg [`EstatEsubCodeLocation] <= excep_esubcode_i;
    end else begin
        estat_reg [`EstatEcodeLocation]    <= estat_reg [`EstatEcodeLocation];   
        estat_reg [`EstatEsubCodeLocation] <= estat_reg [`EstatEsubCodeLocation];
    end
    
    //保留位
    if(rst_n == `RstEnable)begin
        estat_reg[10] <= 1'b0;
        estat_reg[15:13] <= 3'd0;
        estat_reg[31] <=1'd0;
    end else begin
        estat_reg[10]    <= estat_reg[10];    
        estat_reg[15:13] <= estat_reg[15:13]; 
        estat_reg[31]    <= estat_reg[31];     
    end
    
    
 end
 
  //Era例外返回地址
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        era_reg <=`ZeroWord32B;
    end else if(excep_en_i)begin//例外处理，例外指令不允许修改csr，所以优先判断例外
        era_reg <= excep_pc_i;
    end else if(line2_era_we) begin
        era_reg <= line2_csr_wdata_i;
    end else if(line1_era_we) begin
        era_reg <= line1_csr_wdata_i;
    end else begin
        era_reg <= era_reg;
    end
 end
  //BADV出错虚拟地址
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        badv_reg <=`ZeroWord32B;
    end else if(excep_badv_we_i)begin //地址例外的硬件实现的东西
        badv_reg <= excep_badv_wdata_i;
    end else if(line2_badv_we) begin
        badv_reg <= line2_csr_wdata_i;
    end else if(line1_badv_we) begin
        badv_reg <= line1_csr_wdata_i;
    end else begin
        badv_reg <= badv_reg;
    end
 end 
 //eentry例外入口地址
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        eentry_reg <=`ZeroWord32B;
    end else if(line2_eentry_we) begin
        eentry_reg <= line2_csr_wdata_i;
    end else if(line1_eentry_we) begin
        eentry_reg <= line1_csr_wdata_i;
    end else begin
        eentry_reg <= eentry_reg;
    end
 end
  //TLBIDX TLB索引
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        tlbidx_reg <=`ZeroWord32B;
    end else if(line2_tlbidx_we) begin
        tlbidx_reg <= line2_csr_wdata_i;
    end else if(line1_tlbidx_we) begin
        tlbidx_reg <= line1_csr_wdata_i;
    end else begin
        tlbidx_reg <= tlbidx_reg;
    end
 end
  //TLBEHI TLB表项高位
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        tlbehi_reg <=`ZeroWord32B;
    end else if(line2_tlbehi_we) begin
        tlbehi_reg <= line2_csr_wdata_i;
     end else if(line1_tlbehi_we) begin
        tlbehi_reg <= line1_csr_wdata_i;
    end else begin
        tlbehi_reg <=tlbehi_reg;
    end
 end 
 //TLBELO0 TLB表项低位0
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        tlbelo0_reg <=`ZeroWord32B;
    end else if(line2_tlbelo0_we) begin
        tlbelo0_reg <= line2_csr_wdata_i;
    end else if(line1_tlbelo0_we) begin
        tlbelo0_reg <= line1_csr_wdata_i;
    end else begin
        tlbelo0_reg <= tlbelo0_reg;
    end
 end 
 //TLBELo1 TLB表项低位1
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        tlbelo1_reg <=`ZeroWord32B;
    end else if(line2_tlbelo1_we) begin
        tlbelo1_reg <= line2_csr_wdata_i;
     end else if(line1_tlbelo1_we) begin
        tlbelo1_reg <= line1_csr_wdata_i;
    end else begin
        tlbelo1_reg <=tlbelo1_reg;
    end
 end 
 //ASID 地址空间标识符
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        asid_reg <=`ZeroWord32B;
    end else if(line2_asid_we) begin
        asid_reg <= line2_csr_wdata_i;
    end else if(line1_asid_we) begin
        asid_reg <= line1_csr_wdata_i;
    end else begin
        asid_reg <= asid_reg;
    end
 end 
 //PGDL 低半地址空间全局目录基地址
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        pgdl_reg <=`ZeroWord32B;
    end else if(line2_pgdl_we) begin
        pgdl_reg <= line2_csr_wdata_i;
    end else if(line1_pgdl_we) begin
        pgdl_reg <= line1_csr_wdata_i;
    end else begin
        pgdl_reg <=pgdl_reg;
    end
 end 
 //PGDH 高半地址空间全局目录基地址
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        pgdh_reg <=`ZeroWord32B;
    end else if(line2_pgdh_we) begin
        pgdh_reg <= line2_csr_wdata_i;
     end else if(line1_pgdh_we) begin
        pgdh_reg <= line1_csr_wdata_i;
    end else begin
        pgdh_reg <=pgdh_reg;
    end
 end 
 //PGD 全局目录地址
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        pgd_reg <=`ZeroWord32B;
    end else if(line2_pgd_we) begin
        pgd_reg <= line2_csr_wdata_i;
    end else if(line1_pgd_we) begin
        pgd_reg <= line1_csr_wdata_i;
    end else begin
        pgd_reg <=pgd_reg;
    end
 end 
 //CPUID 处理器编号
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        cpuid_reg <=`ZeroWord32B;
    end else if(line2_cpuid_we) begin
        cpuid_reg <= line2_csr_wdata_i;
    end else if(line1_cpuid_we) begin
        cpuid_reg <= line1_csr_wdata_i;
    end else begin
        cpuid_reg <=cpuid_reg;
    end
 end 
 //SAVE0 数据保存寄存器0
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        save0_reg <=`ZeroWord32B;
    end else if(line2_save0_we) begin
        save0_reg <= line2_csr_wdata_i;
    end else if(line1_save0_we) begin
        save0_reg <= line1_csr_wdata_i;
    end else begin
        save0_reg <=save0_reg;
    end
 end 
 //Save1 数据寄存器1
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        save1_reg <=`ZeroWord32B;
    end else if(line2_save1_we) begin
        save1_reg <= line2_csr_wdata_i;
    end else if(line1_save1_we) begin
        save1_reg <= line1_csr_wdata_i;
    end else begin
        save1_reg <= save1_reg;
    end
 end 
 //Save2 数据保存寄存器2
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        save2_reg <=`ZeroWord32B;
    end else if(line2_save2_we) begin
        save2_reg <= line2_csr_wdata_i;
    end else if(line1_save2_we) begin
        save2_reg <= line1_csr_wdata_i;
    end else begin
        save2_reg <= save2_reg;
    end
 end 
 //save3 数据保存寄存器3
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        save3_reg <=`ZeroWord32B;
    end else if(line2_save3_we) begin
        save3_reg <= line2_csr_wdata_i;
    end else if(line1_save3_we) begin
        save3_reg <= line1_csr_wdata_i;
    end else begin
        save3_reg <= save3_reg;
    end
 end 
 //TID 定时器编号
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        tid_reg <=`ZeroWord32B;
    end else if(line2_tid_we) begin
        tid_reg <= line2_csr_wdata_i;
    end else if(line1_tid_we) begin
        tid_reg <= line1_csr_wdata_i;
    end else begin
        tid_reg <=tid_reg;
    end
 end 
 
 //TCFg 定时器配置
 //我将n设置为32,所以没有保留字段全字段有csr_rwc指令决定
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        tcfg_reg <=`ZeroWord32B;
    end else if(line2_tcfg_we) begin
        tcfg_reg <= line2_csr_wdata_i;
    end else if(line1_tcfg_we) begin
        tcfg_reg <= line1_csr_wdata_i;
    end else begin
        tcfg_reg <= tcfg_reg;
    end
 end 
 
 //Tval 定时器值
 //不允许写，值由硬件控制
 //不断自动减在什么时候：val!=1,且tctl.en=1
 //初始赋值是什么时候，tctl,每次写入en=1的时候
 //循环计数是什么是：tctl.pre=1且val=0
 //当前周期csr_wc直接写入tval的初始值，一个时钟周期开始-1，
 always @(posedge clk)begin//计数使能信号
    if(rst_n == `RstEnable)begin
        timer_en <= 1'b0;
    end else if (line2_tcfg_we )begin//if tcfg.en=1则timer_en=1
        timer_en <= line2_csr_wdata_i[0];
    end else if (line1_tcfg_we )begin//if tcfg.en=1则timer_en=1
        timer_en <= line1_csr_wdata_i[0];
    end else if( timer_en && tval_reg[`TvalTimeValLocation]== `TimeValLen'd0 )begin//计数结束且不重装的时候，设置计数使能=0
        timer_en <= tcfg_reg[`TcfgPeriodicLocation];
    end
        
 end
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        tval_reg <=`ZeroWord32B;
    end else if( line2_tcfg_we && line2_csr_wdata_i[0]==1'b1) begin//当ctf中en使能的时候设置定时器的初始值，但是样例代码不考虑tcfg.en是否将要写入1，就把tval_reg的初始值改了，不够应该没有影响，
        tval_reg[`TvalTimeValLocation] <= {line2_csr_wdata_i[`TcfgInitValLocation],2'b00};
    end else if( line1_tcfg_we && line1_csr_wdata_i[0]==1'b1) begin//当ctf中en使能的时候设置定时器的初始值，但是样例代码不考虑tcfg.en是否将要写入1，就把tval_reg的初始值改了，不够应该没有影响，
        tval_reg[`TvalTimeValLocation] <= {line1_csr_wdata_i[`TcfgInitValLocation],2'b00};
    end else if( timer_en )begin//如果当前值==0
        if(tval_reg[`TvalTimeValLocation] != `TimeValLen'd0) begin //如果ctf.en有效且当前计数器的值！=0则不断-1
            tval_reg[`TvalTimeValLocation] <= tval_reg[`TvalTimeValLocation] -`TimeValLen'd1;
        //end else if(tcfg_reg[`TvalTimeValLocation] == `TimeValLen'd0) begin
        end else begin
            tval_reg[`TvalTimeValLocation] <= tcfg_reg[`TcfgPeriodicLocation] ? {tcfg_reg[`TcfgInitValLocation],2'b00} : `TimeValLen'hffff_ffff;//保持值原值
        end
    end else begin
        tval_reg[`TvalTimeValLocation] <= tval_reg[`TvalTimeValLocation];
    end
    
 end 
 
 //TIclr 定时中断清除
 //该寄存器恒读出0，如果要对它进行写，也不需要执行，只需要把写使能要实现的功能实现即可
 //出现写使能就清空estat中定时中断的中断信号，样例代码也是如此的，那这样计数周期数是完全一致的了
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        ticlr_reg <=`ZeroWord32B;
    end
 end 
 //LLibt寄存器
always @(posedge clk)begin
    if(rst_n ==`RstEnable)begin
        llbctl_reg <= `ZeroWord32B;
    end else if(ertn_en_i)begin //例外返回处理
        llbctl_reg [`LlbctlKloLocation] <= 1'b0;
    end else if(line2_llbctl_we) begin
        llbctl_reg <= line2_csr_wdata_i;
    end else if(line1_llbctl_we) begin
        llbctl_reg <= line1_csr_wdata_i;
    end else begin
        llbctl_reg <= llbctl_reg;
    end
end
 //TLB充填例外入口地址
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        tlbrentry_reg <=`ZeroWord32B;
    end else if(line2_tlbrentry_we) begin
        tlbrentry_reg <= line2_csr_wdata_i;
    end else if(line1_tlbrentry_we) begin
        tlbrentry_reg <= line1_csr_wdata_i;
    end else begin
        tlbrentry_reg <=tlbrentry_reg;
    end
 end 
 //Ctag 高速缓冲标签
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        ctag_reg <=`ZeroWord32B;
    end else if(line2_ctag_we) begin
        ctag_reg <= line2_csr_wdata_i;
    end else if(line1_ctag_we) begin
        ctag_reg <= line1_csr_wdata_i;
    end else begin
        ctag_reg <= ctag_reg;
    end
 end 
 // DMW0 直接映射配置窗口
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        dmw0_reg <=`ZeroWord32B;
    end else if(line2_dmw0_we) begin
        dmw0_reg <= line2_csr_wdata_i;
    end else if(line1_dmw0_we) begin
        dmw0_reg <= line1_csr_wdata_i;
    end else begin
        dmw0_reg <= dmw0_reg;
    end
 end 
 //DMW1 直接映射窗口1
 always @(posedge clk)begin
    if(rst_n == `RstEnable)begin
        dmw1_reg <=`ZeroWord32B;
    end else if(line2_dmw1_we) begin
        dmw1_reg <= line2_csr_wdata_i;
    end else if(line1_dmw1_we) begin
        dmw1_reg <= line1_csr_wdata_i;
    end else begin
        dmw1_reg <=dmw1_reg;
    end
 end 
 
 
 

endmodule
