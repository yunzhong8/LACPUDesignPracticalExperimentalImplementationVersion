/*
 * DefineExSign.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */
`include "DefineLoogLenWidth.h"
`ifndef DEFINEEXSIGN_H
`define DEFINEEXSIGN_H

//控制信号
              `define                   NopInstExSign              `ExSignLen'h0
 //Op6指令
     //跳转指令
       //无条件跳转
              `define                   BInstExSign                `ExSignLen'h0
              `define                   BlInstExSign               `ExSignLen'h0
              `define                   JirlInstExSign             `ExSignLen'h0
       //条件跳转
              `define                   BeqInstExSign              `ExSignLen'h0 
              `define                   BneInstExSign              `ExSignLen'h0
              `define                   BltInstExSign              `ExSignLen'h0
              `define                   BgeInstExSign              `ExSignLen'h0
              `define                   BltuInstExSign             `ExSignLen'h0
              `define                   BgeuInstExSign             `ExSignLen'h0
 //op7指令
     //立即数转载指令
              `define                   Lu12iwInstExSign           `ExSignLen'h0
     //pc相对计算指令
              `define                   PcaddiInstExSign           `ExSignLen'h0 //基础指令集不存在
              `define                   Pcaddu12iInstExSign        `ExSignLen'h1
 //OP8指令
     //原子访存指令
              `define                   LlwInstExSign              `ExSignLen'h0
              `define                   ScwInstExSign              `ExSignLen'h0
 //Op10指令
     //比较指令
              `define                   SltiInstExSign             `ExSignLen'h1
              `define                   SltuiInstExSign            `ExSignLen'h1
    //简单运算指令
              `define                   AddiwInstExSign            `ExSignLen'h1
    //逻辑运算指令
              `define                   AndiInstExSign             `ExSignLen'h1
              `define                   OriInstExSign              `ExSignLen'h1
              `define                   XoriInstExSign             `ExSignLen'h1
       //访存指令
        //加载指令
              `define                   LdbInstExSign              `ExSignLen'h0
              `define                   LdhInstExSign              `ExSignLen'h0
              `define                   LdwInstExSign              `ExSignLen'h0
         //存储指令
              `define                   StbInstExSign              `ExSignLen'h0
              `define                   SthInstExSign              `ExSignLen'h0
              `define                   StwInstExSign              `ExSignLen'h0
        //0扩展加载指令
              `define                   LdbuInstExSign             `ExSignLen'h0
              `define                   LdhuInstExSign             `ExSignLen'h0
        //cache预取指令
              `define                   PreldInstExSign            `ExSignLen'h0
 //op17指令
     //简单算术指令
              `define                   AddwInstExSign             `ExSignLen'h1
              `define                   SubwInstExSign             `ExSignLen'h1
     //比较指令
              `define                   SltInstExSign              `ExSignLen'h1
              `define                   SltuInstExSign             `ExSignLen'h1
     //逻辑运算
              `define                   AndInstExSign              `ExSignLen'h1
              `define                   OrInstExSign               `ExSignLen'h1
              `define                   XorInstExSign              `ExSignLen'h1
              `define                   NorInstExSign              `ExSignLen'h1
              `define                   NandInstExSign             `ExSignLen'h0//基础指令集不存在的指令
     //移位指令
              `define                   SllwInstExSign             `ExSignLen'h1
              `define                   SrlwInstExSign             `ExSignLen'h1
              `define                   SrawInstExSign             `ExSignLen'h1
     //复杂运算指令
     //乘法指令
              `define                   MulwInstExSign             `ExSignLen'h1
              `define                   MulhwInstExSign            `ExSignLen'h2
              `define                   MulhwuInstExSign           `ExSignLen'h2
        //除法指令
              `define                   DivwInstExSign             `ExSignLen'h2
              `define                   ModwInstExSign             `ExSignLen'h1
              `define                   DivwuInstExSign            `ExSignLen'h2
              `define                   ModwuInstExSign            `ExSignLen'h1
       //杂项指令
              `define                   SyscallInstExSign          `ExSignLen'h0
              `define                   BreakInstExSign            `ExSignLen'h0
      //移位指令
              `define                   SlliwInstExSign            `ExSignLen'h1
              `define                   SrliwInstExSign            `ExSignLen'h1
              `define                   SraiwInstExSign            `ExSignLen'h1
     //栅障指令
              `define                   DbarInstExSign             `ExSignLen'h0
              `define                   IbarInstExSign             `ExSignLen'h0
 //op22
     //时间预取指令
              `define                   RdcntidwInstExSign         `ExSignLen'h0
              `define                   RdcntvlwInstExSign         `ExSignLen'h0
              `define                   RdcntvhwInstExSign         `ExSignLen'h0
//核心态指令
    //csr访问指令
              `define                   CsrrdInstExSign            `ExSignLen'h0
              `define                   CsrwrInstExSign            `ExSignLen'h0
              `define                   CsrxchgInstExSign          `ExSignLen'h0           
    //cache维护指令                                                        
              `define                   CacopInstExSign            `ExSignLen'h0
     //Tlb维护指令                                       
              `define                   TlbsrchInstExSign          `ExSignLen'h4
              `define                   TlbrdInstExSign            `ExSignLen'h0
              `define                   TlbwrInstExSign            `ExSignLen'h0
              `define                   TlbfillInstExSign          `ExSignLen'h0
              `define                   InvtlbInstExSign           `ExSignLen'h0
    //其他指令                                                             
              `define                   IdleInstExSign             `ExSignLen'h0
              `define                   ErtnInstExSign             `ExSignLen'h0
              `define                   NoExistExSign              `ExSignLen'h0
              



`endif /* !DEFINEEXSIGN_H */
