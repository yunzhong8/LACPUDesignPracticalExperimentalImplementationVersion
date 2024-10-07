/*
 * DefineIdSign.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */
`include "DefineLoogLenWidth.h"

`ifndef DEFINEIDSIGN_H
`define DEFINEIDSIGN_H

//控制信号
              `define             NopInstIdSign            `IdSignLen'h0000
 //Op6指令
     //跳转指令
       //无条件跳转
              `define             BInstIdSign              `IdSignLen'h0000
              `define             BlInstIdSign             `IdSignLen'h0360
              `define             JirlInstIdSign           `IdSignLen'h0261
       //条件跳转
              `define             BeqInstIdSign            `IdSignLen'h0005  
              `define             BneInstIdSign            `IdSignLen'h0005
              `define             BltInstIdSign            `IdSignLen'h0005
              `define             BgeInstIdSign            `IdSignLen'h0005
              `define             BltuInstIdSign           `IdSignLen'h0005
              `define             BgeuInstIdSign           `IdSignLen'h0005
 //op7指令
     //立即数转载指令
              `define             Lu12iwInstIdSign         `IdSignLen'h0000
     //pc相对计算指令
              `define             PcaddiInstIdSign         `IdSignLen'h0000 //基础指令集不存在
              `define             Pcaddu12iInstIdSign      `IdSignLen'h0038
 //OP8指令
     //原子访存指令
              `define             LlwInstIdSign            `IdSignLen'h1051
              `define             ScwInstIdSign            `IdSignLen'h0051
 //Op10指令
     //比较指令
              `define             SltiInstIdSign           `IdSignLen'h0021
              `define             SltuiInstIdSign          `IdSignLen'h0021
    //简单运算指令
              `define             AddiwInstIdSign          `IdSignLen'h0021
    //逻辑运算指令
              `define             AndiInstIdSign           `IdSignLen'h0011
              `define             OriInstIdSign            `IdSignLen'h0011
              `define             XoriInstIdSign           `IdSignLen'h0011
       //访存指令
        //加载指令
              `define             LdbInstIdSign            `IdSignLen'h0021
              `define             LdhInstIdSign            `IdSignLen'h0021
              `define             LdwInstIdSign            `IdSignLen'h0021
         //存储指令
             `define              StbInstIdSign            `IdSignLen'h0025
             `define              SthInstIdSign            `IdSignLen'h0025
             `define              StwInstIdSign            `IdSignLen'h0025
        //0扩展加载指令
             `define              LdbuInstIdSign           `IdSignLen'h0021
             `define              LdhuInstIdSign           `IdSignLen'h0021
        //cache预取指令
             `define              PreldInstIdSign          `IdSignLen'h0000
 //op17指令
     //简单算术指令
             `define              AddwInstIdSign           `IdSignLen'h0003
             `define              SubwInstIdSign           `IdSignLen'h0003
     //比较指令                                                          0000
             `define              SltInstIdSign            `IdSignLen'h0003
             `define              SltuInstIdSign           `IdSignLen'h0003
     //逻辑运算                                            000 0
             `define              AndInstIdSign            `IdSignLen'h0003
             `define              OrInstIdSign             `IdSignLen'h0003
             `define              XorInstIdSign            `IdSignLen'h0003
             `define              NorInstIdSign            `IdSignLen'h0003
             `define              NandInstIdSign           `IdSignLen'h0003//基础指令集不存在的指令
     //移位指令                                                          0000
             `define              SllwInstIdSign           `IdSignLen'h0003
             `define              SrlwInstIdSign           `IdSignLen'h0003
             `define              SrawInstIdSign           `IdSignLen'h0003
     //复杂运算指令
     //乘法指令
             `define              MulwInstIdSign           `IdSignLen'h0003
             `define              MulhwInstIdSign          `IdSignLen'h0003
             `define              MulhwuInstIdSign         `IdSignLen'h0003
        //除法指令                                                       0000
             `define              DivwInstIdSign           `IdSignLen'h0003
             `define              ModwInstIdSign           `IdSignLen'h0003
             `define              DivwuInstIdSign          `IdSignLen'h0003
             `define              ModwuInstIdSign          `IdSignLen'h0003
       //杂项指令                                                        0000
             `define              SyscallInstIdSign        `IdSignLen'h0000
             `define              BreakInstIdSign          `IdSignLen'h0000
      //移位指
             `define              SlliwInstIdSign          `IdSignLen'h0041
             `define              SrliwInstIdSign          `IdSignLen'h0041
             `define              SraiwInstIdSign          `IdSignLen'h0041
     //栅障指
             `define              DbarInstIdSign           `IdSignLen'h0000
             `define              IbarInstIdSign           `IdSignLen'h0000
 //op22
     //时间预取指令
            `define               RdcntidwInstIdSign       `IdSignLen'h0880
            `define               RdcntvlwInstIdSign       `IdSignLen'h0400
            `define               RdcntvhwInstIdSign       `IdSignLen'h0600
//核心态指令
    //csr访问指令
           `define                CsrrdInstIdSign          `IdSignLen'h4A00
           `define                CsrwrInstIdSign          `IdSignLen'h4A04
           `define                CsrxchgInstIdSign        `IdSignLen'h6A05         
    //cache维护指令                                                     
           `define                CacopInstIdSign          `IdSignLen'h0000
     //Tlb维护指令                                         000 
           `define                TlbsrchInstIdSign        `IdSignLen'h0000
           `define                TlbrdInstIdSign          `IdSignLen'h0000
           `define                TlbwrInstIdSign          `IdSignLen'h0000
           `define                TlbfillInstIdSign        `IdSignLen'h0000
           `define                InvtlbInstIdSign         `IdSignLen'h0000
    //其他指令                                                            0000
           `define                IdleInstIdSign           `IdSignLen'h0000
           `define                ErtnInstIdSign           `IdSignLen'h0000
           `define                NoExistIdSign            `IdSignLen'h0000
           





`endif /* !DEFINEIDSIGN_H */
