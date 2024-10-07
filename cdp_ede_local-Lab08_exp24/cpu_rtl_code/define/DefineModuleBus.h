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
//基础级BUS
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
`define DataWriteBusLen `EnLen+`EnLen+2+`MemWeLen+12+`MemDataLen
`define DataWriteBusWidth `DataWriteBusLen-1 :0

//高级总线宽度
        `define PcInstBusLen   `PcLen+`InstLen
        `define PcInstBusWidth `PcInstBusLen-1:0
    //preif
         `define PcBufferBusLen `EnLen+`PcLen
         `define PcBufferBusWidth `PcBufferBusLen-1:0
         
         `define PreifToNextBusLen  `EnLen + `ExcepBusLen +`PcLen    + `ExcepBusLen +`PcLen
         `define PreifToNextBusWidth `PreifToNextBusLen-1:0
         
     //预测器
        `define PrToIfBusLen `EnLen+`EnLen+`EnLen+ 2 + `PcLen//1+32+1+1+2=35
        `define PrToIfBusWidth `PrToIfBusLen-1 :0
        
        `define PrToIfDataBusLen  `EnLen+`EnLen+ 2 + `PcLen
        `define PrToIfDataBusWidth  `PrToIfDataBusLen-1 :0
     //uncache预测器
        `define PucAddrLen 5
        `define PucAddrWidth `PucAddrLen-1:0
        `define PucWbusLen `EnLen+`EnLen +`PucAddrLen
        `define PucWbusWidth `PucWbusLen-1 :0
     //if
       //线级
            `define LineIfToNextBusLen   `EnLen+`EnLen+`EnLen+     `EnLen+`EnLen+`ScountStateLen +`PcLen+    `ExcepBusLen+`PcLen      +`ExcepBusLen+`PcLen//1+1+2+32+
            `define LineIfToNextBusWidth   `LineIfToNextBusLen-1:0
        
       
        //模块级
            `define InstRdataBufferBusLen `EnLen + `InstLen
            `define InstRdataBufferBusWidth `InstRdataBufferBusLen-1 :0
            
            `define IfToNextBusLen    `LineIfToNextBusLen 
            `define IfToNextBusWidth   `IfToNextBusLen-1:0
            
            `define IfToNextSignleBusLen `EnLen+`EnLen+`EnLen+`PpnLen
            `define IfToNextSignleBusWidth `IfToNextSignleBusLen-1:0
            
            `define IfToPreBusLen  `EnLen+`PcLen 
            `define IfToPreBusWidth `IfToPreBusLen-1 :0
            
      //Ift阶段 取指令第二阶段
        //流水条级的数据传输
            `define LineIftToNextBusLen     `EnLen+`EnLen+ 2 +`PcLen+  `ExcepBusLen +    `PcInstBusLen  
            `define LineIftToNextBusWidth `LineIftToNextBusLen-1:0
            
            
            `define LineIftToPreBusLen `EnLen
            `define LineIftToPreBusWidth `LineIftToPreBusLen-1:0    
        //模块级的数据传输
            `define IftToPreBusLen  `EnLen//cache_we,tlb_flush,branch_flush      
            `define IftToPreBusWidth `IftToPreBusLen-1:0                         
        
            `define IftToNextBusLen   `LineIftToNextBusLen + `LineIftToNextBusLen 
            `define IftToNextBusWidth  `IftToNextBusLen-1:0        
            
            `define IftToPreifBusLen  `PcBranchBusLen
            `define IftToPreifBusWidth `IdToPreifBusLen-1:0      
            
            
            
        
       
    
    //ICache
       `define ICacheReadIbusLen `EnLen+`PcLen+`EnLen+`PcLen
       `define ICacheReadIbusWidth `ICacheReadIbusLen-1 :0
       
       `define ICacheReadObusLen `EnLen +`InstLen+`EnLen+`InstLen
       `define ICacheReadObusWidth `ICacheReadObusLen -1 :0
       
       `define ICacheWriteIbusLen `EnLen+`PcLen+`InstLen
       `define ICacheWriteIbusWidth `ICacheWriteIbusLen-1 :0
     //计数器
        `define CoutToIdBusLen 64//64+64
        `define CoutToIdBusWidth `CoutToIdBusLen-1:0
    
    //Id阶段
        //流水条级的数据传输
            `define LineIdToNextBusLen   `EnLen+  `EnLen+`EnLen+ 2 +`PcLen+  `ExcepBusLen+    `AluOpLen+`SignLen+   `PcInstBusLen  
            `define LineIdToNextBusWidth `LineIdToNextBusLen-1:0
            
            
            `define LineIdToPreBusLen `EnLen
            `define LineIdToPreBusWidth `LineIdToPreBusLen-1:0
            
        
        //模块级的数据传输
            `define OdToIspBusLen   32+32+32+64+16+4+32+`InstLen
            `define OdToIspBusWidth `OdToIspBusLen-1:0
            
            `define IdToPreifBusLen  `PcBranchBusLen
            `define IdToPreifBusWidth `IdToPreifBusLen-1:0
            
//            `define IdToPreBusLen `EnLen//cache_we,tlb_flush,branch_flush
//            `define IdToPreBusWidth `IdToPreBusLen-1:0
        
            `define IdToNextBusLen   `LineIdToNextBusLen + `LineIdToNextBusLen
            `define IdToNextBusWidth  `IdToNextBusLen-1:0
            
            
            `define IdToSpBusLen   `RegsAddrLen+`RegsAddrLen+`RegsAddrLen+`InstLen
            `define IdToSpBusWidth `IdToSpBusLen-1 :0
          
    //Launch阶段
        //线级
            `define LineLaunchToPreBusLen 1
            `define LineLaunchToPreBusWidth `LineLaunchToPreBusLen-1 :0
            
            `define LineLaunchToNextBusLen `EnLen+`EnLen+5+  `spIdBtypeLen+`spIdJmpLen+`EnLen+`PcLen+`PcLen+   `EnLen+  `EnLen+ 2 +`PcLen+   `EnLen+ `EnLen+`EnLen+`EnLen+`EnLen+`EnLen+5+`EnLen+`EnLen+`LineRegsReadObusLen+`ExcepBusLen+`LlbitWriteBusLen+`EnLen+`LineCsrWriteBusLen+`spExeRegsWdataSrcLen+`AluBusLen+`spMemRegsWdataSrcLen+`spMemMemDataSrcLen+`MemWriteBusLen+`EnLen+`LineRegsWriteBusLen +`PcInstBusLen
            `define LineLaunchToNextBusWidth `LineLaunchToNextBusLen-1:0
        //模块级
            `define LaunchToPreBusLen `LineLaunchToPreBusLen +`LineLaunchToPreBusLen
            `define LaunchToPreBusWidth `LaunchToPreBusLen-1 :0
            
            `define LaunchToNextBusLen `LineLaunchToNextBusLen + `LineLaunchToNextBusLen
            `define LaunchToNextBusWidth `LaunchToNextBusLen-1 :0           
        
    //EXE阶段
       
        //线级数据传输
            `define LineExToNextBusLen  `EnLen+`EnLen+5+ `EnLen+`PcLen+   `EnLen+`EnLen+  `EnLen+`EnLen+`EnLen+`EnLen+`EnLen    +5+2+     `EnLen+`EnLen+`LineRegsReadObusLen+   `ExcepBusLen+  `LlbitWriteBusLen+  `EnLen+`LineCsrWriteBusLen    +`spMemRegsWdataSrcLen+`spMemMemDataSrcLen+`EnLen+`EnLen+`MemAddrLen   +`EnLen+`LineRegsWriteBusLen    +`PcInstBusLen
            `define LineExToNextBusWidth `LineExToNextBusLen-1:0
            
            `define LineExForwardBusLen  `LineRegsWriteBusLen+`EnLen
            `define LineExForwardBusWidth `LineExForwardBusLen-1:0
            
            `define ExToDataBusLen `DataWriteBusLen
            `define ExToDataBusWidth `ExToDataBusLen-1:0
        //模块级数据传输
            `define ExToNextBusLen  `LineExToNextBusLen + `LineExToNextBusLen
            `define ExToNextBusWidth `ExToNextBusLen-1 : 0
            
            `define ExForwardBusLen  `LineExForwardBusLen + `LineExForwardBusLen
            `define ExForwardBusWidth `ExForwardBusLen-1:0
    //MM阶段
        //线级        
            `define LineMmToPreBusLen 1
            `define LineMmToPreBusWidth `LineMmToPreBusLen-1 :0
            
            `define LineMmForwardBusLen `LineRegsWriteBusLen+`EnLen
            `define LineMmForwardBusWidth `LineMmForwardBusLen-1 :0
            
            `define LineMmToNextBusLen `EnLen+`EnLen+5+ `EnLen+`EnLen+`PpnLen+    `EnLen+`PcLen+ `EnLen+`EnLen+  `EnLen+`EnLen+`EnLen+`EnLen+`EnLen+    5+`EnLen+ `EnLen +`TlbIndexLen+   `EnLen+`EnLen+`LineRegsReadObusLen+    `ExcepBusLen+`MemAddrLen+    `LlbitWriteBusLen+     `EnLen+`LineCsrWriteBusLen+  +`spMemRegsWdataSrcLen+`spMemMemDataSrcLen+`EnLen+`EnLen+`MemAddrLen+    `EnLen+`LineRegsWriteBusLen    +`PcInstBusLen
            `define LineMmToNextBusWidth `LineMmToNextBusLen-1:0
       //模块级`
            `define MmToPreBusLen `LineMmToPreBusLen+`LineMmToPreBusLen
            `define MmToPreBusWidth `MmToPreBusLen-1:0
            
            `define MmForwardBusLen `LineMmForwardBusLen+`LineMmForwardBusLen
            `define MmForwardBusWidth `MmForwardBusLen-1 :0 
            
            `define MmToNextBusLen `LineMmToNextBusLen+`LineMmToNextBusLen
            `define MmToNextBusWidth `MmToNextBusLen-1:0     
    //MEM阶段       
        //线级
            `define LineMemToPreBusLen 1
            `define LineMemToPreBusWidth  `LineMemToPreBusLen-1 :0
                       
            `define LineMemToNextBusLen `EnLen+`EnLen+  `EnLen+`PcLen+ `EnLen+`EnLen+  `EnLen+`EnLen+`EnLen+`EnLen+`EnLen+5+`EnLen+ `EnLen +`TlbIndexLen+`EnLen+`EnLen+`LineRegsReadObusLen+`ExcepBusLen+`MemAddrLen+`LlbitWriteBusLen+`EnLen+`LineCsrWriteBusLen+`EnLen+`LineRegsWriteBusLen +`PcInstBusLen
            `define LineMemToNextBusWidth  `LineMemToNextBusLen-1 :0
            
            `define LineMemForwardBusLen `LineRegsWriteBusLen+`EnLen
            `define LineMemForwardBusWidth `LineMemForwardBusLen-1 :0
    
        //模块级
            `define MemToNextBusLen `LineMemToNextBusLen + `LineMemToNextBusLen
            `define MemToNextBusWidth  `MemToNextBusLen-1 :0 
            
            `define MemForwardBusLen  `LineMemForwardBusLen + `LineMemForwardBusLen
            `define MemForwardBusWidth `MemForwardBusLen-1:0
            
            `define MemToPreBusLen `LineMemToPreBusLen+`LineMemToPreBusLen
            `define MemToPreBusWidth  `MemToPreBusLen-1 :0
        
    //WB
       //线级
            `define LineWbToDebugBusLen  `PcLen +`LineRegsWriteBusLen
            `define LineWbToDebugBusWidth  `LineWbToDebugBusLen-1 :0
            
            `define LineWbToRegsBusLen `LineRegsWriteBusLen
            `define LineWbToRegsBusWidth `LineWbToRegsBusLen-1 :0
            
            `define LineWbToCsrLen `EnLen + `EnLen + 32+32+32+`PsLen+`EnLen+`EnLen+`TlbIndexLen+`EnLen+`AsidLen+`LlbitWriteBusLen + `CsrAddrLen+`LineCsrWriteBusLen
            `define LineWbToCsrWidth `LineWbToCsrLen-1 :0
       //模块级
            `define WbToRegsBusLen `LineWbToRegsBusLen +`LineWbToRegsBusLen
            `define WbToRegsBusWidth `WbToRegsBusLen-1 :0
            
            `define WbToCsrLen `LineWbToCsrLen + `LineWbToCsrLen
            `define WbToCsrWidth `WbToCsrLen-1 :0
            
            `define WbToDebugBusLen  `LineWbToDebugBusLen +`LineWbToDebugBusLen
            `define WbToDebugBusWidth  `WbToDebugBusLen-1 :0
    //except_to_csr tlb_except_en_o,tlb_inst_flush_en_o, tlbr_except_en_o,excep_badv_we_o（4）
        `define ExcepToCsrLen `EnLen+    `EnLen+ `EnLen+`PcLen+ `EnLen+ `EnLen+`MemAddrLen+ `EnLen+ `EnLen+`EcodeLen+`EsubCodeLen+`PcLen
        `define ExcepToCsrWidth `ExcepToCsrLen-1:0
    
    //CSR
       //线级
            `define LineCsrToWbLen   1+2+`RegsDataLen
            `define LineCsrToWbWidth `LineCsrToWbLen-1:0
       
       //模块级
            `define CsrToIdLen 1
            `define CsrToIdWidth `CsrToIdLen-1 :0
            
            `define CsrToWbLen   `LineCsrToWbLen +`LineCsrToWbLen
            `define CsrToWbWidth `CsrToWbLen-1:0
                 
            `define CsrToPreifLen `PcBranchBusLen+ `PcBranchBusLen+`PcBranchBusLen+`PcBranchBusLen
            `define CsrToPreifWidth `CsrToPreifLen-1:0
        
   //DR
       //线级 
         `define LineRegsRigthReadBusLen  `EnLen+`LineRegsReadObusLen
         `define LineRegsRigthReadBusWidth `LineRegsRigthReadBusLen-1 :0
       //模块级
        `define RegsOldReadBusLen  `RegsReadObusLen+`RegsReadIbusLen
        `define RegsOldReadBusWidth `RegsOldReadBusLen-1 :0
        
        `define RegsRigthReadBusLen `LineRegsRigthReadBusLen+`LineRegsRigthReadBusLen
        `define RegsRigthReadBusWidth `RegsRigthReadBusLen-1 :0
// SRAM,AXI
    `define SramIbusLen `EnLen + 3 +32+  `EnLen + 3 + 32 + 4 +`CacheBurstDataLen//128+4+32+3+1+32+3+1
    `define SramIbusWidth `SramIbusLen -1 :0
    
    `define SramObusLen `EnLen+`EnLen+`EnLen+`EnLen+32
    `define SramObusWidth `SramObusLen-1 :0
