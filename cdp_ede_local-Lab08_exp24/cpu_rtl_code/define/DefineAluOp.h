/*
 * DefineAluOp.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */
`include "DefineLoogLenWidth.h"
`ifndef DEFINEALUOP_H
`define DEFINEALUOP_H

//ALU操作码
     //移位运算ALU操作码
        `define SllAluOp       `AluOpLen'd0//逻辑左运算
        `define SrlAluOp       `AluOpLen'd1//逻辑右运算
        `define SraAluOp       `AluOpLen'd2//算术右运算
     //算术运算ALU操作码
        `define AddAluOp       `AluOpLen'd3//加法
        `define SubAluOp       `AluOpLen'd4//减法
     //逻辑运算ALU操作码
        `define AndAluOp        `AluOpLen'd5//按位与
        `define OrAluOp         `AluOpLen'd6//按位或
        `define XorAluOp        `AluOpLen'd7//按位异或
        `define NorAluOp        `AluOpLen'd8//按位或非
    //比较运算
        `define SltAluOp        `AluOpLen'd9//有符号比较
        `define SltuAluOp       `AluOpLen'd10//无符号比较
      //复杂运算
        `define MulAluOp        `AluOpLen'd11//乘
        `define MuluAluOp       `AluOpLen'd13//无符号乘
        
        `define DivAluOp        `AluOpLen'd14//除法
        `define ModAluOp        `AluOpLen'd15//取模
        `define DivuAluOp       `AluOpLen'd16//无符号除
        `define ModuAluOp       `AluOpLen'd17//无符号取模
        `define NoAluOp         `AluOpLen'd18//误操作
        `define LuiAluOp        `AluOpLen'd19

`endif /* !DEFINEALUOP_H */
