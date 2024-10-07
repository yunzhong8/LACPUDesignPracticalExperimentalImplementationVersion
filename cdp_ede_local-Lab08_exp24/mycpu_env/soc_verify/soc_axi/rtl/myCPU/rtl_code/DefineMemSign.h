/*
 * DefineMemSign.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */
`include "DefineLoogLenWidth.h"
`ifndef DEFINEMEMSIGN_H
`define DEFINEMEMSIGN_H

//控制信号
              `define                    NopInstMemSign            `MemSignLen'h00
 //Op6
     //跳转
       //无条件
              `define                    BInstMemSign              `MemSignLen'h00
              `define                    BlInstMemSign             `MemSignLen'h00
              `define                    JirlInstMemSign           `MemSignLen'h00
       //条件
              `define                    BeqInstMemSign            `MemSignLen'h00  
              `define                    BneInstMemSign            `MemSignLen'h00 
              `define                    BltInstMemSign            `MemSignLen'h00 
              `define                    BgeInstMemSign            `MemSignLen'h00
              `define                    BltuInstMemSign           `MemSignLen'h00
              `define                    BgeuInstMemSign           `MemSignLen'h00
 //op7
     //立即数转载
              `define                    Lu12iwInstMemSign         `MemSignLen'h00
     //pc相对计算
              `define                    PcaddiInstMemSign         `MemSignLen'h00 //基础指令集不存在
              `define                    Pcaddu12iInstMemSign      `MemSignLen'h00
 //OP8指
     //原子访存指
              `define                    LlwInstMemSign            `MemSignLen'h22
              `define                    ScwInstMemSign            `MemSignLen'h21
 //Op10指
     //比较指
              `define                    SltiInstMemSign           `MemSignLen'h00
              `define                    SltuiInstMemSign          `MemSignLen'h00
    //简单运算指
              `define                    AddiwInstMemSign          `MemSignLen'h00
    //逻辑运算指
              `define                    AndiInstMemSign           `MemSignLen'h00
              `define                    OriInstMemSign            `MemSignLen'h00
              `define                    XoriInstMemSign           `MemSignLen'h00
       //访存指
        //加载指
              `define                    LdbInstMemSign            `MemSignLen'h36
              `define                    LdhInstMemSign            `MemSignLen'h2E
              `define                    LdwInstMemSign            `MemSignLen'h22
         //存储指
              `define                    StbInstMemSign            `MemSignLen'h31
              `define                    SthInstMemSign            `MemSignLen'h29
              `define                    StwInstMemSign            `MemSignLen'h21
        //0扩展加载指
              `define                    LdbuInstMemSign           `MemSignLen'h32
              `define                    LdhuInstMemSign           `MemSignLen'h2A
        //cache预取指
              `define                    PreldInstMemSign          `MemSignLen'h00
 //op17指
     //简单算术指
              `define                    AddwInstMemSign           `MemSignLen'h00
              `define                    SubwInstMemSign           `MemSignLen'h00
     //比较指
              `define                    SltInstMemSign            `MemSignLen'h00
              `define                    SltuInstMemSign           `MemSignLen'h00
     //逻辑运
              `define                    AndInstMemSign            `MemSignLen'h00
              `define                    OrInstMemSign             `MemSignLen'h00
              `define                    XorInstMemSign            `MemSignLen'h00
              `define                    NorInstMemSign            `MemSignLen'h00
              `define                    NandInstMemSign           `MemSignLen'h00 //基础指令集不存在的指令
     //移位指
              `define                    SllwInstMemSign           `MemSignLen'h00
              `define                    SrlwInstMemSign           `MemSignLen'h00
              `define                    SrawInstMemSign           `MemSignLen'h00
     //复杂运算指
     //乘法指
              `define                    MulwInstMemSign           `MemSignLen'h00
              `define                    MulhwInstMemSign          `MemSignLen'h00
              `define                    MulhwuInstMemSign         `MemSignLen'h00
        //除法指
              `define                    DivwInstMemSign           `MemSignLen'h00
              `define                    ModwInstMemSign           `MemSignLen'h00
              `define                    DivwuInstMemSign          `MemSignLen'h00
              `define                    ModwuInstMemSign          `MemSignLen'h00
       //杂项指
              `define                    SyscallInstMemSign        `MemSignLen'h00
              `define                    BreakInstMemSign          `MemSignLen'h00
      //移位指
              `define                    SlliwInstMemSign          `MemSignLen'h00
              `define                    SrliwInstMemSign          `MemSignLen'h00
              `define                    SraiwInstMemSign          `MemSignLen'h00
     //栅障指
              `define                    DbarInstMemSign           `MemSignLen'h00
              `define                    IbarInstMemSign           `MemSignLen'h00
 //op2
     //时间预取指
              `define                    RdcntidwInstMemSign       `MemSignLen'h00
              `define                    RdcntvlwInstMemSign       `MemSignLen'h00
              `define                    RdcntvhwInstMemSign       `MemSignLen'h00
//核心态指
    //csr访问指
              `define                    CsrrdInstMemSign          `MemSignLen'h00
              `define                    CsrwrInstMemSign          `MemSignLen'h00
              `define                    CsrxchgInstMemSign        `MemSignLen'h00
    //cache维护指令                                     
               `define                   CacopInstMemSign          `MemSignLen'h00
     //Tlb维护指令                                      
               `define                   TlbsrchInstMemSign        `MemSignLen'h00
               `define                   TlbrdInstMemSign          `MemSignLen'h00
               `define                   TlbwrInstMemSign          `MemSignLen'h00
               `define                   TlbfillInstMemSign        `MemSignLen'h00
               `define                   InvtlbInstMemSign         `MemSignLen'h00
    //其他指令                                          
               `define                   IdleInstMemSign           `MemSignLen'h00
               `define                   ErtnInstMemSign           `MemSignLen'h00
               `define                   NoExistMemSign            `MemSignLen'h00




`endif /* !DEFINEMEMSIGN_H */
