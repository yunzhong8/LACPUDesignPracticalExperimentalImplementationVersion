/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：
*
*/
/*************\
bug:
1. mem阶段的例外信号有没有效果，有个前提是必须mem阶段数据不为空
2. mem因为携带例外信号要暂停exe阶段，前提：mem阶段数据不为空，我都没考虑，导致错误
3. 考虑到根据当前阶段是否数据有效去修改excep_type成本太大了，要加好多个比较器，所以引入excep_en信号，用于控制，减少资源消耗
4. 由于wb级不可能发生阻塞，所以不存在需要缓存data_ram的读出数据的情况，mem级不需要知道携带例外信息的指令是不是访存指令
5. store指令需要看data_ok,(这里可以对data_ok含义进行修改为:出现data_ok表明要写的内容一定在cache中了(不命中就等到回填结束))
3. mem_req_o信号关闭的仅在当前级为空才能关
\*************/
//`include "DefineModuleBus.h"
`include "define.v"
module MMCb(

    input wire                            next_allowin_i,//输入ex已经完成当前数据了,允许你清除id_ex锁存器中的数据，将新数据给ex执行，1为允许,由ex传入
    input wire                            now_valid_i, //ID阶段流水是空的，没有要执行的数据，1为有效 ，由id_ex传入,
    
    //
    output wire                           now_allowin_o,//传给if，和id_exe,id阶段已经完成数据，允许你清除if_id锁存器内容
    output wire                           now_to_next_valid_o,//传给exe_mem，id阶段已经完成当前数据，想要将运算结果写入id_ex锁存器中，
    input  wire                           excep_flush_i,
    
    input  wire [`LineExToNextBusWidth]    pre_to_ibus       ,
   
    input  wire [`MmuToMemBusWidth]       mmu_to_ibus,
    
     output wire                          store_buffer_ce_o             ,
    output wire                           now_clk_pre_cache_req_o       , 
    output wire [`LineMemForwardBusWidth] forward_obus,
    output wire                           to_pre_obus,
    
    output wire [`LineMmToNextBusWidth]   to_next_obus ,
    output wire [`MemToMmuBusWidth]       to_mmu_obus            
);

/***************************************input variable define(输入变量定义)**************************************/
 wire [`PcWidth]pc_i;
 wire [`InstWidth]inst_i; 
  
  
    //存储器
         wire                           mem_req_i ;
         wire                           mem_we_i; 
         wire [`spMemRegsWdataSrcWidth] mem_regs_wdata_src_i;
         wire [`spMemMemDataSrcWidth]   mem_mem_data_src_i;
         wire [`MemAddrWidth]           mem_rwaddr_i   ;
    //寄存器组
         wire[`RegsAddrWidth]           regs_waddr_i;
         wire                           regs_we_i;
         wire [`RegsDataWidth]          regs_wdata_i;
         wire  [`RegsDataWidth]         regs_rdata1_i;
         wire  [`RegsDataWidth]         regs_rdata2_i;
    //csr  
      wire is_kernel_inst_i,wb_regs_wdata_src_i;    
      wire csr_wdata_src_i;                         
      wire csr_raddr_src_i;                 
      wire csr_we_i;                        
      wire [`CsrAddrWidth]csr_waddr_i;      
      wire [`RegsDataWidth]csr_wdata_i;     
   //llbit                               
      wire llbit_we_i;                      
      wire llbit_wdata_i;      
    //tlb
     wire tlbidx_found_o;
     wire tlbidx_ne_o;
     wire [`TlbIndexWidth]tlbidx_index_o;
     wire [1:0]tlb_search_type_i;
     wire tlb_re_i         ; 
     wire tlb_se_i         ;
     wire tlb_ie_i         ; 
     wire tlb_we_i         ; 
     wire tlb_fe_i          ;
     wire [4:0]tlb_op_i     ;   
                     
    //例外                                          
         wire [`ExceptionTypeWidth]excep_type_i;    
         wire excep_en_i;   
         wire tlb_error_i;    
          wire tlb_adem_i;   
      wire refetch_flush_i; 
     //cache
        wire sotre_buffer_we_i;  
        wire uncache_i;     
        wire idle_en_i,cacop_en_i;
        wire [4:0]cacop_code_i;  
        
        
        
     //跳转冲刷
        wire branch_flush_i;
        wire [`PcWidth]jmp_addr_i;           

