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
//设置缓存一致性
addi.w $r1,$r0,40
csrwr $r1,0
//赋初始值
addi.w $r1,$r0,1
addi.w $r2,$r0,1
//所以次数循环的最大次数
addi.w $r3,$r0,128

//检查B循环指令，r1的值不断自增
loop1:
addi.w $r1,$r1,1 //循环次数
beq $r1,$r3,loop2
B loop1
//跳转的冗余指令，检查
addi.w $r2,$r2,1

//循环检查bne指令 
loop2:
addi.w $r2,$r2,1 //r2记录循环次数
bne $r2,$r3,loop2
addi.w $r2,$r2,1 //跳转指令的冗余指令没有处理就会跳转失效

loop3://检查blt指令
addi.w $r4,$r4,1
blt  $r4,$r3,loop3
addi.w $r4,$r4,1

loop4:
addi.w $r5,$r5,1
bge   $r3,$r5,loop4
