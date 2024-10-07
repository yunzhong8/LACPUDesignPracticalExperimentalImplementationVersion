1. cache文件夹是cache代码
2. cpu_code是主要代码
3. Predict是分支预测器件的代码
4. zzq_design_ip是我自己设计通用代码模块
5. define 是宏定义文件
本文件仅为副本，主体在mycpu_env/soc_verify/soc_axi/rtl/myCPU
vivado项目使用的项目代码就是./mycpu_env/soc_verify/soc_axi/rtl/myCPU中代码

mv Define* ../../define/
mv define.v ../../define/
mv Mmu.v tlb.v TlbGroup.v ../../mmu/
mv Predactor* ../../Predict/
mv diff.v ../../zzq_design_ip/Diff/
