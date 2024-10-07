#include "game.h"
# define REGS_SAVE_ADDR 0xafb00000
# define REGS_SAVE_FUNC(addr_reg)\
	li.w addr_reg,REGS_SAVE_ADDR;\
	st.w $r1,addr_reg,0x0;\
        st.w $r2,addr_reg,0x4;\
	st.w $r2,addr_reg,0x8;\
	st.w $r3,addr_reg,0xc;\
	st.w $r4,addr_reg,0x10;\
	st.w $r5,addr_reg,0x14;\
	st.w $r6,addr_reg,0x18;\
	st.w $r7,addr_reg,0x1c;\
	st.w $r8,addr_reg,0x20;\
	st.w $r9,addr_reg,0x24;\
	st.w $r10,addr_reg,0x28;\
	st.w $r11,addr_reg,0x2c;\
	st.w $r12,addr_reg,0x30;\
	st.w $r13,addr_reg,0x34;\
	st.w $r14,addr_reg,0x38;\
	st.w $r15,addr_reg,0x3c;\
	st.w $r16,addr_reg,0x40;\
	st.w $r17,addr_reg,0x44;\
	st.w $r18,addr_reg,0x48;\
	st.w $r19,addr_reg,0x4c;\
	st.w $r20,addr_reg,0x50;\
	st.w $r21,addr_reg,0x54;\
	st.w $r22,addr_reg,0x58;\
	st.w $r23,addr_reg,0x5c;\
	st.w $r24,addr_reg,0x60;\
	st.w $r25,addr_reg,0x64;\
	st.w $r26,addr_reg,0x68;\
	st.w $r27,addr_reg,0x6c;\
	st.w $r28,addr_reg,0x70;\
	st.w $r29,addr_reg,0x74;\
	st.w $r30,addr_reg,0x78;\
	st.w $r31,addr_reg,0x7c;\
	RESET_REGS_FUNC

# define REGS_LOAD_FUNC(addr_reg)\
	li.w addr_reg,REGS_SAVE_ADDR;\
	ld.w $r1,addr_reg,0x0;\
        ld.w $r2,addr_reg,0x4;\
	ld.w $r2,addr_reg,0x8;\
	ld.w $r3,addr_reg,0xc;\
	ld.w $r4,addr_reg,0x10;\
	ld.w $r5,addr_reg,0x14;\
	ld.w $r6,addr_reg,0x18;\
	ld.w $r7,addr_reg,0x1c;\
	ld.w $r8,addr_reg,0x20;\
	ld.w $r9,addr_reg,0x24;\
	ld.w $r10,addr_reg,0x28;\
	ld.w $r11,addr_reg,0x2c;\
	ld.w $r12,addr_reg,0x30;\
	ld.w $r13,addr_reg,0x34;\
	ld.w $r14,addr_reg,0x38;\
	ld.w $r15,addr_reg,0x3c;\
	ld.w $r16,addr_reg,0x40;\
	ld.w $r17,addr_reg,0x44;\
	ld.w $r18,addr_reg,0x48;\
	ld.w $r19,addr_reg,0x4c;\
	ld.w $r20,addr_reg,0x50;\
	ld.w $r21,addr_reg,0x54;\
	ld.w $r22,addr_reg,0x58;\
	ld.w $r23,addr_reg,0x5c;\
	ld.w $r24,addr_reg,0x60;\
	ld.w $r25,addr_reg,0x64;\
	ld.w $r26,addr_reg,0x68;\
	ld.w $r27,addr_reg,0x6c;\
	ld.w $r28,addr_reg,0x70;\
	ld.w $r29,addr_reg,0x74;\
	ld.w $r30,addr_reg,0x78;\
	ld.w $r31,addr_reg,0x7c;
#这样设置宏函数
#define RESET_REGS_FUNC add.w $r1,zero,zero;\
	add.w $r2,zero,zero;	add.w $r3,zero,zero;\
	add.w $r3,zero,zero;\
	add.w $r4,zero,zero;\
	add.w $r5,zero,zero;\
	add.w $r6,zero,zero;\
	add.w $r7,zero,zero;\
	add.w $r8,zero,zero;\
	add.w $r9,zero,zero;\
	add.w $r10,zero,zero;\
	add.w $r11,zero,zero;\
	add.w $r12,zero,zero;\
	add.w $r13,zero,zero;\
	add.w $r14,zero,zero;\
	add.w $r15,zero,zero;\
	add.w $r16,zero,zero;	add.w $r17,zero,zero;\
	add.w $r18,zero,zero;\
	add.w $r19,zero,zero;\
	add.w $r20,zero,zero;\
	add.w $r21,zero,zero;\
	add.w $r22,zero,zero;\
	add.w $r23,zero,zero;\
	add.w $r24,zero,zero;\
	add.w $r25,zero,zero;\
	add.w $r26,zero,zero;\
	add.w $r27,zero,zero;\
	add.w $r28,zero,zero;\
	add.w $r29,zero,zero;\
	add.w $r30,zero,zero;\
	add.w $r31,zero,zero;
#define LOAD_STORE_TEST(data_reg,max_times_reg,count_reg,base_addr_reg) add.w count_reg,zero,zero;\
loop:\
	addi.w data_reg,data_reg,0x1; \
	st.w data_reg,base_addr_reg,0x0;\
	ld.w data_reg,base_addr_reg,0x0;\
	addi.w base_addr_reg,base_addr_reg,0x4;\
	addi.w count_reg,count_reg,0x1;\
	bge max_times_reg,count_reg,loop
#define SET_CACHE_CONSISTENCY(reg) addi.w reg,$r0,40;\
	csrwr reg,0;\
	add.w reg,zero,zero;
#define DIV_ILLEGALITY(dividend_reg,divisor_reg,consult_reg,remainder_reg,max_time_reg) add.w divisor_reg,zero,zero;\
	addi.w max_time_reg,zero,0x1ff;\
	addi.w dividend_reg,zero,0xff;\
	div.w consult_reg,dividend_reg,divisor_reg;\
	loop_div_mod:\
	addi.w  divisor_reg,divisor_reg,0x1;\
	div.w consult_reg,dividend_reg,divisor_reg;\
	mod.w remainder_reg,dividend_reg,divisor_reg;\
	bne divisor_reg,max_time_reg,loop_div_mod;\
	add.w divisor_reg,zero,zero; loop_div_mod_u:	addi.w divisor_reg,divisor_reg,0x1;\
	div.wu consult_reg,dividend_reg,divisor_reg;\
	mod.wu remainder_reg,dividend_reg,divisor_reg;\
	bltu max_time_reg,divisor_reg,loop_div_mod_u;

#define IDLE_FUNC\
	loop_idle:\
	b loop_idle