/***************************************output variable define(输出变量定义)**************************************/
    //存储器
         wire mem_req_o;
         wire mem_we_o;
         wire [`MemAddrWidth]mem_rwaddr_o;
         reg [3:0]mem_rwsel_o;
        //物理地址
         wire [`MemDataWidth]p_mem_rwaddr_i;
        
        
    //寄存器组
         wire regs_we_o;
         wire[`RegsAddrWidth]regs_waddr_o;
         wire[`RegsDataWidth] regs_wdata_o;
     //csr
      wire csr_raddr_src_o;
      wire csr_we_o;
      wire [`CsrAddrWidth]csr_waddr_o;
      wire [`RegsDataWidth]csr_wdata_o;
    //llbit
      wire llbit_we_o;
      wire llbit_wdata_o;  
     //tlb
    
     wire tlb_re_o         ; 
     wire tlb_se_o         ;
     wire tlb_ie_o         ; 
     wire tlb_we_o         ; 
     wire tlb_fe_o         ;
     wire [4:0]tlb_op_o     ; 
    //例外信号                                                          
         wire [`ExceptionTypeWidth] excep_type_o; 
         wire excep_en_o;  
    //相关检测器要求暂停
      wire dr_stall_o;
     //cache
        wire sotre_buffer_we_o; 
        wire [19:0]p_tag_o;//物理标记地址  
        wire idle_en_o,cacop_en_o;
        //表明当前指令是uncache,如果是load指令则执行填充,如果store指令则写入到sotre_buffer中      
        wire refetch_flush_o;
        wire uncache_o;
        wire cache_refill_valid_o;
     
        
    
/***************************************parameter define(常量定义)**************************************/
wire [`ExToDiffBusWidth] ex_to_diff_ibus;


wire [`MmToDiffBusWidth] mm_to_diff_obus;
/***************************************inner variable define(内部变量定义)**************************************/
wire now_ctl_valid;
wire now_ctl_base_valid;
wire excep_en;

 wire [1:0] mem_rwaddr_low2;
 
 //tlb例外
 wire tlb_memr_excep_i    ;
 wire tlb_pil_excep_i     ;
 wire tlb_pis_excep_i     ;
 
 wire tlb_pme_excep_i     ;
 wire tlb_ppi_excep_i ;
 //握手信号
 wire now_ready_go;
 
/****************************************input decode(输入解码)***************************************/
 assign   { 
           ex_to_diff_ibus,
           idle_en_i,cacop_en_i,cacop_code_i,
           branch_flush_i,jmp_addr_i,
           refetch_flush_i,sotre_buffer_we_i,
           tlb_fe_i,tlb_se_i,tlb_re_i,tlb_we_i,tlb_ie_i,
           tlb_op_i,tlb_search_type_i,
           is_kernel_inst_i,
           csr_wdata_src_i,regs_rdata1_i,regs_rdata2_i,
           excep_en_i,excep_type_i,
           llbit_we_i,llbit_wdata_i,                                  
           csr_raddr_src_i,csr_we_i,csr_waddr_i,csr_wdata_i,//csr写使能  
           mem_regs_wdata_src_i,mem_mem_data_src_i,mem_req_i,mem_we_i,mem_rwaddr_i,
           wb_regs_wdata_src_i,regs_we_i,regs_waddr_i,regs_wdata_i,
           pc_i,inst_i} = pre_to_ibus;

assign {uncache_i,
            tlb_error_i,tlb_adem_i,tlb_memr_excep_i,tlb_pil_excep_i,tlb_pis_excep_i,tlb_pme_excep_i,tlb_ppi_excep_i,//1+6=7+1=8
             p_mem_rwaddr_i[`PcWidth],tlbidx_found_o,tlbidx_index_o,tlbidx_ne_o} = mmu_to_ibus;//32++4+2=38
