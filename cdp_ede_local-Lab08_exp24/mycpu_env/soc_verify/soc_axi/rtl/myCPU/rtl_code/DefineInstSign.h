/*
 * SpDefine.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */
`include "DefineLoogLenWidth.h"
`include "DefineIdSign.h"
`include "DefineExSign.h"
`include "DefineMemSign.h"
`include "DefineWbSign.h"
`include "DefineBJSign.h"
`include "DefineExcepSign.h"

`ifndef DEFINESP_H
`define DEFINESP_H

//控制信号 
             `define NopInstSign           {     `NopInstExcepSign        ,  `NopInstBJSign       ,   `NopInstWbSign          ,      `NopInstMemSign      ,            `NopInstExSign      ,         `NopInstIdSign                                                     }
 //Op6指令                                         
     //跳转指令                                      
       //无条件跳转                                   
              `define BInstSign            {     `BInstExcepSign          ,  `BInstBJSign         ,   `BInstWbSign            ,      `BInstMemSign        ,            `BInstExSign        ,         `BInstIdSign                                                       }
              `define BlInstSign           {     `BlInstExcepSign         ,  `BlInstBJSign        ,   `BlInstWbSign           ,      `BlInstMemSign       ,            `BlInstExSign       ,         `BlInstIdSign                                                      }
              `define JirlInstSign         {     `JirlInstExcepSign       ,  `JirlInstBJSign      ,   `JirlInstWbSign         ,      `JirlInstMemSign     ,            `JirlInstExSign     ,         `JirlInstIdSign                                                    }
       //条件跳转                                                                                         
             `define BeqInstSign           {     `BeqInstExcepSign        ,  `BeqInstBJSign       ,   `BeqInstWbSign          ,      `BeqInstMemSign      ,            `BeqInstExSign      ,         `BeqInstIdSign                                                     }
             `define BneInstSign           {     `BneInstExcepSign        ,  `BneInstBJSign       ,   `BneInstWbSign          ,      `BneInstMemSign      ,            `BneInstExSign      ,         `BneInstIdSign                                                     }
             `define BltInstSign           {     `BltInstExcepSign        ,  `BltInstBJSign       ,   `BltInstWbSign          ,      `BltInstMemSign      ,            `BltInstExSign      ,         `BltInstIdSign                                                     }
             `define BgeInstSign           {     `BgeInstExcepSign        ,  `BgeInstBJSign       ,   `BgeInstWbSign          ,      `BgeInstMemSign      ,            `BgeInstExSign      ,         `BgeInstIdSign                                                     }
             `define BltuInstSign          {     `BltuInstExcepSign       ,  `BltuInstBJSign      ,   `BltuInstWbSign         ,      `BltuInstMemSign     ,            `BltuInstExSign     ,         `BltuInstIdSign                                                    }
             `define BgeuInstSign          {     `BgeuInstExcepSign       ,  `BgeuInstBJSign      ,   `BgeuInstWbSign         ,      `BgeuInstMemSign     ,            `BgeuInstExSign     ,         `BgeuInstIdSign                                                    }                                                                                                   
 //op7指令                                                                                                  
     //立即数转载指令                                                                                            
            // `define Lu12iwInstSign        {     `Lu12iwInstExcepSign     ,  `Lu12iwInstBJSign    ,   `Lu12iwInstWbSign       ,      `Lu12iwInstMemSign   ,            `Lu12iwInstExSign   ,         `Lu12iwInstIdSign                                                  }                                                   `                                                                     
     //pc相对计算指令                           
           `define PcaddiInstSign          {     `PcaddiInstExcepSign     ,  `PcaddiInstBJSign    ,   `PcaddiInstWbSign       ,      `PcaddiInstMemSign   ,            `PcaddiInstExSign   ,         `PcaddiInstIdSign                                                  }
           `define Pcaddu12iInstSign       {     `Pcaddu12iInstExcepSign  ,  `Pcaddu12iInstBJSign ,   `Pcaddu12iInstWbSign    ,      `Pcaddu12iInstMemSign,            `Pcaddu12iInstExSign,         `Pcaddu12iInstIdSign                                               }                                                                                                  
 //OP8指令                                       
     //原子访存指令                                  
            `define LlwInstSign            {     `LlwInstExcepSign        ,  `LlwInstBJSign       ,   `LlwInstWbSign          ,      `LlwInstMemSign      ,            `LlwInstExSign      ,         `LlwInstIdSign                                                     }
            `define ScwInstSign            {     `ScwInstExcepSign        ,  `ScwInstBJSign       ,   `ScwInstWbSign          ,      `ScwInstMemSign      ,            `ScwInstExSign      ,         `ScwInstIdSign                                                     }
 //Op10指令                                      
     //比较指令                                    
            //`define SltiInstSign           {     `SltiInstExcepSign       ,  `SltiInstBJSign      ,   `SltiInstWbSign         ,      `SltiInstMemSign     ,            `SltiInstExSign     ,         `SltiInstIdSign                                                    }
            //`define SltiInstSign           {     4'h0       ,  8'h0      ,   4'h0         ,      8'h0     ,           4'h0    ,        16'h0                                                   }              
            //`define SltiInstSign           44'h0                                                                   `                                                                     
            `define SltuiInstSign          {     `SltuiInstExcepSign      ,  `SltuiInstBJSign     ,   `SltuiInstWbSign        ,      `SltuiInstMemSign    ,            `SltuiInstExSign    ,         `SltuiInstIdSign                                                   }
    //简单运算指令                                  
            `define AddiwInstSign          {     `AddiwInstExcepSign      ,  `AddiwInstBJSign     ,   `AddiwInstWbSign        ,      `AddiwInstMemSign    ,            `AddiwInstExSign    ,         `AddiwInstIdSign                                                   }
    //逻辑运算指令                                  
            `define AndiInstSign           {     `AndiInstExcepSign       ,  `AndiInstBJSign      ,   `AndiInstWbSign         ,      `AndiInstMemSign     ,            `AndiInstExSign     ,         `AndiInstIdSign                                                    }
            `define OriInstSign            {     `OriInstExcepSign        ,  `OriInstBJSign       ,   `OriInstWbSign          ,      `OriInstMemSign      ,            `OriInstExSign      ,         `OriInstIdSign                                                     }
            `define XoriInstSign           {     `XoriInstExcepSign       ,  `XoriInstBJSign      ,   `XoriInstWbSign         ,      `XoriInstMemSign     ,            `XoriInstExSign     ,         `XoriInstIdSign                                                    }
       //访存指令                                  
        //加载指令                                 
            `define LdbInstSign            {     `LdbInstExcepSign        ,  `LdbInstBJSign       ,   `LdbInstWbSign          ,      `LdbInstMemSign      ,            `LdbInstExSign      ,         `LdbInstIdSign                                                     }
            `define LdhInstSign            {     `LdhInstExcepSign        ,  `LdhInstBJSign       ,   `LdhInstWbSign          ,      `LdhInstMemSign      ,            `LdhInstExSign      ,         `LdhInstIdSign                                                     }
            `define LdwInstSign            {     `LdwInstExcepSign        ,  `LdwInstBJSign       ,   `LdwInstWbSign          ,      `LdwInstMemSign      ,            `LdwInstExSign      ,         `LdwInstIdSign                                                     }                                                                                                                                                                                                     
         //存储指令                                
            `define StbInstSign            {     `StbInstExcepSign        ,  `StbInstBJSign       ,   `StbInstWbSign          ,      `StbInstMemSign      ,            `StbInstExSign      ,         `StbInstIdSign                                                     }
            `define SthInstSign            {     `SthInstExcepSign        ,  `SthInstBJSign       ,   `SthInstWbSign          ,      `SthInstMemSign      ,            `SthInstExSign      ,         `SthInstIdSign                                                     }
            `define StwInstSign            {     `StwInstExcepSign        ,  `StwInstBJSign       ,   `StwInstWbSign          ,      `StwInstMemSign      ,            `StwInstExSign      ,         `StwInstIdSign                                                     }
        //0扩展加载指令                             
            `define LdbuInstSign           {     `LdbuInstExcepSign       ,  `LdbuInstBJSign      ,   `LdbuInstWbSign         ,      `LdbuInstMemSign     ,            `LdbuInstExSign     ,         `LdbuInstIdSign                                                    }
            `define LdhuInstSign           {     `LdhuInstExcepSign       ,  `LdhuInstBJSign      ,   `LdhuInstWbSign         ,      `LdhuInstMemSign     ,            `LdhuInstExSign     ,         `LdhuInstIdSign                                                    }
        //cache预取指令                              `                        ,  `                    ,   `                       ,      `                    ,            `                   ,         `                                                                  
            `define PreldInstSign          {     `PreldInstExcepSign      ,  `PreldInstBJSign     ,   `PreldInstWbSign        ,      `PreldInstMemSign    ,            `PreldInstExSign    ,         `PreldInstIdSign                                                   }
 //op17指令                                       
     //简单算术指令                                   
             `define AddwInstSign          {     `AddwInstExcepSign       ,  `AddwInstBJSign      ,   `AddwInstWbSign         ,      `AddwInstMemSign     ,            `AddwInstExSign     ,         `AddwInstIdSign                                                    }
             `define SubwInstSign          {     `SubwInstExcepSign       ,  `SubwInstBJSign      ,   `SubwInstWbSign         ,      `SubwInstMemSign     ,            `SubwInstExSign     ,         `SubwInstIdSign                                                    }
     //比较指令                                    
             `define SltInstSign           {     `SltInstExcepSign        ,  `SltInstBJSign       ,   `SltInstWbSign          ,      `SltInstMemSign      ,            `SltInstExSign      ,         `SltInstIdSign                                                     }
             `define SltuInstSign          {     `SltuInstExcepSign       ,  `SltuInstBJSign      ,   `SltuInstWbSign         ,      `SltuInstMemSign     ,            `SltuInstExSign     ,         `SltuInstIdSign                                                    }
     //逻辑运算                                     
             `define AndInstSign           {     `AndInstExcepSign        ,  `AndInstBJSign       ,   `AndInstWbSign          ,      `AndInstMemSign      ,            `AndInstExSign      ,         `AndInstIdSign                                                     }
             `define OrInstSign            {     `OrInstExcepSign         ,  `OrInstBJSign        ,   `OrInstWbSign           ,      `OrInstMemSign       ,            `OrInstExSign       ,         `OrInstIdSign                                                      }
             `define XorInstSign           {     `XorInstExcepSign        ,  `XorInstBJSign       ,   `XorInstWbSign          ,      `XorInstMemSign      ,            `XorInstExSign      ,         `XorInstIdSign                                                     }
             `define NorInstSign           {     `NorInstExcepSign        ,  `NorInstBJSign       ,   `NorInstWbSign          ,      `NorInstMemSign      ,            `NorInstExSign      ,         `NorInstIdSign                                                     }
             `define NandInstSign          {     `NandInstExcepSign       ,  `NandInstBJSign      ,   `NandInstWbSign         ,      `NandInstMemSign     ,            `NandInstExSign     ,         `NandInstIdSign                                                    }
     //移位指令                                     
             `define SllwInstSign          {     `SllwInstExcepSign       ,  `SllwInstBJSign      ,   `SllwInstWbSign         ,      `SllwInstMemSign     ,            `SllwInstExSign     ,         `SllwInstIdSign                                                    }
             `define SrlwInstSign          {     `SrlwInstExcepSign       ,  `SrlwInstBJSign      ,   `SrlwInstWbSign         ,      `SrlwInstMemSign     ,            `SrlwInstExSign     ,         `SrlwInstIdSign                                                    }
             `define SrawInstSign          {     `SrawInstExcepSign       ,  `SrawInstBJSign      ,   `SrawInstWbSign         ,      `SrawInstMemSign     ,            `SrawInstExSign     ,         `SrawInstIdSign                                                    }                                                                                                   
     //复杂运算指令                                
     //乘法指令                                  
             `define MulwInstSign          {     `MulwInstExcepSign       ,  `MulwInstBJSign      ,   `MulwInstWbSign         ,      `MulwInstMemSign     ,            `MulwInstExSign     ,         `MulwInstIdSign                                                    }
             `define MulhwInstSign         {     `MulhwInstExcepSign      ,  `MulhwInstBJSign     ,   `MulhwInstWbSign        ,      `MulhwInstMemSign    ,            `MulhwInstExSign    ,         `MulhwInstIdSign                                                   }
             `define MulhwuInstSign        {     `MulhwuInstExcepSign     ,  `MulhwuInstBJSign    ,   `MulhwuInstWbSign       ,      `MulhwuInstMemSign   ,            `MulhwuInstExSign   ,         `MulhwuInstIdSign                                                  }
        //除法指令                                                                                        
             `define DivwInstSign          {     `DivwInstExcepSign       ,  `DivwInstBJSign      ,   `DivwInstWbSign         ,      `DivwInstMemSign     ,            `DivwInstExSign     ,         `DivwInstIdSign                                                    }
             `define ModwInstSign          {     `ModwInstExcepSign       ,  `ModwInstBJSign      ,   `ModwInstWbSign         ,      `ModwInstMemSign     ,            `ModwInstExSign     ,         `ModwInstIdSign                                                    }
             `define DivwuInstSign         {     `DivwuInstExcepSign      ,  `DivwuInstBJSign     ,   `DivwuInstWbSign        ,      `DivwuInstMemSign    ,            `DivwuInstExSign    ,         `DivwuInstIdSign                                                   }
             `define ModwuInstSign         {     `ModwuInstExcepSign      ,  `ModwuInstBJSign     ,   `ModwuInstWbSign        ,      `ModwuInstMemSign    ,            `ModwuInstExSign    ,         `ModwuInstIdSign                                                   }
       //杂项指令                                  
             `define SyscallInstSign       {     `SyscallInstExcepSign    ,  `SyscallInstBJSign   ,   `SyscallInstWbSign      ,      `SyscallInstMemSign  ,            `SyscallInstExSign  ,         `SyscallInstIdSign                                                 }
             `define BreakInstSign         {     `BreakInstExcepSign      ,  `BreakInstBJSign     ,   `BreakInstWbSign        ,      `BreakInstMemSign    ,            `BreakInstExSign    ,         `BreakInstIdSign                                                   }
      //移位指令                                   
             `define SlliwInstSign         {     `SlliwInstExcepSign      ,  `SlliwInstBJSign     ,   `SlliwInstWbSign        ,      `SlliwInstMemSign    ,            `SlliwInstExSign    ,         `SlliwInstIdSign                                                   }
             `define SrliwInstSign         {     `SrliwInstExcepSign      ,  `SrliwInstBJSign     ,   `SrliwInstWbSign        ,      `SrliwInstMemSign    ,            `SrliwInstExSign    ,         `SrliwInstIdSign                                                   }
             `define SraiwInstSign         {     `SraiwInstExcepSign      ,  `SraiwInstBJSign     ,   `SraiwInstWbSign        ,      `SraiwInstMemSign    ,            `SraiwInstExSign    ,         `SraiwInstIdSign                                                   }
     //栅障指令                                  
             `define DbarInstSign          {     `DbarInstExcepSign       ,  `DbarInstBJSign      ,   `DbarInstWbSign         ,      `DbarInstMemSign     ,            `DbarInstExSign     ,         `DbarInstIdSign                                                    }
             `define IbarInstSign          {     `IbarInstExcepSign       ,  `IbarInstBJSign      ,   `IbarInstWbSign         ,      `IbarInstMemSign     ,            `IbarInstExSign     ,         `IbarInstIdSign                                                    }
 //op22                                         
     //时间预取指令                                   
            `define RdcntidwInstSign       {     `RdcntidwInstExcepSign   ,  `RdcntidwInstBJSign  ,   `RdcntidwInstWbSign     ,      `RdcntidwInstMemSign ,            `RdcntidwInstExSign ,         `RdcntidwInstIdSign                                                }
            `define RdcntvlwInstSign       {     `RdcntvlwInstExcepSign   ,  `RdcntvlwInstBJSign  ,   `RdcntvlwInstWbSign     ,      `RdcntvlwInstMemSign ,            `RdcntvlwInstExSign ,         `RdcntvlwInstIdSign                                                }
            `define RdcntvhwInstSign       {     `RdcntvhwInstExcepSign   ,  `RdcntvhwInstBJSign  ,   `RdcntvhwInstWbSign     ,      `RdcntvhwInstMemSign ,            `RdcntvhwInstExSign ,         `RdcntvhwInstIdSign                                                }
//核心态指令                                       
    //csr访问指令                                 
           `define CsrrdInstSign           {     `CsrrdInstExcepSign      ,  `CsrrdInstBJSign     ,   `CsrrdInstWbSign        ,      `CsrrdInstMemSign    ,            `CsrrdInstExSign    ,         `CsrrdInstIdSign                                                   }
           `define CsrwrInstSign           {     `CsrwrInstExcepSign      ,  `CsrwrInstBJSign     ,   `CsrwrInstWbSign        ,      `CsrwrInstMemSign    ,            `CsrwrInstExSign    ,         `CsrwrInstIdSign                                                   }
           `define CsrxchgInstSign         {     `CsrxchgInstExcepSign    ,  `CsrxchgInstBJSign   ,   `CsrxchgInstWbSign      ,      `CsrxchgInstMemSign  ,            `CsrxchgInstExSign  ,         `CsrxchgInstIdSign                                                 }                                                                                                   
    //cache维护指令                         `                                                                
           `define CacopInstSign           {     `CacopInstExcepSign      ,  `CacopInstBJSign     ,   `CacopInstWbSign        ,      `CacopInstMemSign    ,            `CacopInstExSign    ,         `CacopInstIdSign                                                   }
     //Tlb维护指令                                 
          `define TlbsrchInstSign          {     `TlbsrchInstExcepSign    ,  `TlbsrchInstBJSign   ,   `TlbsrchInstWbSign      ,      `TlbsrchInstMemSign  ,            `TlbsrchInstExSign  ,         `TlbsrchInstIdSign                                                 }
          `define TlbrdInstSign            {     `TlbrdInstExcepSign      ,  `TlbrdInstBJSign     ,   `TlbrdInstWbSign        ,      `TlbrdInstMemSign    ,            `TlbrdInstExSign    ,         `TlbrdInstIdSign                                                   }
          `define TlbwrInstSign            {     `TlbwrInstExcepSign      ,  `TlbwrInstBJSign     ,   `TlbwrInstWbSign        ,      `TlbwrInstMemSign    ,            `TlbwrInstExSign    ,         `TlbwrInstIdSign                                                   }
          `define TlbfillInstSign          {     `TlbfillInstExcepSign    ,  `TlbfillInstBJSign   ,   `TlbfillInstWbSign      ,      `TlbfillInstMemSign  ,            `TlbfillInstExSign  ,         `TlbfillInstIdSign                                                 }
         `define InvtlbInstSign            {     `InvtlbInstExcepSign     ,  `InvtlbInstBJSign    ,   `InvtlbInstWbSign       ,      `InvtlbInstMemSign   ,            `InvtlbInstExSign   ,         `InvtlbInstIdSign                                                  }
    //其他指令                                  
         `define IdleInstSign              {     `IdleInstExcepSign       ,  `IdleInstBJSign      ,   `IdleInstWbSign         ,      `IdleInstMemSign     ,            `IdleInstExSign     ,         `IdleInstIdSign                                                    }
         `define ErtnInstSign              {     `ErtnInstExcepSign       ,  `ErtnInstBJSign      ,   `ErtnInstWbSign         ,      `ErtnInstMemSign     ,            `ErtnInstExSign     ,         `ErtnInstIdSign                                                    }
                                                                                                                                                                       
            `define SltiInstSign           {     `SltiInstExcepSign       ,  `SltiInstBJSign      ,   `SltiInstWbSign         ,      `SltiInstMemSign     ,            `SltiInstExSign     ,         `SltiInstIdSign                                                    }      
             `define Lu12iwInstSign        {     `Lu12iwInstExcepSign     ,  `Lu12iwInstBJSign    ,   `Lu12iwInstWbSign       ,      `Lu12iwInstMemSign   ,            `Lu12iwInstExSign   ,         `Lu12iwInstIdSign                                                  }                                                                       
            `define  NoExistInstSign       {     `NoExistExcepSign        ,  `NoExistBJSign       ,    `NoExistWbSign         ,    `NoExistMemSign        ,            `NoExistExSign      ,         `NoExistIdSign                                                     }
`endif /* !SPDEFINE_H */
