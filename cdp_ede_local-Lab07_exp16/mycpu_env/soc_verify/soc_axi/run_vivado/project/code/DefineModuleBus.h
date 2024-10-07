/*
 * DefineModuleBus.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 *因为复制粘贴，导致线级使用啦模块级的len
 */
`include "DefineLoogLenWidth.h"
`ifndef DEFINEMODULEBUS_H
`define DEFINEMODULEBUS_H
//绑定接口bus(那些数据是绑定同时出现的就使用相同bus)
  //REGS
  //线级
         `define LineRegsWriteBusLen `EnLen+`RegsAddrLen+`RegsDataLen //reg_we1,reg_waddr5,reg_wdata32
         `define LineRegsWriteBusWidth `LineRegsWriteBusLen-1 : 0

         `define LineRegsReadIbusLen `EnLen+`RegsAddrLen+`EnLen+`RegsAddrLen
         `define LineRegsReadIbusWidth `LineRegsReadIbusLen-1:0
         
         
         `define LineRegsReadObusLen `RegsDataLen +`RegsDataLen
         `define LineRegsReadObusWidth `LineRegsReadObusLen-1 :0
   //模块级
         `define RegsWriteBusLen `LineRegsWriteBusLen+`LineRegsWriteBusLen
         `define RegsWriteBusWidth `RegsWriteBusLen-1 : 0

         `define RegsReadIbusLen `LineRegsReadIbusLen+`LineRegsReadIbusLen
         `define RegsReadIbusWidth `RegsReadIbusLen-1:0
        
        
         `define RegsReadObusLen `LineRegsReadObusLen + `LineRegsReadObusLen
         `define RegsReadObusWidth `RegsReadObusLen-1 :0
         
 //csr写
`define LineCsrWriteBusLen `EnLen+`CsrAddrLen+`RegsDataLen //csr_we,csr_waddr, csr_wdata32
`define LineCsrWriteBusWidth `CsrWriteBusLen-1 : 0

