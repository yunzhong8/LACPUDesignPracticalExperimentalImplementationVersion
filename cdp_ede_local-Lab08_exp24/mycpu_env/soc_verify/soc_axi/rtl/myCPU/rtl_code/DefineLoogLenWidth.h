/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*
*/
/*************\
bug:
\*************/
`ifndef DEFINELOOGLENWIDTH_H
`define DEFINELOOGLENWIDTH_H
`include "DefineConfg.h"
`include "DefineError.h"
`include "DefineCache.h"
//`include "DefineCsrAddr.h"
//`include "DefineAluOp.h"
//初始地址
    `define PerTestEn 0 //启动功能测试
  
//物理地址大小
  `define PaLen 32
  `define PaWidth `PaLen-1 :0
  //计数器的最大长度
 `define TimeValLen 32  
//TLB_INI_OPd1最大值
  `define TlbInvOpMax 6

//全局使用的宏定义
    `define ZeroWord32B 32'h0000_0000//32位0

//复位信号
    `define EnLen 1
    `define EnWidth `EnLen-1:0
    `define RstEnable `EnLen'b0 //复位信号有效
    `define RstDisable `EnLen'b1 //复位信号无效

//PC宽度
    `define PcLen   32
    `define PcWidth `PcLen-1:0 //PC宽度
    
    `define FuncTestLineOneIntitialAddr `PcLen'h1bff_fffc
    `define FuncTestLineTwoIntitialAddr `PcLen'h1c00_0000
    
    `define PerfTestLineOneIntitialAddr `PcLen'hffff_fffc
    `define PerfTestLineTwoIntitialAddr `PcLen'h0000_0000
    
//指令宽度
    `define InstLen   32
    `define InstWidth `InstLen-1:0 //指令宽度
    
    `define DoubleInstLen `InstLen+`InstLen
    `define DoubleInstWidth `DoubleInstLen-1:0
//读写信号
    `define WriteEnable      `EnLen'b1 //写使能
    `define WriteDisable     `EnLen'b0 //写禁止

    `define ReadEnable       `EnLen'b1 //读使能信号
    `define ReadDisable      `EnLen'b0 //禁止读

    `define  MemEnable       `EnLen'b1
    `define  MemDisable      `EnLen'b0

//暂停流水
    `define StopLen         6
    `define StopWidth         `StopLen-1:0
    `define StopEnable      `EnLen'b1
    `define StopDisable     `EnLen'b0
//例外
    `define ExceptionTypeLen 20 //[0:15]是手册规定的例外，16是我规定ernt指令例外，17是我规定的tlb在取指令阶段的tlb充填例外，18是我规定的tlb维护指令导致冲刷例外，19 IfPpiLocation 取指令的页特权等级错误
    `define ExceptionTypeWidth `ExceptionTypeLen-1 :0
//PHT表
    `define ScountStateLen 2
    `define ScountStateWidth `ScountStateLen-1 :0
    
    `define ScountAddrLen 10
    `define ScountAddrWidth `ScountAddrLen-1:0
    
    `define PhtWbusLen `EnLen + `ScountAddrLen +`ScountStateLen
    `define PhtWbusWidth `PhtWbusLen-1 :0 
    
 //BTB表
    `define BiatLen 22
    `define BiatWidth `BiatLen-1:0
    
    `define BtbAddrLen 7
    `define BtbAddrWidth `BtbAddrLen-1 :0
    
    `define BtbDataLen `EnLen+`BiatLen+`InstLen
    `define BtbDataWidth `BtbDataLen-1 :0
    
    `define BtbWbusLen `EnLen+`EnLen+`BtbAddrLen + `BiatLen + `PcLen
    `define BtbWbusWidth `BtbWbusLen-1 :0
    
 //Predactor
    `define PtoWbusLen `BtbWbusLen + `PhtWbusLen
    `define PtoWbusWidth `PtoWbusLen-1 :0
 //Icache
    `define ICacheRowAddrLen 3
    `define ICacheRowAddrWidth `ICacheRowAddrLen-1 : 0
    
    `define ICacheIndexLen 4
    `define ICacheIndexWidth `ICacheIndexLen-1:0
    
    `define ICacheAddrLen 5
    `define ICacheAddrWidth `ICacheAddrLen-1 :0

//寄存器组宏定义
    `define RegsAddrLen 5
    `define RegsAddrWidth `RegsAddrLen-1:0 //寄存器组访问地址宽度

    `define RegsDataLen 32
    `define RegsDataWidth `RegsDataLen-1:0 //寄存器组数据宽度
    `define RegsNum 32 //寄存器组寄存器个数
    `define RegsNumLog2  5 //寻址通用寄存器使用的地址长度
//存储器宏定义
    `define MemAddrLen 32
    `define MemAddrWidth `MemAddrLen-1:0
    
    `define MemDataLen  32
    `define MemDataWidth `MemDataLen-1:0
    
    `define MemWeLen 4
    `define MemWeWidth `MemWeLen-1 :0

