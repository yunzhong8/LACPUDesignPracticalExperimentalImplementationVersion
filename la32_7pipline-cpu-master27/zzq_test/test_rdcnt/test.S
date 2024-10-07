#include "regdef.h"
.data 
.text
.global main
main:
start:
addi.w $r2,zero,0x80
addi.w $r3,zero,0
loop:
addi.w $r3,$r3,1
bne $r3,$r2,loop
rdcntvl.w s6
rdcntvl.w s5
addi.w s5,s5,10
mod.wu s5,s5,$r3
b start
