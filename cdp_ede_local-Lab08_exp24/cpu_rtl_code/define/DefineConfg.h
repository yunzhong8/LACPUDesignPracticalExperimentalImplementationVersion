`ifndef DEFINECONFG
`define DEFINECONFG
//CPU配置文件
//1表示开启双发是
`define double_launch 1

//调试配置文件
//1表示用zzq设置的正确轨迹进行对比测试,0表示源代码的测试集
`define use_zzq_test  0
//1表示关闭对比测试，0表示开启对比测试
`define close_trace_compare  1

//1表示当前记录的是正确运行的轨迹，0表示当前记录的轨迹是要进行测试的
`define record_right_trace 0 


//1:表示轨迹记录是最简单的结构
`define simply_trace_record_open 1
`define whole_trace_record_open 1

//轨迹保存路径
//待比对的轨迹
  //最简单的记录方式
//`define Test_TRACE_WRITE_FILE "/home/ysyx/LoogArch/LoongArch_Trace_record/test_trace/ZzqTest/test_jmp.txt"
//`define Test_TRACE_WRITE_FILE "/home/ysyx/LoogArch/LoongArch_Trace_record/test_trace/ZzqTest/random.txt"
`define Test_TRACE_WRITE_FILE "/home/ysyx/LoogArch/LoongArch_Trace_record/test_trace/ZzqTest/point72_simply.txt"

//复杂全面的记录方式
`define Test_TRACE_WRITE_FILE_WHOLE "/home/ysyx/LoogArch/LoongArch_Trace_record/test_trace/ZzqTest/point72_whole.txt"


//ZZQ正确轨迹路径
//`define RIGHT_TRACE_WRITE_FILE "/home/ysyx/LoogArch/LoongArch_Trace_record/right_trace/FuncTest/point72.txt"
//`define RIGHT_TRACE_WRITE_FILE  "/home/ysyx/LoogArch/LoongArch_Trace_record/right_trace/ZzqTest/test_jmp.txt"
`define RIGHT_TRACE_WRITE_FILE  "/home/ysyx/LoogArch/LoongArch_Trace_record/right_trace/ZzqTest/random.txt"


//trace比对正确轨迹的路径，
//官方
//`define TRACE_REF_FILE "/home/ysyx/LoogArch/LoongArch_Trace_record/official_right_trace/golden_trace.txt"
`define TRACE_REF_FILE  "/home/ysyx/perf_test-la32r/soft/func_gettrace/golden_trace.txt"


//在zzq路径
`define ZZQ_TRACE_REF_FILE "/home/ysyx/LoogArch/LoongArch_Trace_record/right_trace/ZzqTest/test_jmp.txt"
`endif 
