# 描述此程序名字和功能的注释
# 打算使用队列来保存数据，所以但是以一个字表示坐标
#include "inst_test.h"
# Template.s
# 汇编程序模板
#bug:
#没有考虑字节地址，半字地址，和字地址，cpu是字节地址，我忘记移位*4了
# 显存位置
.data # 本行之后是数据声明

.text # 指令在本行之后开始
.global main
main:  # 程序入口
#设置缓存一致性
SET_CACHE_CONSISTENCY($r1)
# 将寄存器堆全部清理
RESET_REGS_FUNC
nop
# 进行连续读写同一个地址测
addi.w $r2,zero,0xff
li.w $r5,0xcc50
LOAD_STORE_TEST($r3,$r2,$r4,$r5)
#保存寄存器值
REGS_SAVE_FUNC($r1)
## 测试非法除法
DIV_ILLEGALITY($r1,$r2,$r3,$r4,$r5)
REGS_LOAD_FUNC($r1)
IDLE_FUNC
