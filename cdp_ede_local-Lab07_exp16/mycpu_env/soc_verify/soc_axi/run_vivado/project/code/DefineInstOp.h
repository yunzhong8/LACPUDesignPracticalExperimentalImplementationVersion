/*
 * InstOpDefine.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */

`ifndef DEFINEINSTOP_H
`define DEFINEINSTOP_H

//指令
    //跳转指令
      //无条件跳转
             `define JirlInstOp             `InstOpLen6'b0100_11
             `define BInstOp                `InstOpLen6'b0101_00
             `define BlInstOp               `InstOpLen6'b0101_01
      //条件跳转
            `define BeqInstOp               `InstOpLen6'b0101_10
            `define BneInstOp               `InstOpLen6'b0101_11
            `define BltInstOp               `InstOpLen6'b0110_00
            `define BgeInstOp               `InstOpLen6'b0110_01
            `define BltuInstOp              `InstOpLen6'b0110_10
            `define BgeuInstOp              `InstOpLen6'b0110_11
//op7指令
    //立即数转载指令
            `define Lu12iwInstOp            `InstOpLen7'b0001_010
    //pc相对计算指令
          `define Pcaddu12iInstOp           `InstOpLen7'b0001_110
//OP8指令
    //原子访存指令
           `define LlwInstOp                `InstOpLen8'b0010_0000
           `define ScwInstOp                `InstOpLen8'b0010_0001
//Op10指令
    //比较指令
           `define SltiInstOp               `InstOpLen10'b0000_0010_00
           `define SltuiInstOp              `InstOpLen10'b0000_0010_01
   //简单运算指令
           `define AddiInstOp               `InstOpLen10'b0000_0010_10
   //逻辑运算指令
           `define AndiInstOp               `InstOpLen10'b0000_0011_01
           `define OriInstOp                `InstOpLen10'b0000_0011_10
           `define XoriInstOp               `InstOpLen10'b0000_0011_11
      //访存指令
       //加载指令
           `define LdbInstOp                `InstOpLen10'b0010_1000_00
           `define LdhInstOp                `InstOpLen10'b0010_1000_01
           `define LdwInstOp                `InstOpLen10'b0010_1000_10

        //存储指令
           `define StbInstOp                `InstOpLen10'b0010_1001_00
           `define SthInstOp                `InstOpLen10'b0010_1001_01
           `define StwInstOp                `InstOpLen10'b0010_1001_10
       //0扩展加载指令
           `define LdbuInstOp               `InstOpLen10'b0010_1010_00
           `define LdhuInstOp               `InstOpLen10'b0010_1010_01


       //cache预取指令
           `define PreldInstOp              `InstOpLen10'b0010_1010_11
//op17指令
    //简单算术指令
            `define AddwInstOp             `InstOpLen17'b0000_0000_0001_0000_0
            `define SubwInstOp             `InstOpLen17'b0000_0000_0001_0001_0
    //比较指令
            `define SltInstOp              `InstOpLen17'b0000_0000_0001_0010_0
            `define SltuInstOp             `InstOpLen17'b0000_0000_0001_0010_1
    //逻辑运算
            `define AndInstOp              `InstOpLen17'b0000_0000_0001_0100_1
            `define OrInstOp               `InstOpLen17'b0000_0000_0001_0101_0
            `define XorInstOp              `InstOpLen17'b0000_0000_0001_0101_1
            `define NorInstOp              `InstOpLen17'b0000_0000_0001_0100_0
    //移位指令
            `define SllwInstOp             `InstOpLen17'b0000_0000_0001_0111_0
            `define SrlwInstOp             `InstOpLen17'b0000_0000_0001_0111_1
            `define SrawInstOp             `InstOpLen17'b0000_0000_0001_1000_0

    //复杂运算指令
    //乘法指令
            `define MulwInstOp             `InstOpLen17'b0000_0000_0001_1100_0
            `define MulhwInstOp            `InstOpLen17'b0000_0000_0001_1100_1
            `define MulhwuInstOp           `InstOpLen17'b0000_0000_0001_1101_0
       //除法指令
            `define DivwInstOp             `InstOpLen17'b0000_0000_0010_0000_0
            `define ModwInstOp             `InstOpLen17'b0000_0000_0010_0000_1
            `define DivwuInstOp            `InstOpLen17'b0000_0000_0010_0001_0
            `define ModwuInstOp            `InstOpLen17'b0000_0000_0010_0001_1
      //杂项指令
            `define SyscallInstOp          `InstOpLen17'b0000_0000_0010_1011_0
            `define BreakInstOp            `InstOpLen17'b0000_0000_0010_1010_0
     //移位指令
            `define SlliwInstOp            `InstOpLen17'b0000_0000_0100_0000_1
            `define SrliwInstOp            `InstOpLen17'b0000_0000_0100_0100_1
            `define SraiwInstOp            `InstOpLen17'b0000_0000_0100_1000_1
    //栅障指令
            `define DbarInstOp             `InstOpLen17'b0011_1000_0111_0010_0
            `define IbarInstOp             `InstOpLen17'b0011_1000_0111_0010_1
//op22
    //时间预取指令
           `define RdcntidwInstOp          `InstOpLen22'b0000_0000_0000_0000_0110_00
           `define RdcntvlwInstOp          `InstOpLen22'b0000_0000_0000_0000_0110_00
           `define RdcntvhwInstOp          `InstOpLen22'h0000_0000_0000_0000_0110_01
   //csr访问指令
          `define CsrrdInstOp              `InstOpLen8'b0000_0100
          `define CsrwrInstOp              `InstOpLen8'b0000_0100
          `define CsrxchgInstOp            `InstOpLen8'b0000_0100
   //cache维护指令
          `define CacopInstOp              `InstOpLen10'b0000_0110_00
    //Tlb维护指令
         `define TlbsrchInstOp             `InstOpLen22'b0000_0110_0100_1000_0010_10
         `define TlbrdInstOp               `InstOpLen22'b0000_0110_0100_1000_0010_11
         `define TlbwrInstOp               `InstOpLen22'b0000_0110_0100_1000_0011_00
         `define TlbfillInstOp             `InstOpLen22'b0000_0110_0100_1000_0011_01
        `define InvtlbInstoP               `InstOpLen17'b0000_0110_0100_1001_1
   //其他指令
        `define IdleInstOp                 `InstOpLen17'b0000_0110_0100_1000_1
        `define ErtnInstOp                 `InstOpLen22'b0000_0110_0100_1000_0011_10


`endif /* !INSTOPDEFINE_H */
