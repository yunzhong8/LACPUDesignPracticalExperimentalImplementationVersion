# 
# Synthesis run script generated by Vivado
# 

set TIME_start [clock seconds] 
proc create_report { reportName command } {
  set status "."
  append status $reportName ".fail"
  if { [file exists $status] } {
    eval file delete [glob $status]
  }
  send_msg_id runtcl-4 info "Executing : $command"
  set retval [eval catch { $command } msg]
  if { $retval != 0 } {
    set fp [open $status w]
    close $fp
    send_msg_id runtcl-5 warning "$msg"
  }
}
set_param chipscope.maxJobs 3
set_msg_config -id {Common 17-41} -limit 10000000
create_project -in_memory -part xc7a200tfbg676-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_msg_config -source 4 -id {IP_Flow 19-2162} -severity warning -new_severity info
set_property webtalk.parent_dir /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/run_vivado/project/loongson.cache/wt [current_project]
set_property parent.project_path /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/run_vivado/project/loongson.xpr [current_project]
set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property ip_output_repo /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/run_vivado/project/loongson.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/func/obj/inst_ram.coe
add_files /home/ysyx/zzq/Code/AssemblerLangugae/test_jmp/inst_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/zzq_test/test_jmp/inst_ram.coe
add_files /home/ysyx/LoogArch/loongarch_test/loongarch_test/func_point72/func/obj/inst_ram.coe
add_files /home/ysyx/LoogArch/loongarch_test/zzq_test/test_random/inst_ram.coe
add_files /home/ysyx/LoogArch/loongarch_test/zzq_test/test_idle/inst_ram.coe
add_files /home/ysyx/LoogArch/loongarch_test/zzq_test/test_cacop/inst_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/func_test/func/obj/inst_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/perf_func/obj/select_sort/axi_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/perf_func/obj/allbench/axi_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/perf_func/obj/stringsearch/axi_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/perf_func/obj/sha/axi_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/perf_func/obj/quick_sort/axi_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/perf_func/obj/dhrystone/axi_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/perf_func/obj/crc32/axi_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/perf_func/obj/bubble_sort/axi_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/perf_func/obj/bitcount/axi_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/perf_func/obj/coremark/axi_ram.coe
add_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/offical_test/perf_func/obj/stream_copy/axi_ram.coe
read_verilog {
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineBJSign.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineExSign.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineIdSign.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineWbSign.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineInstSign.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineMemSign.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineCsrAddr.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineExcepSign.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineAluOp.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineModuleBus.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineConfg.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineSignLocation.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineLoogLenWidth.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineCache.h
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineError.h
}
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineBJSign.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineExSign.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineIdSign.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineWbSign.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineInstSign.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineMemSign.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineCsrAddr.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineExcepSign.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineAluOp.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineModuleBus.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineConfg.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineSignLocation.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineLoogLenWidth.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineCache.h]
set_property file_type "Verilog Header" [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/DefineError.h]
read_mem /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/xilinx_ip/axi_ram/axi_ram.mif
read_verilog -library xil_defaultlib {
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/define.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Arith_Logic_Unit.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Branch_Unit.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Cdo.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/CdoCb.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/CdoSq.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/CountReg.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Csr.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Data_Relevant.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Div.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/EX.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/EX_MEM.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Error.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/ExStage.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/ID.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/ID_EX.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/IF.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/IF_ID.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/IdCb.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/IdSq.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/IdStage.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/IfStage.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/IfTCb.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/IfTSq.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/IfTStage.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/IndetifyInstType.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Lanuch.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Loog.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/MEM.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/MEM_WB.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/MMCb.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/MMSq.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/MMStage.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/MemStage.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Mmu.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/OpDecoder.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/PreIF.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Predactor.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Predactor_Btb.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Predactor_PUC.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Predactor_Pht.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/PreifReg.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Preif_IF.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Queue.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Reg_File.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/Reg_File_Box.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/SignProduce.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/TlbGroup.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/WB.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/WbStage.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/axi_wrap/axi_wrap.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/ram_wrap/axi_wrap_ram.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/cache.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/cache_table.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/cache_way.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/CONFREG/confreg.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/mycpu_cache_top.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/mycpu_top.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/sramaixbridge.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/tlb.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/tools.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/rtl_code/wallace_mul.v
  /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/soc_lite_top.v
}
read_ip -quiet /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/xilinx_ip/clk_pll/clk_pll.xci
set_property used_in_implementation false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/xilinx_ip/clk_pll/clk_pll_board.xdc]
set_property used_in_implementation false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/xilinx_ip/clk_pll/clk_pll.xdc]
set_property used_in_implementation false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/xilinx_ip/clk_pll/clk_pll_ooc.xdc]

read_ip -quiet /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/xilinx_ip/axi_ram/axi_ram.xci
set_property used_in_implementation false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/xilinx_ip/axi_ram/axi_ram_ooc.xdc]

read_ip -quiet /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/axi_clock_converter/axi_clock_converter.xci
set_property used_in_synthesis false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/axi_clock_converter/axi_clock_converter_clocks.xdc]
set_property used_in_implementation false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/axi_clock_converter/axi_clock_converter_clocks.xdc]
set_property used_in_implementation false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/axi_clock_converter/axi_clock_converter_ooc.xdc]

read_ip -quiet /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/data_bank/data_bank.xci
set_property used_in_implementation false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/data_bank/data_bank_ooc.xdc]

read_ip -quiet /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/tagv_ram/tagv_ram.xci
set_property used_in_implementation false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/tagv_ram/tagv_ram_ooc.xdc]

read_ip -quiet /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/xilinx_ip/axi_crossbar_1x2/axi_crossbar_1x2.xci
set_property used_in_implementation false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/xilinx_ip/axi_crossbar_1x2/axi_crossbar_1x2_ooc.xdc]

read_ip -quiet /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/pht_ram/pht_ram.xci
set_property used_in_implementation false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/pht_ram/pht_ram_ooc.xdc]

read_ip -quiet /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/btb_ram/btb_ram.xci
set_property used_in_implementation false [get_files -all /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/rtl/myCPU/IP/btb_ram/btb_ram_ooc.xdc]

# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}
read_xdc /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/run_vivado/constraints/soc_lite_top.xdc
set_property used_in_implementation false [get_files /home/ysyx/zzq/cdp_ede_local-Lab08_exp23/mycpu_env/soc_verify/soc_axi/run_vivado/constraints/soc_lite_top.xdc]

read_xdc dont_touch.xdc
set_property used_in_implementation false [get_files dont_touch.xdc]
set_param ips.enableIPCacheLiteLoad 1
close [open __synthesis_is_running__ w]

synth_design -top soc_axi_lite_top -part xc7a200tfbg676-1


# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_checkpoint -force -noxdef soc_axi_lite_top.dcp
create_report "synth_1_synth_report_utilization_0" "report_utilization -file soc_axi_lite_top_utilization_synth.rpt -pb soc_axi_lite_top_utilization_synth.pb"
file delete __synthesis_is_running__
close [open __synthesis_is_complete__ w]
