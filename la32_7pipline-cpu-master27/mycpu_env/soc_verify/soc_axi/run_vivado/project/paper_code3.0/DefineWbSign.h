/*
 * DefineWbSign.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */
`include "DefineLoogLenWidth.h"
`ifndef DEFINEWBSIGN_H
`define DEFINEWBSIGN_H

//控制信号
              `define                NopInstWbSign           `WbSignLen'h0
 //Op6指令
     //跳转指令
       //无条件跳转
              `define                BInstWbSign            `WbSignLen'h0
              `define                BlInstWbSign           `WbSignLen'h1
              `define                JirlInstWbSign         `WbSignLen'h1
       //条件跳转
              `define                BeqInstWbSign           `WbSignLen'h0  
              `define                BneInstWbSign           `WbSignLen'h0 
              `define                BltInstWbSign           `WbSignLen'h0 
              `define                BgeInstWbSign           `WbSignLen'h0
              `define                BltuInstWbSign          `WbSignLen'h0
              `define                BgeuInstWbSign          `WbSignLen'h0
 //op7指令
     //立即数转载指令
              `define                Lu12iwInstWbSign        `WbSignLen'h1
     //pc相对计算指令
              `define                PcaddiInstWbSign          `WbSignLen'h0 //基础指令集不存在
              `define                Pcaddu12iInstWbSign       `WbSignLen'h1
 //OP8指令
     //原子访存指令
              `define                LlwInstWbSign            `WbSignLen'h5
              `define                ScwInstWbSign            `WbSignLen'h4
 //Op10指令
     //比较指令
              `define                SltiInstWbSign           `WbSignLen'h1
              `define                SltuiInstWbSign          `WbSignLen'h1
    //简单运算指令
              `define                AddiwInstWbSign          `WbSignLen'h1
    //逻辑运算指令
              `define                AndiInstWbSign           `WbSignLen'h1
              `define                OriInstWbSign            `WbSignLen'h1
              `define                XoriInstWbSign           `WbSignLen'h1
       //访存指令
        //加载指令
              `define                LdbInstWbSign            `WbSignLen'h1
              `define                LdhInstWbSign            `WbSignLen'h1
              `define                LdwInstWbSign            `WbSignLen'h1
         //存储指令
              `define                StbInstWbSign            `WbSignLen'h0
              `define                SthInstWbSign            `WbSignLen'h0
              `define                StwInstWbSign            `WbSignLen'h0
        //0扩展加载指令
              `define                LdbuInstWbSign           `WbSignLen'h1
              `define                LdhuInstWbSign           `WbSignLen'h1
        //cache预取指令
              `define                PreldInstWbSign          `WbSignLen'h0
 //op17指令
     //简单算术指令
              `define                AddwInstWbSign          `WbSignLen'h1
              `define                SubwInstWbSign          `WbSignLen'h1
     //比较指令
              `define                SltInstWbSign           `WbSignLen'h1
              `define                SltuInstWbSign          `WbSignLen'h1
     //逻辑运算
              `define                AndInstWbSign           `WbSignLen'h1
              `define                OrInstWbSign            `WbSignLen'h1
              `define                XorInstWbSign           `WbSignLen'h1
              `define                NorInstWbSign           `WbSignLen'h1
              `define                NandInstWbSign          `WbSignLen'h0 //基础指令集不存在的指令
     //移位指令
              `define                SllwInstWbSign          `WbSignLen'h1
              `define                SrlwInstWbSign          `WbSignLen'h1
              `define                SrawInstWbSign          `WbSignLen'h1
     //复杂运算指令
     //乘法指令
              `define                MulwInstWbSign          `WbSignLen'h1
              `define                MulhwInstWbSign         `WbSignLen'h1
              `define                MulhwuInstWbSign        `WbSignLen'h1
        //除法指令
              `define                DivwInstWbSign          `WbSignLen'h1
              `define                ModwInstWbSign          `WbSignLen'h1
              `define                DivwuInstWbSign         `WbSignLen'h1
              `define                ModwuInstWbSign         `WbSignLen'h1
       //杂项指令
              `define                SyscallInstWbSign       `WbSignLen'h0
              `define                BreakInstWbSign         `WbSignLen'h0
      //移位指令
              `define                SlliwInstWbSign         `WbSignLen'h1
              `define                SrliwInstWbSign         `WbSignLen'h1
              `define                SraiwInstWbSign         `WbSignLen'h1
     //栅障指令
              `define                DbarInstWbSign          `WbSignLen'h80
              `define                IbarInstWbSign          `WbSignLen'h80
 //op22
     //时间预取指令
              `define                RdcntidwInstWbSign       `WbSignLen'h9
              `define                RdcntvlwInstWbSign       `WbSignLen'h1
              `define                RdcntvhwInstWbSign       `WbSignLen'h1
//核心态指令
    //csr访问指令
              `define                CsrrdInstWbSign           `WbSignLen'h9
              `define                CsrwrInstWbSign           `WbSignLen'hb
              `define                CsrxchgInstWbSign         `WbSignLen'hb          
    //cache维护指令                                       
              `define                CacopInstWbSign           `WbSignLen'h0
     //Tlb维护指令                                                      
              `define                TlbsrchInstWbSign          `WbSignLen'h0
              `define                TlbrdInstWbSign            `WbSignLen'h10
              `define                TlbwrInstWbSign            `WbSignLen'h20
              `define                TlbfillInstWbSign          `WbSignLen'h80
              `define                InvtlbInstWbSign           `WbSignLen'h40
    //其他指令                                                          
              `define                IdleInstWbSign              `WbSignLen'h0
              `define                ErtnInstWbSign              `WbSignLen'h0
              `define                NoExistWbSign                `WbSignLen'h0





`endif /* !DEFINEWBSIGN_H */
