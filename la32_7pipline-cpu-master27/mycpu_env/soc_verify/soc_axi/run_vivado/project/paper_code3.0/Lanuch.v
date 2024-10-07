/*
*作者：zzq
*创建时间：2023-04-21
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*
*/
/*************\
bug:考虑到forward的位置我未来会改（发射级和译码级分开）所以我打算将datarelate进行解耦，将其放流水线中
2. assign 写成wire则导致赋值无效生成z
3.跳转指令和单双发组合漏洞，if line1跳转，line2是访问指令
4.没有考虑阻塞的情况，当line1被阻塞，line2没有被阻塞的时候，line2的指令不能向下传导，必须line1执行的顺序一定要大于line2，这个我一直没有考虑，真恐怖这个还通过测试啦
5。对发射信号的含义没有明确清楚，zero:表示当前指令没有发出去
\*************/
`include "DefineModuleBus.h"

module Lanuch(
   //时钟
    input  wire                         clk                           ,
    input  wire                         rst_n                         ,
    
    //握手
    input  wire                         next_allowin_i               ,
    input  wire                         line1_pre_to_now_valid_i     ,
    input  wire                         line2_pre_to_now_valid_i     ,
    
    output wire                         line1_now_to_next_valid_o    ,
    output wire                         line2_now_to_next_valid_o    ,
    output wire                         now_allowin_o                ,//缓存队列是否允许输入
    //冲刷
    input wire excep_flush_i,
    
    //数据
    input  wire [`IdToNextBusWidth]       pre_to_ibus               ,
    input  wire [`RegsRigthReadBusWidth]  regs_rigth_read_ibus      ,//输入寄存器读出数据         
    input  wire [63:0]                    cout_to_ibus              ,    
    
  
    output wire  [`RegsReadIbusWidth]     regs_raddr_obus           ,
    output wire  [`LaunchToNextBusWidth]  to_next_obus  
    
    
);

/***************************************input variable define(输入变量定义)**************************************/
//线级变量
wire [`LineRegsRigthReadBusWidth]line2_regs_rigth_read_ibus,line1_regs_rigth_read_ibus;


/***************************************output variable define(输出变量定义)**************************************/

//线级
wire [`LineLaunchToNextBusWidth] line2_to_next_obus,line1_to_next_obus;
wire [`LineRegsReadIbusWidth]line2_to_rfb_obus,line1_to_rfb_obus;

wire banch_flush_o;

/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
//IDStage使用
//寄存器堆写
wire                      line2_regs_we_o,line1_regs_we_o;//寄存器组写使能
wire [`RegsAddrWidth]     line2_regs_waddr_o,line1_regs_waddr_o;//寄存器写地址

wire [`IdToNextBusWidth]pre_to_bus;
wire [`LineIdToNextBusWidth]line2_pre_to_bus,line1_pre_to_bus;


//跳转信号
wire                   line2_jmp_flag,line1_jmp_flag;//跳转标志
wire [`PcWidth]        line2_jmp_addr,line1_jmp_addr;//跳转转地址


//跳转冲刷信号
wire branch_flush;
//发射信号
wire  double_valid_inst_lunch_flag;
wire  single_valid_inst_lunch_flag;
wire  zero_valid_inst_lunch_flag;

//IFID
wire line2_now_valid,line1_now_valid;
wire [`IdToNextBusWidth]pre_to_id_bus;

//ID
wire line2_inst_is_mem,line1_inst_is_mem;
wire line2_regs_re2_o,line2_regs_re1_o;
wire [`LineLaunchToPreBusWidth]line2_to_pre_obus,line1_to_pre_obus;