//ALU
    `define AluOpLen 5 //运算器运算类型控制长度
    `define AluOpWidth `AluOpLen-1:0 //运算器运算类型控制长度

    `define AluShmatLen 5
    `define AluShmatWidth `AluShmatLen-1:0
   

    `define AluOperLen 32
    `define AluOperWidth `AluOperLen-1:0 //运算器参与运算的数的宽度
//CSR
    `define CsrRegLen 32
    `define CsrRegWidth `CsrRegLen-1 :0
    
    `define EcodeLen 6
    `define EcodeWidth `EcodeLen-1:0
    `define EsubCodeLen 9
    `define EsubCodeWidth `EsubCodeLen-1:0
    
    `define CsrAddrLen 14
    `define CsrAddrWidth `CsrAddrLen-1:0
    
   

//指令
  //op位宽
    `define  InstOpLen6   6
    `define  InstOpWidtg6    `InstOpLen6-1 :0
    
    `define  InstOpLen7   7
    `define  InstOpWidth7    `InstOpLen7-1 :0
    
    `define  InstOpLen8   8
    `define  InstOpWidth8    `InstOpLen8-1 :0
    
    `define  InstOpLen10   10
    `define  InstOpWidth10    `InstOpLen10-1 :0
    
    `define  InstOpLen17   17
    `define  InstOpWidth17    `InstOpLen17-1 :0
    
    `define  InstOpLen22   22
    `define  InstOpWidth22    `InstOpLen22-1 :0

//指令信号宽度
    //id阶段
        `define IdSignLen 16
        `define IdSignWidth `IdSignLen-1:0
        
        `define spIdRegsRead2SrcLen    2
        `define spIdRegsRead2SrcWidth   `spIdRegsRead2SrcLen-1:0
        
        `define spIdAluOpaSrcLen    1
        `define spIdAluOpaSrcWidth      `spIdAluOpaSrcLen-1:0
        
        `define spIdAluOpbSrcLen      3
        `define spIdAluOpbSrcWidth      `spIdAluOpbSrcLen-1:0
        
        `define spIdRegsWaddrSrcLen      2
        `define spIdRegsWaddrSrcWidth   `spIdRegsWaddrSrcLen-1:0
        
        `define spIdRegsWdataSrcLen   3
        `define spIdRegsWdataSrcWidth `spIdRegsWdataSrcLen-1:0
        
        `define spIdCsrWaddrSrcLen 2
        `define spIdCsrWaddrSrcWdith `spIdCsrWaddrSrcLen-1 :0
       
    //EXE
        `define ExSignLen 4
        `define ExSignWidth `ExSignLen-1:0
        
        `define spExeRegsWdataSrcLen   2
        `define spExeRegsWdataSrcWidth  `spExeRegsWdataSrcLen-1:0
    //MEM
        `define MemSignLen 8
        `define MemSignWidth `MemSignLen-1:0
        
        `define spMemReqLen             1
        `define spMemReqWidth           `spMemReqLen-1:0
        
        `define spMemMemWeLen           1
        `define spMemMemWeWidth         `spMemMemWeLen-1:0
    
        `define spMemRegsWdataSrcLen 1 //mem阶段传给reg的写入数据控制
        `define spMemRegsWdataSrcWidth  `spMemRegsWdataSrcLen-1:0
    
         
        `define spMemMemDataSrcLen 3 //me
        `define spMemMemDataSrcWidth  `spMemMemDataSrcLen-1:0
      //WB
        `define WbSignLen 8
        `define WbSignWidth `WbSignLen-1 :0
    
     
    //PC修改
        `define BJSignLen 8
        `define BJSignWidth `BJSignLen-1 :0
        
        `define spIdBtypeLen 3
        `define spIdBtypeWidth          `spIdBtypeLen-1:0
        
        `define spIdJmpLen 1
        `define spIdJmpWidth            `spIdJmpLen-1:0
        
        `define spIdJmpBaseAddrSrcLen 1
        `define spIdJmpBaseAddrSrcWidth `spIdJmpBaseAddrSrcLen-1:0
        
        `define spIdJmpOffsAddrSrcLen  1
        `define spIdJmpOffsAddrSrcWidth `spIdJmpOffsAddrSrcLen-1:0
    //例外信号
        `define ExcepSignLen 8
        `define ExcepSignWidth `ExcepSignLen-1:0
        
        `define spExcepTypeLen 3
        `define spExcepTypeWidth `spExcepTypeLen-1 :0
 //信号宽度
  
    `define SignLen          `IdSignLen+`ExSignLen+`MemSignLen+`WbSignLen+`BJSignLen+`ExcepSignLen//信号实际使用长度16+4+8+8+8+4
    `define SignWidth        `SignLen-1:0//信号实际使用宽度
 //中断类型
    `define EscepSwiZero     `ExceptionTypeLen'b0000_0000_0000_0000_0000_0000_0000_0001
    `define EscepSwiOne      `ExceptionTypeLen'b0000_0000_0000_0000_0000_0000_0000_0010
    `define EscepHwiZero     `ExceptionTypeLen'b0000_0000_0000_0000_0000_0000_0000_0100
    `define EscepHwiOne      `ExceptionTypeLen'b0000_0000_0000_0000_0000_0000_0000_1000
    `define EscepHwiTwo      `ExceptionTypeLen'b0000_0000_0000_0000_0000_0000_0001_0000
    `define EscepHwiThree    `ExceptionTypeLen'b0000_0000_0000_0000_0000_0000_0010_0000
    `define EscepHwiFour     `ExceptionTypeLen'b0000_0000_0000_0000_0000_0000_0100_0000
    `define EscepHwiFive     `ExceptionTypeLen'b0000_0000_0000_0000_0000_0000_1000_0000
    `define EscepHwiSix      `ExceptionTypeLen'b0000_0000_0000_0000_0000_0001_0000_0000
    `define EscepHwiSeven    `ExceptionTypeLen'b0000_0000_0000_0000_0000_0010_0000_0000
    `define EscepTi          `ExceptionTypeLen'b0000_0000_0000_0000_0000_0100_0000_0000
    `define EscepIpi         `ExceptionTypeLen'b0000_0000_0000_0000_0000_1000_0000_0000
    `define EscepPis         `ExceptionTypeLen'b0000_0000_0000_0000_0001_0000_0000_0000
    `define EscepPif         `ExceptionTypeLen'b0000_0000_0000_0000_0010_0000_0000_0000
    `define EscepPme         `ExceptionTypeLen'b0000_0000_0000_0000_0100_0000_0000_0000
    `define EscepPpi         `ExceptionTypeLen'b0000_0000_0000_0000_1000_0000_0000_0000
    `define EscepAdef        `ExceptionTypeLen'b0000_0000_0000_0001_0000_0000_0000_0000
    `define EscepAle         `ExceptionTypeLen'b0000_0000_0000_0010_0000_0000_0000_0000
    `define EscepSys         `ExceptionTypeLen'b0000_0000_0000_0100_0000_0000_0000_0000
    `define EscepBrk         `ExceptionTypeLen'b0000_0000_0000_1000_0000_0000_0000_0000
    `define EscepIne         `ExceptionTypeLen'b0000_0000_0001_0000_0000_0000_0000_0000
    `define EscepIpe         `ExceptionTypeLen'b0000_0000_0010_0000_0000_0000_0000_0000
    `define EscepFpd         `ExceptionTypeLen'b0000_0000_0100_0000_0000_0000_0000_0000
    `define EscepFpe         `ExceptionTypeLen'b0000_0000_1000_0000_0000_0000_0000_0000
    `define EscepTlbr        `ExceptionTypeLen'b0000_0001_0000_0000_0000_0000_0000_0000
