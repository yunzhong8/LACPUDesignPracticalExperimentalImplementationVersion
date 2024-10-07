/*
 * DefineAluOp.h
 * Copyright (C) 2023 zzq <zzq@zzq-HP-Pavilion-Gaming-Laptop-15-cx0xxx>
 *
 * Distributed under terms of the MIT license.
 */
`ifndef DEFINECACHE_H
`define DEFINECACHE_H

`define CacheIndexLen 8
`define CacheIndexWidth `CacheIndexLen-1:0

`define CacheTagLen 20
`define CacheTagWidth `CacheTagLen-1 :0

`define CacheOffsetLen 4
`define CacheOffsetWidth `CacheOffsetLen-1 :0

`define CacheWstrbLen 4
`define CacheWstrbWidth `CacheWstrbLen-1 :0

`define CacheBurstDataLen 128
`define CacheBurstDataWidth `CacheBurstDataLen-1 :0

 `define CacheBurstLastLen 2
 `define CacheBurstLastWidth `CacheBurstLastLen-1 :0
 


 
 `define Way0Data0Location 31:0
 `define Way0Data1Location 63:32
 `define Way0Data2Location 95:64
 `define Way0Data3Location 127:96
 `define Way0DataLocation 127:0
 `define Way0TagLocation 147:128 //
 `define Way0VLocation 148
 `define Way0DLocation 149
 
 
 `define Way1Data0Location 181:150
 `define Way1Data1Location 213:182
 `define Way1Data2Location 245:214
 `define Way1Data3Location 277:246
 `define Way1DataLocation  277:150
 `define Way1TagLocation 297:278//
 `define Way1VLocation 298
 `define Way1DLocation 299

`endif /* !DEFINEALUOP_H */
