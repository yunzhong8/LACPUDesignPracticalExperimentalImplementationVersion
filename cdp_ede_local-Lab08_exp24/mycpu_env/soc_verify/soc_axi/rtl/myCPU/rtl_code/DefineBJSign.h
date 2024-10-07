/*
 * DefineJmpSign.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */

`include "DefineLoogLenWidth.h"
`ifndef DEFINEJMPSIGN_H
`define DEFINEJMPSIGN_H

//控制信号
              `define                         NopInstBJSign           `BJSignLen'h00
 //Op6指令
     //跳转指令
       //无条件跳转
              `define                         BInstBJSign            `BJSignLen'h28
              `define                         BlInstBJSign           `BJSignLen'h28
              `define                         JirlInstBJSign         `BJSignLen'h18
       //条件跳转
             `define                          BeqInstBJSign           `BJSignLen'h01 
             `define                          BneInstBJSign           `BJSignLen'h02
             `define                          BltInstBJSign           `BJSignLen'h03
             `define                          BgeInstBJSign           `BJSignLen'h04
             `define                          BltuInstBJSign          `BJSignLen'h05
             `define                          BgeuInstBJSign          `BJSignLen'h06
 //op7指令
     //立即数转载指令
             `define                          Lu12iwInstBJSign        `BJSignLen'h00
     //pc相对计算指令
             `define                          PcaddiInstBJSign          `BJSignLen'h00//基础指令集不存在
             `define                          Pcaddu12iInstBJSign       `BJSignLen'h00
 //OP8指令
     //原子访存指令
            `define                           LlwInstBJSign            `BJSignLen'h00
            `define                           ScwInstBJSign            `BJSignLen'h00
 //Op10指令
     //比较指令
            `define                           SltiInstBJSign           `BJSignLen'h00
            `define                           SltuiInstBJSign          `BJSignLen'h00
    //简单运算指令
            `define                           AddiwInstBJSign          `BJSignLen'h00
    //逻辑运算指令
            `define                           AndiInstBJSign           `BJSignLen'h00
            `define                           OriInstBJSign            `BJSignLen'h00
            `define                           XoriInstBJSign           `BJSignLen'h00
       //访存指令
        //加载指令
            `define                           LdbInstBJSign            `BJSignLen'h00
            `define                           LdhInstBJSign            `BJSignLen'h00
            `define                           LdwInstBJSign            `BJSignLen'h00
         //存储指令
            `define                           StbInstBJSign            `BJSignLen'h00
            `define                           SthInstBJSign            `BJSignLen'h00
            `define                           StwInstBJSign            `BJSignLen'h00
        //0扩展加载指令
            `define                           LdbuInstBJSign           `BJSignLen'h00
            `define                           LdhuInstBJSign           `BJSignLen'h00
        //cache预取指令
            `define                           PreldInstBJSign          `BJSignLen'h00
 //op17指令
     //简单算术指令
             `define                          AddwInstBJSign          `BJSignLen'h00
             `define                          SubwInstBJSign          `BJSignLen'h00
     //比较指令
             `define                          SltInstBJSign           `BJSignLen'h00
             `define                          SltuInstBJSign          `BJSignLen'h00
     //逻辑运算
             `define                          AndInstBJSign           `BJSignLen'h00
             `define                          OrInstBJSign            `BJSignLen'h00
             `define                          XorInstBJSign           `BJSignLen'h00
             `define                          NorInstBJSign           `BJSignLen'h00
             `define                          NandInstBJSign          `BJSignLen'h00//基础指令集不存在的指令
     //移位DefineExSign.h指令
             `define                          SllwInstBJSign          `BJSignLen'h00
             `define                          SrlwInstBJSign          `BJSignLen'h00
             `define                          SrawInstBJSign          `BJSignLen'h00
     //复杂运算指令
     //乘法指令
             `define                          MulwInstBJSign          `BJSignLen'h00
             `define                          MulhwInstBJSign         `BJSignLen'h00
             `define                          MulhwuInstBJSign        `BJSignLen'h00
        //除法指令
             `define                          DivwInstBJSign          `BJSignLen'h00
             `define                          ModwInstBJSign          `BJSignLen'h00
             `define                          DivwuInstBJSign         `BJSignLen'h00
             `define                          ModwuInstBJSign         `BJSignLen'h00
       //杂项指令
             `define                          SyscallInstBJSign       `BJSignLen'h00
             `define                          BreakInstBJSign         `BJSignLen'h00
      //移位指令
             `define                          SlliwInstBJSign         `BJSignLen'h00
             `define                          SrliwInstBJSign         `BJSignLen'h00
             `define                          SraiwInstBJSign         `BJSignLen'h00
     //栅障指令
             `define                          DbarInstBJSign          `BJSignLen'h00
             `define                          IbarInstBJSign          `BJSignLen'h00
 //op22
     //时间预取指令
            `define                           RdcntidwInstBJSign       `BJSignLen'h00
            `define                           RdcntvlwInstBJSign       `BJSignLen'h00
            `define                           RdcntvhwInstBJSign       `BJSignLen'h00
//核心态指令
    //csr访问指令
           `define                            CsrrdInstBJSign           `BJSignLen'h00
           `define                            CsrwrInstBJSign           `BJSignLen'h00
           `define                            CsrxchgInstBJSign         `BJSignLen'h00        
    //cache维护指令                                       
           `define                            CacopInstBJSign           `BJSignLen'h00
     //Tlb维护指令                                        
          `define                             TlbsrchInstBJSign          `BJSignLen'h00
          `define                             TlbrdInstBJSign            `BJSignLen'h00
          `define                             TlbwrInstBJSign            `BJSignLen'h00
          `define                             TlbfillInstBJSign          `BJSignLen'h00
          `define                             InvtlbInstBJSign            `BJSignLen'h00
    //其他指令                                            
          `define                              IdleInstBJSign              `BJSignLen'h00
          `define                              ErtnInstBJSign              `BJSignLen'h00
          `define                              NoExistBJSign               `BJSignLen'h00





`endif /* !DEFINEJMPSIGN_H */