//TLB                                                                                       
  //查找输入bus                                                                                  
  `define TlbSearchIbusLen `VppnLen + `EnLen +`AsidLen                                       
  `define TlbSearchIbusWidth `TlbSearchIbusLen-1 : 0                                         
  //查找输出bus                                                                                  
  `define TlbSearchObusLen  `PpnLen +`PsLen +`PlvLen +`MatLen +`EnLen + `EnLen 
  `define TlbSearchObusWidth  `TlbSearchObusLen-1 : 0                                        
  //写bus                                                                                     
  `define TlbWriteBusLen  `TlbVirtualItemLen + `TlbPhysicsItemLen + `TlbPhysicsItemLen       
  `define TlbWriteBusWidth `TlbWriteBusLen-1 :0                                              
  //读输入bus                                                                                   
  `define TlbReadIbusLen `TlbIndexLen                                                        
  `define TlbReadIbusWidth `TlbReadIbusLen-1 :0                                              
  //读输出bus                                                                                   
  `define TlbReadObusLen  `TlbVirtualItemLen + `TlbPhysicsItemLen + `TlbPhysicsItemLen       
  `define TlbReadObusWidth `TlbReadObusLen-1 :0               
  //TLB清理
  `define TlbInvBusLen `InvtlbOpLen + `AsidLen + `VppnLen
  `define TlbInvBusWidth `TlbInvBusLen-1 :0                               
  //地址定义 
//mmu
   `define IfToMmuBusLen     `PcLen
   `define IfToMmuBusWidth   `IfToMmuBusLen-1 :0
   
   `define MemToMmuBusLen    `EnLen + `EnLen + `MemAddrLen
   `define MemToMmuBusWidth  `MemToMmuBusLen-1 :0
   
   `define WbToMmuBusLen   `EnLen +`EnLen +`EnLen + `InvtlbOpLen + `VppnLen + `AsidLen
   `define WbToMmuBusWidth `WbToMmuBusLen-1:0
   
   `define CsrToMmuBusLen  `RegsDataLen + `RegsDataLen + `RegsDataLen + `RegsDataLen + `RegsDataLen + `RegsDataLen + `RegsDataLen + `RegsDataLen 
   `define CsrToMmuBusWidth `CsrToMmuBusLen-1:0
   
   `define MmuToIfBusLen   `EnLen +`EnLen + `MmuFetchExcepNumLen +`PcLen
   `define MmuToIfBusWidth `MmuToIfBusLen-1:0
   
   `define MmuToMemBusLen   `EnLen +`EnLen +  `MmuLSExcepNumLen + `PcLen +  `TlbIndexLen + `EnLen +  `EnLen //2+6+32+4+2=46
   `define MmuToMemBusWidth `MmuToMemBusLen-1:0
   
   `define MmuToWbBusLen   `EnLen +`RegsDataLen + `RegsDataLen + `RegsDataLen +`PsLen + `AsidLen +
   `define MmuToWbBusWidth `MmuToWbBusLen-1:0
//cache
    `define IfToICacheBusLen `EnLen+`EnLen + 20//uncache,P-tag
    `define IfToICacheBusWidth `IfToICacheBusLen-1:0
    `define MemToCacheBusLen `EnLen+`EnLen+20
    `define MemToCacheBusWidth `MemToCacheBusLen-1 :0 
    
    `define WbToCacheBusLen   `EnLen
    `define WbToCacheBusWidth `WbToCacheBusLen-1 :0 
   
//差分测试接口
    //wb阶段
        //线级
        `define LineWbToDiffBusLen `EnLen +`RegsAddrLen+`RegsDataLen  +`PcInstBusLen+`EnLen
        `define LineWbToDiffBusWidth  `LineWbToDiffBusLen-1 :0   
        //模块级 
        `define WbToDiffBusLen `LineWbToDiffBusLen +`LineWbToDiffBusLen                                                                         
        `define WbToDiffBusWidth  `WbToDiffBusLen-1 :0                              
  
    
`endif /* !DEFINEMODULEBUS_H */