//TLB    
 `define TlbItemNum 8
 //////////////////////虚拟
 `define EnLen 1
 //虚拟页号
 `define VppnLen 19
 `define VppnWidth `VppnLen-1 :0
 
 //页大小
 `define PsLen 6
 `define PsWidth `PsLen-1 :0
 
 //全局使能位
 `define GLen 1
 `define GWidth `GLen-1 :0
 
 //进程权限id
 `define AsidLen 10
 `define AsidWidth `AsidLen -1 :0
 //查找无效位置
 `define ELen 1
 `define EWidth `Elne-1 :0
 
 
 /////////////////////////物理
 //物理页号
 `define PpnLen 20
 `define PpnWidth `PpnLen-1 :0
 
 //表项对应权限
 `define PlvLen 2
 `define PlvWidth `PlvLen-1 :0
 //表项空间对应的存储访问类型
 `define MatLen 2
 `define MatWidth `MatLen-1:0
 
 //肮脏数据位
 `define DLen  1
 `define DWidth `DLen-1 :0
 //数据有效位
 `define VLen 1
 `define VWidth `VLen-1:0
 
 //TLB表项定义
 `define TlbVirtualItemLen `VppnLen + `PsLen +`GLen +`AsidLen +`ELen 
 `define TlbPhysicsItemLen `PpnLen + `PlvLen +`MatLen+`DLen+`VLen
 `define TLbItemLen `TlbVirtualItemLen + `TlbPhysicsItemLen + `TlbPhysicsItemLen
 
 `define TlbIndexLen 4 //发生修改要修改csr中的tlbidx_reg的空字段（特别是取值为16的时候）
 `define TlbIndexWidth `TlbIndexLen -1 :0
   
 `define InvtlbOpLen 5
 `define InvtlbOpWidth `InvtlbOpLen-1 :0
 // MMU
 //方寸指令的例外
 `define MmuLSExcepNumLen 6
 `define MmuLSExcepNumWidth `MmuLSExcepNumLen-1:0
 
 `define MmuFetchExcepNumLen 4 //tlb_fetch_adef_except || tlb_fetchr_except || tlb_pif_except || tlb_fetch_ppi_except
 `define MmuFetchExcepNumWidth `MmuFetchExcepNumLen-1:0
 //csr
 `define DmwPsegLen 3
 `define DmwPsegWidth `DmwPsegLen-1 :0
 
 `define DmwVsegLen 3
 `define DmwVsegWidth `DmwVsegLen-1:0
 //TLB读写长度定义
 //`define TlbVirtualWRLen `VppnLen + `PsLen +`GLen +`AsidLen +`ELen 
 //`define TlbPhysicsWRLen `PpnLen + `PlvLen +`MatLen+ `DLen + `VLen 
    
    
    
    
   
    
    
`endif