/****************************************output code(输出解码)***************************************/
assign to_next_obus= {
                      mm_to_diff_obus,
                      idle_en_o,cacop_en_o,cacop_code_i,
                      cache_refill_valid_o,uncache_o,p_tag_o,  
                      branch_flush_o,jmp_addr_i,
                      refetch_flush_o,sotre_buffer_we_o,
                      tlb_fe_o,tlb_se_o,tlb_re_o,tlb_we_o,tlb_ie_o,
                      tlb_op_o,tlbidx_found_o,tlbidx_ne_o,tlbidx_index_o,
                      is_kernel_inst_i,csr_wdata_src_i,regs_rdata1_i,regs_rdata2_i,
                      excep_en_o,excep_type_o,
                      llbit_we_o,llbit_wdata_o,                                 
                      csr_raddr_src_o,csr_we_o,csr_waddr_o,csr_wdata_o,//csr写使能 32+20
                      mem_regs_wdata_src_i,mem_mem_data_src_i,mem_req_o,mem_we_o,mem_rwaddr_i,//32+1+1+1=35
                      wb_regs_wdata_src_i,regs_we_o,regs_waddr_o,regs_wdata_o,//32+5+1+1=39
                      pc_i,inst_i};//64
                      
//assign forward_obus={                                                                      
//                     regs_we_o,regs_waddr_o,regs_wdata_o,
//                     dr_stall_o};
assign forward_obus={                                                                      
                     regs_we_i&now_ctl_base_valid,regs_waddr_o,regs_wdata_o,
                     dr_stall_o};
//使用了forward机制不再需要阻塞exe级了
assign to_pre_obus   = 1'b0;
assign to_mmu_obus             = {tlb_search_type_i,mem_rwaddr_o} ;
assign store_buffer_ce_o       = mem_we_i&mem_req_i&excep_flush_i;
assign now_clk_pre_cache_req_o = mem_req_o;
/*******************************complete logical function (逻辑功能实现)*******************************/
  //forward
  //当前指令是在wb阶段写入的，且数据有效，要求暂停，当前指令是访存指令，但是数据还没有读出则要求暂停
  assign dr_stall_o =  now_valid_i & (wb_regs_wdata_src_i | (mem_req_i & (~mem_we_i)) );
  //寄存器组
    assign regs_we_o    = regs_we_i & now_ctl_valid;//因为有forward，所以可能无效要立马实现，we--i=1&&当前数据有效，we_o=1
    assign regs_waddr_o = regs_waddr_i;  
    assign regs_wdata_o = regs_wdata_i;

    assign mem_rwaddr_low2 = mem_rwaddr_i[1:0];
   
   