//refgs
wire [`RegsAddrWidth]line2_regs_raddr1,line2_regs_raddr2;
wire line2_regs_we,line1_regs_we;
wire [`RegsAddrWidth]line2_regs_waddr,line1_regs_waddr;
wire [5:0]line2_wregs_bus,line1_wregs_bus;
wire [`PcWidth] line1_pc;



//发射级两条指令相关性
wire line2_relate_line1;
wire line2_want_done_en_o,line1_want_done_en_o;

//握手
wire line2_now_allowin,line1_now_allowin;
wire line2_now_to_next_valid,line1_now_to_next_valid;
//发射级是否允许队列输入
wire lunch_allowin;
//表示lunch阶段的组合逻辑把事情做完了
wire now_allowin;
/****************************************input decode(输入解码)***************************************/
assign {line2_regs_rigth_read_ibus,line1_regs_rigth_read_ibus} = regs_rigth_read_ibus ;
assign line1_pc = line1_pre_to_bus[63:32];
/****************************************output code(输出解码)***************************************/

assign to_next_obus    = {line2_to_next_obus,line1_to_next_obus};
//访问rfb
assign regs_raddr_obus = {line2_to_rfb_obus,line1_to_rfb_obus};


/****************************************output code(内部解码)***************************************/
assign {line1_regs_we,line1_regs_waddr} = line1_wregs_bus;
assign {line2_regs_we,line2_regs_waddr} = line2_wregs_bus;
assign {line2_pre_to_bus,line1_pre_to_bus} = pre_to_bus;
assign {line2_regs_re2_o,line2_regs_raddr2,line2_regs_re1_o,line2_regs_raddr1} = line2_to_rfb_obus;


/*******************************complete logical function (逻辑功能实现)*******************************/

IF_ID IFIDI(
        .rst_n(rst_n),
        .clk(clk),
        
        
        //握手                                                     
        .line1_pre_to_now_valid_i(line1_pre_to_now_valid_i),     
        .line2_pre_to_now_valid_i(line2_pre_to_now_valid_i),     
        .now_allowin_i(now_allowin),                           
                                                                 
        .line1_now_valid_o(line1_now_valid),                     
        .line2_now_valid_o(line2_now_valid),                     
         //冲刷                                                        
        .branch_flush_i     (branch_flush),
        .excep_flush_i      (excep_flush_i),  
        //发射状况   
        .double_valid_inst_lunch_flag_i( double_valid_inst_lunch_flag  ),  
        .single_valid_inst_lunch_flag_i( single_valid_inst_lunch_flag  ),  
        .zero_valid_inst_lunch_flag_i  ( zero_valid_inst_lunch_flag    ),    
        
               
                                      
        //数据域                                                
        .pre_to_ibus(pre_to_ibus), 
        .allowin_o(now_allowin_o),
        
        .to_id_obus(pre_to_bus)         
       
         
    );
                   

ID IDI1(
        .rst_n (rst_n),
        //握手
        .next_allowin_i(next_allowin_i),
        .now_valid_i(line1_now_valid),
        
        .now_allowin_o(line1_now_allowin),
        .now_to_next_valid_o(line1_now_to_next_valid),
        
        .excep_flush_i(excep_flush_i),
        
        //数据域
        .pre_to_ibus(line1_pre_to_bus),
        .regs_rigth_read_ibus(line1_regs_rigth_read_ibus),
        .cout_to_ibus(cout_to_ibus ),
        
        .want_done_en_o      (line1_want_done_en_o),
        .wregs_obus          (line1_wregs_bus),
        //.to_pre_obus          (line1_to_pre_obus),
        .to_next_obus        (line1_to_next_obus),
        
        
        .to_rfb_obus         (line1_to_rfb_obus)
    );
   
    
    
    
  ID IDI2(
        .rst_n (rst_n),
        //握手
        .next_allowin_i(next_allowin_i),
        .now_valid_i(line2_now_valid),
        
        .now_allowin_o(line2_now_allowin),
        .now_to_next_valid_o(line2_now_to_next_valid),
  
        .excep_flush_i(excep_flush_i),
        
        //数据域
        .pre_to_ibus(line2_pre_to_bus),
        .regs_rigth_read_ibus(line2_regs_rigth_read_ibus),
        .cout_to_ibus(cout_to_ibus ),
        
        .want_done_en_o         (line2_want_done_en_o)   ,
        .wregs_obus             (line2_wregs_bus)        ,
        //.to_pre_obus            (line2_to_pre_obus)       ,
        .to_next_obus           (line2_to_next_obus)  ,
        
        
             
        .to_rfb_obus            (line2_to_rfb_obus)
    );

//两条指令相关性检查
//line1写使能有效,且写地址~=0,且(line1写地址==line2的读地址1或者line1的写地址==line2的读地址2) then两条指令出现相关
assign line2_relate_line1 = ( (line1_regs_we == `WriteEnable) && (line1_regs_waddr!=0) && 
                               ( (line1_regs_waddr ==line2_regs_raddr1 && line2_regs_re1_o) || (line1_regs_waddr ==line2_regs_raddr2 && line2_regs_re2_o) ) ) ? 1'b1 : 1'b0;


//发射仲裁
   //发射的前提是当前两条流水线都允许输入
   //默认了line2有值就是有效的，line1有指令就是有效的
   //line1跳转则双发射
   //line2有效&&line2不是除法，访存指令||line2无效，表示line2渴望被双发射执行，if没有和line1发生相关，则双发
   //有效且是访问，除法指令则不能双发
   //line1允许输入,且line1是跳转指令,且预测正确
  
   //表示当前指令没有没发射走，（包含：当前时钟周期有指令，但是被阻塞了，当前时钟周期的的指令为空）                        
   assign zero_valid_inst_lunch_flag = ~double_valid_inst_lunch_flag &~single_valid_inst_lunch_flag;
   //表示当前阶段的两条指令在本个时钟周期结束就要被发走了
   assign double_valid_inst_lunch_flag =   (line1_now_valid &line2_now_valid &now_allowin) ? (line2_want_done_en_o?  (line2_relate_line1   ? 1'b0 :1'b1) : 1'b0):1'b0;
   
   assign single_valid_inst_lunch_flag = (line1_now_valid &~line2_now_valid &now_allowin) ? 1'b1 :
                              (line1_now_valid &line2_now_valid &now_allowin) ?(line2_want_done_en_o?  (line2_relate_line1   ? 1'b1 :1'b0) : 1'b1):1'b0;

//冲刷信号
    assign  branch_flush  = 1'b0 ;
    assign  banch_flush_o = 1'b0 ;


//握手
//当两条流水线都完成工作的时候才允许往下传递线级的now_allowin
assign now_allowin = line2_now_allowin && line1_now_allowin;


assign line1_now_to_next_valid_o = line1_now_to_next_valid && now_allowin;
//第二条流水线数据有效的条件:line1没有发生跳转，当前是双发射状态
assign line2_now_to_next_valid_o = double_valid_inst_lunch_flag ? line2_now_to_next_valid :1'b0;



endmodule
