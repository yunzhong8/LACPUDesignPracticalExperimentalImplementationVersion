# 描述此程序名字和功能的注释
# Template.s
# 汇编程序模板

.data # 本行之后是数据声明

.text # 指令在本行之后开始

.global main
main:  # 程序入口
addi.w $r1,$r0,12
st.w  $r1,$r0,8
ld.w $r2,$r0,8
add.w $r3,$r1,$r2
