/*
 * defineSignLocation.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */
`include "DefineLoogLenWidth.h"

`ifndef DEFINESIGNLOCATION_H

    `define DEFINESIGNLOCATION_H
    
    //译码阶段信号
    `define ID_SIGN_USE_LEN 15 //4 
    `define ID_SIGN_BEGIN_PIONT 0 //8+4+8+4=24
    `define ID_SIGN_LOCATION  `ID_SIGN_BEGIN_PIONT+`ID_SIGN_USE_LEN-1 : `ID_SIGN_BEGIN_PIONT
    //执行阶段信号
    `define EXE_SIGN_USE_LEN 2 //1 reg_wdata_src(2)
    `define EXE_SIGN_BEGIN_PIONT  `IdSignLen//16
    `define EXE_SIGN_LOCATION `EXE_SIGN_BEGIN_PIONT+`EXE_SIGN_USE_LEN-1 : `EXE_SIGN_BEGIN_PIONT
    
    //访存阶段信号·
    `define MEM_SIGN_USE_LEN  6 //2 mem_we,reg_wdata_src.mem_req
    `define MEM_SIGN_BEGIN_PIONT `ExSignLen+`IdSignLen//8+4=12
    `define MEM_SIGN_LOCATION `MEM_SIGN_BEGIN_PIONT+`MEM_SIGN_USE_LEN-1 : `MEM_SIGN_BEGIN_PIONT
    
    //写会阶段信号·
    `define WB_SIGN_USE_LEN  4 //1 regs_we,csr_we,llbit_we
    `define WB_SIGN_BEGIN_PIONT `MemSignLen+`ExSignLen+`IdSignLen//8+4=12
    `define WB_SIGN_LOCATION  `WB_SIGN_BEGIN_PIONT+`WB_SIGN_USE_LEN -1: `WB_SIGN_BEGIN_PIONT
    
    //JMP信号
    `define B_SIGN_USE_LEN  6 //2
    `define B_SIGN_BEGIN_PIONT `WbSignLen+`MemSignLen+`ExSignLen+`IdSignLen//8+4=12
    `define B_SIGN_LOCATION `B_SIGN_BEGIN_PIONT+`B_SIGN_USE_LEN-1 : `B_SIGN_BEGIN_PIONT
    //end 3+1+2+1+2=9 4*9=36
    //例外信号
    `define EXCEP_SIGN_USE_LEN 4
    `define EXCEP_SIGN_BEGIN_POINT  `BJSignLen+`WbSignLen+`MemSignLen+`ExSignLen+`IdSignLen//8+4=12
    `define EXCEP_SIGN_LOCATION `EXCEP_SIGN_BEGIN_POINT+`EXCEP_SIGN_USE_LEN -1: `EXCEP_SIGN_BEGIN_POINT
    
`endif /* !defineSIGNLOCATION_H */
