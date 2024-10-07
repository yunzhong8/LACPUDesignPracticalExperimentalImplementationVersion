/*
 * defineSignLocation.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */
`include "DefineLoogLenWidth.h"
//每段信号的总长记录在：DefineLoonLenWidth.h中
//修改信号需要修总长和使用长度
`ifndef DEFINESIGNLOCATION_H

    `define DEFINESIGNLOCATION_H
    
    //译码阶段信号，总长16
    `define ID_SIGN_USE_LEN 15 //4 
    `define ID_SIGN_BEGIN_PIONT 0 //
    `define ID_SIGN_LOCATION  `ID_SIGN_BEGIN_PIONT+`ID_SIGN_USE_LEN-1 : `ID_SIGN_BEGIN_PIONT
    //执行阶段信号 总长4
    `define EXE_SIGN_USE_LEN 3 //1 reg_wdata_src(2)+tlb_se(1)
    `define EXE_SIGN_BEGIN_PIONT  `IdSignLen//16
    `define EXE_SIGN_LOCATION `EXE_SIGN_BEGIN_PIONT+`EXE_SIGN_USE_LEN-1 : `EXE_SIGN_BEGIN_PIONT
    
    //访存阶段信号· 总长 8
    `define MEM_SIGN_USE_LEN  6 //2 mem_we,reg_wdata_src.mem_req
    `define MEM_SIGN_BEGIN_PIONT `ExSignLen+`IdSignLen//16+4
    `define MEM_SIGN_LOCATION `MEM_SIGN_BEGIN_PIONT+`MEM_SIGN_USE_LEN-1 : `MEM_SIGN_BEGIN_PIONT
    
    //写会阶段信号·总长8
    `define WB_SIGN_USE_LEN  8 //1 regs_we,csr_we,llbit_we,wb_wdata_src,(4),tlb_re,tlb_we,tlb_ie,tlb_fe(3)
    `define WB_SIGN_BEGIN_PIONT `MemSignLen+`ExSignLen+`IdSignLen//16+4+8
    `define WB_SIGN_LOCATION  `WB_SIGN_BEGIN_PIONT+`WB_SIGN_USE_LEN -1: `WB_SIGN_BEGIN_PIONT
    
    //JMP信号总长8
    `define B_SIGN_USE_LEN  6 //2
    `define B_SIGN_BEGIN_PIONT `WbSignLen+`MemSignLen+`ExSignLen+`IdSignLen//16+4+8+8
    `define B_SIGN_LOCATION `B_SIGN_BEGIN_PIONT+`B_SIGN_USE_LEN-1 : `B_SIGN_BEGIN_PIONT
    //end 3+1+2+1+2=9 4*9=36
    //例外信号总长4
    `define EXCEP_SIGN_USE_LEN 7 //1
    `define EXCEP_SIGN_BEGIN_POINT  `BJSignLen+`WbSignLen+`MemSignLen+`ExSignLen+`IdSignLen//16+4+8+8+8
    `define EXCEP_SIGN_LOCATION `EXCEP_SIGN_BEGIN_POINT+`EXCEP_SIGN_USE_LEN -1: `EXCEP_SIGN_BEGIN_POINT
    //16+4+8+8+8+4=48
    
`endif /* !defineSIGNLOCATION_H */