//mem写
`define MemWriteBusLen `EnLen+`EnLen+`MemDataLen //mem_req1,mem_we,mem_wdata,
//例外·
`define ExcepBusLen `EnLen+`ExceptionTypeLen
`define ExcepBusWidth `ExcepBusLen-1 :0
//llbit
`define LlbitWriteBusLen `EnLen+`EnLen
`define LlbitWriteBusWidth `LlbitWriteBusLen-1 :0
//alu
`define AluBusLen `AluOpLen+`AluOperLen+`AluOperLen
`define AluBusWidth `AluBusLen-1:0
//pc分支
`define PcBranchBusLen `EnLen+`PcLen
`define PcBranchBusWidth `PcBranchBusLen-1 :0
//data_ram 写
`define DataWriteBusLen `EnLen+`EnLen+2+`MemWeLen+`MemAddrLen+`MemDataLen
`define DataWriteBusWidth `DataWriteBusLen-1 :0

//总线宽度
        `define PcInstBusLen   `PcLen+`InstLen
        `define PcInstBusWidth `PcInstBusLen-1:0
    //preif
         `define PcBufferBusLen `EnLen+`PcLen
         `define PcBufferBusWidth `PcBufferBusLen-1:0
         
         `define PreifToIfBusLen   `PcLen +`PcLen
         `define PreifToIfBusWidth `PreifToIfBusLen-1:0
     //if
       //线级
        `define LineIfToIdBusLen    `EnLen+`ExcepBusLen  +`PcInstBusLen
        `define LineIfToIdBusWidth   `LineIfToIdBusLen-1:0
        
        //模块级
        `define InstRdataBufferBusLen `EnLen + `InstLen
        `define InstRdataBufferBusWidth `InstRdataBufferBusLen-1 :0
        
        `define IfToIdBusLen    `LineIfToIdBusLen +`LineIfToIdBusLen
        `define IfToIdBusWidth   `IfToIdBusLen-1:0
        
        `define IfToPreifBusLen  `EnLen+`PcLen 
        `define IfToPreifBusWidth `IfToPreifBusLen-1 :0
        
        `define IfToICacheBusLen `EnLen+`PcLen+`InstLen+`EnLen+`PcLen+`EnLen+`PcLen
        `define IfToICacheBusWidth `IfToICacheBusLen:0
    
    //ICache
       `define ICacheReadIbusLen `EnLen+`PcLen+`EnLen+`PcLen
       `define ICacheReadIbusWidth `ICacheReadIbusLen-1 :0
       
       `define ICacheReadObusLen `EnLen +`InstLen+`EnLen+`InstLen
       `define ICacheReadObusWidth `ICacheReadObusLen -1 :0
       
       `define ICacheWriteIbusLen `EnLen+`PcLen+`InstLen
       `define ICacheWriteIbusWidth `ICacheWriteIbusLen-1 :0
     //时钟
        `define CoutToIdBusLen 64//64+64
        `define CoutToIdBusWidth `CoutToIdBusLen-1:0
    
    //Id阶段
        //流水条级的数据传输
        `define LineIdToExBusLen `EnLen+`EnLen+`LineRegsReadObusLen+`ExcepBusLen+`LlbitWriteBusLen+`EnLen+`LineCsrWriteBusLen+`spExeRegsWdataSrcLen+`AluBusLen+`spMemRegsWdataSrcLen+`spMemMemDataSrcLen+`MemWriteBusLen+`EnLen+`LineRegsWriteBusLen +`PcInstBusLen
        `define LineIdToExBusWidth `LineIdToExBusLen-1:0
        
        `define LineIdToRfbBusLen `EnLen +`RegsAddrLen+`EnLen +`RegsAddrLen
        `define LineIdToRfbBusWidth `LineIdToRfbBusLen-1:0
        
       
       
        
        //模块级的数据传输
          `define OdToIspBusLen   32+32+32+64+16+4+32+`InstLen
          `define OdToIspBusWidth `OdToIspBusLen-1:0
          
          `define IdToPreifBusLen  `PcBranchBusLen
          `define IdToPreifBusWidth `IdToPreifBusLen-1:0
          
          `define IdToIfBusLen `EnLen+`EnLen
          `define IdToIfBusWidth `IdToIfBusLen-1:0
        
          `define IdToExBusLen   `LineIdToExBusLen + `LineIdToExBusLen
          `define IdToExBusWidth  `IdToExBusLen-1:0
          
          `define IdToRfbBusLen  `LineIdToRfbBusLen+`LineIdToRfbBusLen
          `define IdToRfbBusWidth `IdToRfbBusLen-1:0
          
          `define IdToSpBusLen   `RegsAddrLen+`RegsAddrLen+`RegsAddrLen+`InstLen
          `define IdToSpBusWidth `IdToSpBusLen-1 :0
        
    //EXE阶段
       
        //线级数据传输
        `define LineExToMemBusLen  `EnLen+`EnLen+`LineRegsReadObusLen+ `ExcepBusLen+`LlbitWriteBusLen+`EnLen+`LineCsrWriteBusLen +`spMemRegsWdataSrcLen+`spMemMemDataSrcLen+`DataWriteBusLen+`EnLen+`LineRegsWriteBusLen +`PcInstBusLen
        `define LineExToMemBusWidth `LineExToMemBusLen-1:0
        
        `define LineExForwardBusLen  `LlbitWriteBusLen+`LineRegsWriteBusLen+`EnLen
        `define LineExForwardBusWidth `LineExForwardBusLen-1:0
        
        `define ExToDataBusLen `DataWriteBusLen
        `define ExToDataBusWidth `ExToDataBusLen-1:0
        //模块级数据传输
         `define ExToMemBusLen  `LineExToMemBusLen + `LineExToMemBusLen
         `define ExToMemBusWidth `ExToMemBusLen-1 : 0
         
         `define ExForwardBusLen  `LineExForwardBusLen + `LineExForwardBusLen
         `define ExForwardBusWidth `ExForwardBusLen-1:0
         
    //MEM阶段
        `define LineMemToExBusLen 1
        `define LineMemToExBusWidth  `LineMemToExBusLen-1 :0
       
        //线级
        `define LineMemToWbBusLen `EnLen+`EnLen+`LineRegsReadObusLen+`ExcepBusLen+`MemAddrLen+`LlbitWriteBusLen+`EnLen+`LineCsrWriteBusLen+`EnLen+`LineRegsWriteBusLen +`PcInstBusLen
        `define LineMemToWbBusWidth  `LineMemToWbBusLen-1 :0
        
        `define LineMemForwardBusLen `LlbitWriteBusLen+`LineRegsWriteBusLen+`EnLen
        `define LineMemForwardBusWidth `LineMemForwardBusLen-1 :0
    
        //模块级
        `define MemToWbBusLen `LineMemToWbBusLen + `LineMemToWbBusLen
        `define MemToWbBusWidth  `MemToWbBusLen-1 :0 
        
        `define MemForwardBusLen  `LineMemForwardBusLen + `LineMemForwardBusLen
        `define MemForwardBusWidth `MemForwardBusLen-1:0
        
        `define MemToExBusLen `LineMemToExBusLen+`LineMemToExBusLen
        `define MemToExBusWidth  `MemToExBusLen-1 :0
        
    //WB
       //线级
        `define LineWbToDebugBusLen  `PcLen +`LineRegsWriteBusLen
        `define LineWbToDebugBusWidth  `LineWbToDebugBusLen-1 :0
        
        `define LineWbToRegsBusLen `LineRegsWriteBusLen
        `define LineWbToRegsBusWidth `LineWbToRegsBusLen-1 :0
        
        `define LineWbToCsrLen `LlbitWriteBusLen + `CsrAddrLen+`LineCsrWriteBusLen
        `define LineWbToCsrWidth `LineWbToCsrLen-1 :0
       //模块级
        `define WbToRegsBusLen `LineWbToRegsBusLen +`LineWbToRegsBusLen
        `define WbToRegsBusWidth `WbToRegsBusLen-1 :0
        
        `define WbToCsrLen `LineWbToCsrLen + `LineWbToCsrLen
        `define WbToCsrWidth `WbToCsrLen-1 :0
        
        `define WbToDebugBusLen  `LineWbToDebugBusLen +`LineWbToDebugBusLen
        `define WbToDebugBusWidth  `WbToDebugBusLen-1 :0
    //except_to_csr
        `define ExcepToCsrLen `EnLen+`MemAddrLen+`EnLen+`EnLen+`EcodeLen+`EsubCodeLen+`PcLen
        `define ExcepToCsrWidth `ExcepToCsrLen-1:0
    
    //CSR
       //线级
        `define LineCsrToWbLen   2+`RegsDataLen
        `define LineCsrToWbWidth `LineCsrToWbLen-1:0
       
       //模块级
        `define CsrToIdLen 1
        `define CsrToIdWidth `CsrToIdLen-1 :0
        
        `define CsrToWbLen   `LineCsrToWbLen +`LineCsrToWbLen
        `define CsrToWbWidth `CsrToWbLen-1:0
             
        `define CsrToPreifLen `PcBranchBusLen+`PcBranchBusLen
        `define CsrToPreifWidth `CsrToPreifLen-1:0
    //RFB
        //线级
        `define LineRfbToIdBusLen `CsrToIdLen+`LineRegsReadObusLen
        `define LineRfbToIdBusWidth `LineRfbToIdBusLen-1 :0
        //模块级
        `define RfbToIdBusLen `LineRfbToIdBusLen+`LineRfbToIdBusLen
        `define RfbToIdBusWidth `RfbToIdBusLen-1 :0
        
   //DR
       //线级
       
        
         `define LineRegsRigthReadBusLen `EnLen+`LineRfbToIdBusLen
         `define LineRegsRigthReadBusWidth `LineRegsRigthReadBusLen-1 :0
       //模块级
        `define RegsOldReadBusLen  `RfbToIdBusLen+`RegsReadIbusLen
        `define RegsOldReadBusWidth `RegsOldReadBusLen-1 :0
        
        `define RegsRigthReadBusLen `LineRegsRigthReadBusLen+`LineRegsRigthReadBusLen
        `define RegsRigthReadBusWidth `RegsRigthReadBusLen-1 :0
// SRAM,AXI
    `define SramIbusLen `EnLen + `EnLen + 2 + 4 +32 +32
    `define SramIbusWidth `SramIbusLen -1 :0
    
    `define SramObusLen `EnLen+`EnLen+32
    `define SramObusWidth `SramObusLen-1 :0
    
`endif /* !DEFINEMODULEBUS_H */