//存储器  
    //携带了例外信息不能关闭该信号，因为这个有用于store_buffer清空，表示该指令是发过cache访问请求的，在mem阶段也许判断当前指令是否发过请求，
    //本级携带上了例外信息但是指令在exe阶段发过cache请求，所以mem_req_o不能关闭
    //本级接收到了冲刷信号也不能关闭mem_req_o，因为其也在exe阶段发过请求
    assign  mem_req_o        = mem_req_i&now_valid_i;
    assign  mem_we_o         = mem_we_i & now_ctl_valid;//写使能    
    assign  mem_rwaddr_o     = mem_rwaddr_i; 
 //cache
    //本级store_buffer_we_o有效的前提:本机的store指令有效,now_clk没有收到冲刷信号,now_inst没有携带例外信息
    assign sotre_buffer_we_o = sotre_buffer_we_i & now_ctl_valid;
    assign p_tag_o           = p_mem_rwaddr_i[31:12];
    //访问存指令的uncach属性有效前提
    //当前访存指令有效,当前指令没有携带例外信息,当前没有收到例外冲刷
    assign uncache_o = uncache_i & now_ctl_valid;
    //重填有效,当前指令没有出现例外,当前指令没有收冲刷信号 
    assign cache_refill_valid_o =  now_ctl_valid;
 //csr
    assign csr_raddr_src_o =  csr_raddr_src_i; 
    assign csr_we_o        =  csr_we_i & now_ctl_valid;        
    assign csr_waddr_o     =  csr_waddr_i;     
    assign csr_wdata_o     =  csr_wdata_i;     
    //llbit                                    
    assign llbit_we_o      =   llbit_we_i & now_ctl_valid;       
    assign llbit_wdata_o   =  llbit_wdata_i;  
 //TLB   
    assign tlb_re_o = tlb_re_i & now_ctl_valid;
    assign tlb_se_o = tlb_se_i & now_ctl_valid;
    assign tlb_ie_o = tlb_ie_i & now_ctl_valid;
    assign tlb_we_o = tlb_we_i & now_ctl_valid;
    assign tlb_fe_o = tlb_fe_i & now_ctl_valid;
    assign tlb_op_o = tlb_op_i;
   //idle
     assign idle_en_o =  idle_en_i&now_ctl_valid;
     //cache
     assign cacop_en_o= cacop_en_i&now_ctl_valid;
     
    
    
     //例外
     assign excep_type_o[`IntLocation]                 = excep_type_i[`IntLocation] ; //0
     assign excep_type_o[`PilLocation]                 = tlb_pil_excep_i&now_ctl_base_valid;//1
     assign excep_type_o[2]                            = tlb_pis_excep_i&now_ctl_base_valid;//2
     assign excep_type_o[`PifLocation]                 = excep_type_i[`PifLocation] ; //3
     assign excep_type_o[4]                            = tlb_pme_excep_i&now_ctl_base_valid;//4
     assign excep_type_o[5]                            = tlb_ppi_excep_i&now_ctl_base_valid;//5
     assign excep_type_o[`AdefLocation]                = excep_type_i[`AdefLocation]; //6
     assign excep_type_o[`AdemLocation]                = excep_type_i[`AdemLocation]|tlb_adem_i &now_ctl_base_valid; //7
       //地址不对齐
     assign excep_type_o[`AleLocation]                 = excep_type_i[`AleLocation];//8
     assign excep_type_o[`FpeLocation:`AleLocation+1]  = excep_type_i[`FpeLocation:`AleLocation+1]; //14：9
     assign excep_type_o[`TlbrLocation]                = tlb_memr_excep_i&now_ctl_base_valid;
     assign excep_type_o[`IfPpiLocation:`ErtnLocation] = excep_type_i[`IfPpiLocation:`ErtnLocation];//19：16 
     
     assign excep_en   = excep_en_i | tlb_error_i;
     assign excep_en_o = excep_en & now_ctl_base_valid;
     
     assign refetch_flush_o = refetch_flush_i &now_ctl_valid;
  //跳转冲刷
     assign branch_flush_o = branch_flush_i &now_ctl_valid;  
  //有效信号
  assign now_ctl_valid      = now_ctl_base_valid & (~excep_en);                      
  assign now_ctl_base_valid = (~excep_flush_i) & now_valid_i ;    
  
  //握手信号
  //如果当前指令是在[preif,exe]级没有携带上例外信息的访存指令(即mem_req_i==1)则必须等data_ok
    assign now_ready_go   = 1'b1; //id阶段数据是否运算好了，1：是
    assign now_allowin_o  = !now_valid_i //本级数据为空，允许if阶段写入
                             || (now_ready_go && next_allowin_i);//本级有数据要运行，本时钟周期，id阶段运算好了，exe也同时允许写入，同写，和取走数据
    assign now_to_next_valid_o = now_valid_i && now_ready_go;//id阶段打算写入

 //diff
assign mm_to_diff_obus =    ex_to_diff_ibus;

wire [31:0]diff_store_wdata_i;
    wire diff_rdcn_en_i;
    wire [63:0]diff_time_value_i;
    wire [7:0] diff_load_type_i,diff_store_type_i;    
        
   assign  {diff_store_wdata_i,diff_rdcn_en_i,diff_time_value_i,diff_load_type_i,diff_store_type_i}  = ex_to_diff_ibus  ;

       
endmodule
