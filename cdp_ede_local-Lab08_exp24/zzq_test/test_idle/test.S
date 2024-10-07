# 描述此程序名字和功能的注释
# Template.s
# 汇编程序模板
#####################bug
#beq执行忘记写逗号了"," beq $r1,$r2 loop2
#正确形式：beq $r1,$r2,loop2
#寄存器忘记写$了
#######################
.data # 本行之后是数据声明

.text # 指令在本行之后开始

.global main
main:  # 程序入口
//设置缓存一致性和打开中断
addi.w $r1,$r0,0xac
csrwr $r1,0
//打开中断使能位号sb,立即数最大是12位，为什么编译器只允许11位
li.w $r1,0xfffff000
addi.w $r1,$r1,0x7ff
addi.w $r1,$r1,1
addi.w $r1,$r1,0x7ff
csrwr $r1,4
//设在定时中断
addi.w $r1,$r0,0x2f1
csrwr $r1,0x41
//设置idle
idle 0
addi.w $r2,$r0,0xff
addi.w $r3,$r0,0
addi.w $r4,$r0,0
loop1:
addi.w $r4,$r4,1
bne $r4,$r2,loop1
loop2:
b loop1
