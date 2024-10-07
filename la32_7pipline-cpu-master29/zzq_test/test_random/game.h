#数据
#include "regdef.h"
#define  VIDEO_BASE_ADDR 0xafb00000
#define  VIDEO_MAX_OFFEST_ADDR 1200*4
#define  EMPTY_MAX   0x00f000
#define GAME_BACKGROUND_COLOR 0x09 #黑色
#define GAME_EDGE_COLOR  0x007#蓝色
#define SNAKE_COLOR 0x380#红色
#define BALL_COLOE 0x038#绿色
#define EDGE_LEN 80
#define EDGE_WIDTH 60
#define SNAKE_X 20
#define SNAKE_Y 20
#define BALL_X 30
#define BALL_Y 30
#define SCORE 0
#define CPU_EMPTY_NUM 0x00fff000
#define SNAKE_LEN 1
#define SNAKE_DIRECTION 1
#define SNAKE_SPEED 1
#define QUEUE_ADDR 0x100
#define QUEUE_MAx_ADDR 0x200
####地址
#define GAME_EDGE_COLOR_DATAADDR 0x00
#define GAME_BACKGROUND_COLOR_DATAADDR 0x02
#define SNAKE_COLOR_DATAADDR 0x04
#define BALL_COLOR_DATAADDR 0x06
#define EDGE_LEN_DATAADDR 0x08
#define EDGE_WIDTH_DATAADDR 0xc
#define SNAKE_X_DATAADDR 0x10
#define SNAKE_Y_DATAADDR 0x12
#define BALL_X_DATAADDR 0x14
#define BALL_Y_DATAADDR 0x16
#define SCORE_DATAADDR 0x20
#define VIDEO_BASE_ADDR_DATAADDR 0x24
#define VIDEO_MAX_ADDR_DATAADDR 0x28
#define CPU_EMPTY_NUM_DATAADDR 0x2c
#define SNAKE_LEN_DATAADDR 0x30
#define SNAKE_DIRECTION_DATAADDR 0x34
#define QUEUE_ADDR_DATAADDR 0x38
#define QUEUE_MAx_ADDR_DATAADDR 0x3c
#define EXCEPT_ENTRY_ADDR_DATAADDR 0x40
#define NIXIE_TUBE_DATA_ADDR_DATAADDR 0x44
#define CPU_EMPTY_TIME_DATAADDR 0x48
##临时数据保存堆
#define TEMP_DATA_SAVE_ADDR_DATAADDR 0x400

##函数
#define snake_move_update_func(snake_x_reg,snak_y_reg,snake_diction_reg,snake_speed_reg,temp_diction_reg) \
addi.w snake_speed_reg,zero,SNAKE_SPEED \
add.w temp_diction_reg,zero,zero; \
addi.w  temp_diction_reg,zero,1; \
beq snake_diction_reg,temp_diction_reg,move_up; \
addi.w temp_diction_reg,zero,1; \
beq snake_diction_reg,temp_diction_reg,move_down; \
addi.w temp_diction_reg,zero,1; \
beq snake_diction_reg,temp_diction_reg,move_left; \
addi.w temp_diction_reg,zero,1; \
beq snake_diction_reg,temp_diction_reg,move_right; \
move_up:; \
add.w snake_y_reg,snake_x_reg,snake_speed_reg; \
b move_over; \
move_down:; \
sub.w snake_y_reg,snake_x_reg,snake_speed_reg; \
b move_over; \
move_left:; \
sub.w snake_x_reg,snake_x_reg,snake_speed_reg; \
b move_over; \
move_right:; \
add.w snake_x_reg,snake_x_reg,snake_speed_reg; \
b move_over; \
move_over: 

