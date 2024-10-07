-makelib ies_lib/xpm -sv \
  "/home/ysyx/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "/home/ysyx/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib ies_lib/xpm \
  "/home/ysyx/Xilinx/Vivado/2019.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../../../rtl/xilinx_ip/axi_ram/simulation/blk_mem_gen_v8_4.v" \
  "../../../../../../rtl/xilinx_ip/axi_ram/sim/axi_ram.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

