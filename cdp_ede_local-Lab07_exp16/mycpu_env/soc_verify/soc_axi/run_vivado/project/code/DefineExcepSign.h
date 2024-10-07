/*
 * DefineExcepSign.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */

`include "DefineLoogLenWidth.h"
`ifndef DEFINEEXCEPSIGN_H
`define DEFINEEXCEPSIGN_H


//控制信号
              `define             NopInstExcepSign            `ExcepSignLen'h0
 //Op6指
     //跳转指
       //无条件跳
              `define             BInstExcepSign              `ExcepSignLen'h0
              `define             BlInstExcepSign             `ExcepSignLen'h0
              `define             JirlInstExcepSign           `ExcepSignLen'h0
       //条件跳
              `define             BeqInstExcepSign            `ExcepSignLen'h0  
              `define             BneInstExcepSign            `ExcepSignLen'h0
              `define             BltInstExcepSign            `ExcepSignLen'h0
              `define             BgeInstExcepSign            `ExcepSignLen'h0
              `define             BltuInstExcepSign           `ExcepSignLen'h0
              `define             BgeuInstExcepSign           `ExcepSignLen'h0
 //op7指
     //立即数转载指
              `define             Lu12iwInstExcepSign         `ExcepSignLen'h0
     //pc相对计算指
              `define             PcaddiInstExcepSign         `ExcepSignLen'h0 //基础指令集不存在
              `define             Pcaddu12iInstExcepSign      `ExcepSignLen'h0
 //OP8指
     //原子访存指
              `define             LlwInstExcepSign            `ExcepSignLen'h0
              `define             ScwInstExcepSign            `ExcepSignLen'h1
 //Op10指
     //比较指
              `define             SltiInstExcepSign           `ExcepSignLen'h0
              `define             SltuiInstExcepSign          `ExcepSignLen'h0
    //简单运算指
              `define             AddiwInstExcepSign          `ExcepSignLen'h0
    //逻辑运算指
              `define             AndiInstExcepSign           `ExcepSignLen'h0
              `define             OriInstExcepSign            `ExcepSignLen'h0
              `define             XoriInstExcepSign           `ExcepSignLen'h0
       //访存指
        //加载指
              `define             LdbInstExcepSign            `ExcepSignLen'h0
              `define             LdhInstExcepSign            `ExcepSignLen'h0
              `define             LdwInstExcepSign            `ExcepSignLen'h0
         //存储指
             `define              StbInstExcepSign            `ExcepSignLen'h0
             `define              SthInstExcepSign            `ExcepSignLen'h0
             `define              StwInstExcepSign            `ExcepSignLen'h0
        //0扩展加载指
             `define              LdbuInstExcepSign           `ExcepSignLen'h0
             `define              LdhuInstExcepSign           `ExcepSignLen'h0
        //cache预取指
             `define              PreldInstExcepSign          `ExcepSignLen'h0
 //op17指
     //简单算术指
             `define              AddwInstExcepSign           `ExcepSignLen'h0
             `define              SubwInstExcepSign           `ExcepSignLen'h0
     //比较指令                                                          000
             `define              SltInstExcepSign            `ExcepSignLen'h0
             `define              SltuInstExcepSign           `ExcepSignLen'h0
     //逻辑运算                                            000 
             `define              AndInstExcepSign            `ExcepSignLen'h0
             `define              OrInstExcepSign             `ExcepSignLen'h0
             `define              XorInstExcepSign            `ExcepSignLen'h0
             `define              NorInstExcepSign            `ExcepSignLen'h0
             `define              NandInstExcepSign           `ExcepSignLen'h0//基础指令集不存在的指令
     //移位指令                                                          000
             `define              SllwInstExcepSign           `ExcepSignLen'h0
             `define              SrlwInstExcepSign           `ExcepSignLen'h0
             `define              SrawInstExcepSign           `ExcepSignLen'h0
     //复杂运算指
     //乘法指
             `define              MulwInstExcepSign           `ExcepSignLen'h0
             `define              MulhwInstExcepSign          `ExcepSignLen'h0
             `define              MulhwuInstExcepSign         `ExcepSignLen'h0
        //除法指令                                                       000
             `define              DivwInstExcepSign           `ExcepSignLen'h0
             `define              ModwInstExcepSign           `ExcepSignLen'h0
             `define              DivwuInstExcepSign          `ExcepSignLen'h0
             `define              ModwuInstExcepSign          `ExcepSignLen'h0
       //杂项指令                                                        000
             `define              BreakInstExcepSign          `ExcepSignLen'h1
             `define              SyscallInstExcepSign        `ExcepSignLen'h2
      //移位
             `define              SlliwInstExcepSign          `ExcepSignLen'h0
             `define              SrliwInstExcepSign          `ExcepSignLen'h0
             `define              SraiwInstExcepSign          `ExcepSignLen'h0
     //栅障
             `define              DbarInstExcepSign           `ExcepSignLen'h0
             `define              IbarInstExcepSign           `ExcepSignLen'h0
 //op2
     //时间预取指
            `define               RdcntidwInstExcepSign       `ExcepSignLen'h0
            `define               RdcntvlwInstExcepSign       `ExcepSignLen'h0
            `define               RdcntvhwInstExcepSign       `ExcepSignLen'h0
//核心态指
    //csr访问指
           `define                CsrrdInstExcepSign          `ExcepSignLen'h8
           `define                CsrwrInstExcepSign          `ExcepSignLen'h8
           `define                CsrxchgInstExcepSign        `ExcepSignLen'h8          
    //cache维护指令                                                    
           `define                CacopInstExcepSign          `ExcepSignLen'h8
     //Tlb维护指令                                         000
           `define                TlbsrchInstExcepSign        `ExcepSignLen'h8
           `define                TlbrdInstExcepSign          `ExcepSignLen'h8
           `define                TlbwrInstExcepSign          `ExcepSignLen'h8
           `define                TlbfillInstExcepSign        `ExcepSignLen'h8
           `define                InvtlbInstExcepSign         `ExcepSignLen'h8
    //其他指令                                                            000
           `define                IdleInstExcepSign           `ExcepSignLen'hc
           `define                ErtnInstExcepSign           `ExcepSignLen'hb
           `define                NoExistExcepSign            `ExcepSignLen'h5






`endif /* !DEFINEEXCEPSIGN_H */
