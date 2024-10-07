/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：很抱歉读cache要用mmu进行翻译，所以未来就是4读，2两写
*tlbrd错误，vppn是tlbehi的31：13位，我设置tlbrd往csr中写入的vpp设置在31：12导致错误
×例外使能信号应该和例外信息保持一致，因为可能因为前面流水产生啦例外使能，导致本级没有产生例外，但是有例外信息，导致例外种类由于优先级发生错误
*tlb例外中页等级例外是使用crmd中的plv位，我用成了tlhblo0,tlbl01中的plv域
×pis例外的1前提是没有发生tlb重填例外，失手写成没有发生pis例外是前提
*复制粘贴出现错误,忘记修改,查找了一天csr_crmd_da_i  && (csr_crmd_datm_i==2'b0)) ||
/*************\
bug:
\*************/
//`include "DefineModuleBus.h"
//`include "DefineCsrAddr.h"
`include "define.v"
module Mmu(
input  wire clk,
input wire  rst_n,

input  wire [`IfToMmuBusWidth]   if_to_ibus  ,
input  wire [`MemToMmuBusWidth]     mem_to_ibus    ,
input  wire [`WbToMmuBusWidth]      wb_to_ibus     ,//csr到mmu的数据
input  wire [`CsrToMmuBusWidth]     csr_to_ibus    ,

output wire [`MmuToIfBusWidth]     to_if_obus  ,//取指令翻译结果
output wire [`MmuToMemBusWidth]     to_mem_obus    ,//访存翻译结果
output wire [`MmuToWbBusWidth]      to_wb_obus     //tlb读指令
//output wire [`MmuToCsrBusWidth]to_csr_obus 

);





/***************************************input variable define(输入变量定义)**************************************/
//preif
wire [31:0] pc_i;
//exe阶段输入
wire [1:0]mem_type_i;//访问类型，1x表示存储访问，00表示：不使用mmu,01表示：tlb查找指令在使用mmu
wire [31:0]data_rw_addr_i;

//CSR的输入

wire [31:0] csr_crmd_i,csr_asid_i,csr_tlbehi_i,csr_tlbidx_i,csr_tlbelo0_i,csr_tlbelo1_i,csr_dmw1_i,csr_dmw0_i ;

wire                   csr_crmd_da_i;
wire  [`PlvWidth]      csr_crmd_plv_i             ;
wire   [1:0]           csr_crmd_datf_i            ; 
wire   [1:0]           csr_crmd_datm_i            ;
wire  [`AsidWidth]     csr_asid_asid_i            ;    
                                                  
wire  [`TlbIndexWidth] csr_tlbidx_index_i         ;
wire  [`PsWidth]       csr_tlbidx_ps_i            ;
wire                   csr_tlbidx_ne_i            ;
                                                 
wire  [`VppnWidth]     csr_tlbehi_vppn_i          ;
                                                  
wire                   csr_tlbelo0_v_i            ;
wire                   csr_tlbelo0_d_i            ;
wire  [`PlvWidth]      csr_tlbelo0_plv_i          ;
wire  [`MatWidth]      csr_tlbelo0_mat_i          ;
wire                   csr_tlbelo0_g_i            ;
wire  [`PpnWidth]      csr_tlbelo0_ppn_i          ;
                                                  
wire                   csr_tlbelo1_v_i            ;
wire                   csr_tlbelo1_d_i            ;
wire  [`PlvWidth]      csr_tlbelo1_plv_i          ;
wire  [`MatWidth]      csr_tlbelo1_mat_i          ;
wire                   csr_tlbelo1_g_i            ;
wire  [`PpnWidth]      csr_tlbelo1_ppn_i          ;

wire                csr_dmw0_plv0_i;//看不懂你这个dmw的功能是要做什么              
wire                csr_dmw0_plv3_i;                                 
wire [`MatWidth]    csr_dmw0_mat_i;                                  
wire [`DmwPsegWidth]csr_dmw0_pseg_i;                              
wire [`DmwVsegWidth]csr_dmw0_vseg_i;                              

wire                csr_dmw1_plv0_i ;//看不懂你这个dmw的功能是要做什么
wire                csr_dmw1_plv3_i ;
wire [`MatWidth]    csr_dmw1_mat_i  ;
wire [`DmwPsegWidth]csr_dmw1_pseg_i ;
wire [`DmwVsegWidth]csr_dmw1_vseg_i ;


//wb阶段输入
wire tlb_ie_i         ; 
wire tlb_fe_i ;





/***************************************output variable define(输出变量定义)**************************************/
//PREIFG
wire [`PcWidth]p_inst_raddr;
wire inst_uncache_o;//访问空间是uncache
//EXE输出
wire [`TlbIndexWidth]exe_tlbidx_index_o;
wire exe_tlbidx_ne_o;
wire [`PcWidth]  p_data_rwaddr;
wire data_uncache_o;
//WB输出
wire wb_tlbrd_valid;//tlrd查找的表项无效
wire [31:0]wb_tlbehi_o;
wire [31:0]wb_tlblo0_o;
wire [31:0]wb_tlblo1_o;
wire [`PsWidth]wb_tlbidx_ps_o;
wire [`AsidWidth]wb_asid_asid_o;

/***************************************parameter define(常量定义)**************************************/
parameter TLBNUM = 16 ;
wire [$clog2(TLBNUM)-1:0]diff_refill_rand_index_o;
/***************************************inner variable define(内部变量定义)**************************************/
// search port 0     
wire [`TlbSearchIbusWidth]  tlb_s0_ibus         ;                                     
wire [`VppnWidth] s0_vppn;                                      
wire              s0_va_bit12;                                  
wire [`AsidWidth] s0_asid;            

wire [`TlbSearchObusWidth]  tlb_s0_obus         ;  
wire                        tlb_s0_found      ;                                                    
wire [$clog2(TLBNUM)-1:0]s0_index;                        
wire [`PpnWidth]         s0_ppn;                                       
wire [`PsWidth]          s0_ps;                                        
wire [`PlvWidth]         s0_plv;                                       
wire [`MatWidth]         s0_mat;                                       
wire                     s0_d;                                         
wire                     s0_v;                                      
// search port 1    
wire [`TlbSearchIbusWidth]  tlb_s1_ibus         ;                                      
wire [`VppnWidth] s1_vppn;                                      
wire              s1_va_bit12;                                  
wire [`AsidWidth] s1_asid;  

wire                        tlb_s1_found      ;
wire [`TlbSearchObusWidth]  tlb_s1_obus         ;                                                                        
wire [$clog2(TLBNUM)-1:0] s1_index;                       
wire [`PpnWidth]          s1_ppn;                                       
wire [`PsWidth]           s1_ps;                                        
wire [`PlvWidth]          s1_plv;                                       
wire [`MatWidth]          s1_mat;                                       
wire                      s1_d;                                         
wire                      s1_v;                                         
// write port    
wire        tlb_we_i;                                   
wire [$clog2(TLBNUM)-1:0] tlb_w_index;//log16=4,4-1=3 
reg [$clog2(TLBNUM)-1:0] refill_rand_index;//重填的随机地址

wire [`TlbWriteBusWidth]    tlb_w_ibus          ;                                           
wire              w_e;                                          
wire [`VppnWidth] w_vppn;                                       
wire [`PsWidth]   w_ps  ;                                       
wire [`AsidWidth] w_asid;                                       
wire              w_g;                                          
wire [`PpnWidth]  w_ppn0;                                       
wire [`PlvWidth]  w_plv0;                                       
wire [`MatWidth]  w_mat0;                                       
wire              w_d0;                                         
wire              w_v0;                                         
wire [`PpnWidth]  w_ppn1;                                       
wire [`PlvWidth]  w_plv1;                                       
wire [`MatWidth]  w_mat1;                                       
wire              w_d1;                                         
wire              w_v1;                                         
// read port  
wire [`TlbReadIbusWidth]    tlb_r_ibus          ;                               

wire [`TlbReadObusWidth]    tlb_r_obus          ;                       
wire              r_e;                                          
wire [`VppnWidth] r_vppn;                                       
wire [`PsWidth]   r_ps;                                         
wire [`AsidWidth] r_asid;                                       
wire              r_g;                                          
wire [`PpnWidth]  r_ppn0;                                       
wire [`PlvWidth]  r_plv0;                                       
wire [`MatWidth]  r_mat0;                                       
wire              r_d0;                                         
wire              r_v0;                                         
wire [`PpnWidth]  r_ppn1;                                       
wire [`PlvWidth]  r_plv1;                                       
wire [`MatWidth]  r_mat1;                                       
wire              r_d1;                                         
wire              r_v1;       
//TLB例外信号
wire fetch_except_flag;
wire [`MmuFetchExcepNumWidth]fetch_tlb_excpet_type;
wire tlb_fetchr_except;
wire tlb_pif_except;
wire tlb_fetch_ppi_except;
wire tlb_fetch_adef_except;

wire exe_except_flag;
wire [`MmuLSExcepNumWidth]data_tlb_except_type;
wire tlb_adem_except;
wire tlb_memr_except;
wire tlb_pil_except;
wire tlb_pis_except;
wire tlb_exe_ppi_except;
wire tlb_pme_except;


//DMW
wire fetch_dmw0_en,fetch_dmw1_en;
wire ls_dmw0_en,ls_dmw1_en;


                                         



        

                                           



wire [`TlbInvBusWidth]tlb_invtlb_ibus ;

/****************************************input decode(输入解码)***************************************/
//一级解码
assign  pc_i = if_to_ibus;
assign  {mem_type_i,data_rw_addr_i} = mem_to_ibus;
assign  {tlb_fe_i,tlb_we_i,tlb_ie_i,tlb_invtlb_ibus} = wb_to_ibus;
assign  {csr_crmd_i,csr_asid_i,csr_tlbehi_i,csr_tlbidx_i,csr_tlbelo0_i,csr_tlbelo1_i,csr_dmw1_i,csr_dmw0_i} = csr_to_ibus ;
//二级解码

assign csr_crmd_plv_i  = csr_crmd_i[`CrmdPlvLocation];
assign csr_crmd_da_i   = csr_crmd_i[`CrmdDaLocation];
assign csr_crmd_datf_i = csr_crmd_i[`CrmdDatfLocation];
assign csr_crmd_datm_i = csr_crmd_i[`CrmdDatmLocation];

assign  csr_asid_asid_i      =  csr_asid_i   [`AsidAsidLocation]    ;

assign  csr_tlbidx_index_i   =  csr_tlbidx_i [`TlbidxIndxLocation]  ;
assign  csr_tlbidx_ps_i      =  csr_tlbidx_i [`TLbidxPsLocation]    ;
assign  csr_tlbidx_ne_i      =  csr_tlbidx_i [`TLbidxNeLocation]    ;

assign  csr_tlbehi_vppn_i    =  csr_tlbehi_i [`TlbehiVppnLocation ] ;//没有奇偶位

assign  csr_tlbelo0_v_i      =  csr_tlbelo0_i [`TlbeloVLocation]    ;
assign  csr_tlbelo0_d_i      =  csr_tlbelo0_i [`TlbeloDLocation]    ;
assign  csr_tlbelo0_plv_i    =  csr_tlbelo0_i [`TlbeloPlvLocation]  ;
assign  csr_tlbelo0_mat_i    =  csr_tlbelo0_i [`TlbeloMatLocation]  ;
assign  csr_tlbelo0_g_i      =  csr_tlbelo0_i [`TlbeloGLocation]    ;
assign  csr_tlbelo0_ppn_i    =  csr_tlbelo0_i [`TlbeloPpnLocation]  ;

assign  csr_tlbelo1_v_i      =  csr_tlbelo1_i [`TlbeloVLocation]    ;  
assign  csr_tlbelo1_d_i      =  csr_tlbelo1_i [`TlbeloDLocation]    ;  
assign  csr_tlbelo1_plv_i    =  csr_tlbelo1_i [`TlbeloPlvLocation]  ;
assign  csr_tlbelo1_mat_i    =  csr_tlbelo1_i [`TlbeloMatLocation]  ;
assign  csr_tlbelo1_g_i      =  csr_tlbelo1_i [`TlbeloGLocation]    ;  
assign  csr_tlbelo1_ppn_i    =  csr_tlbelo1_i [`TlbeloPpnLocation]  ;


assign csr_dmw0_plv0_i   = csr_dmw0_i[`DmwPlv0Location ];
assign csr_dmw0_plv3_i   = csr_dmw0_i[`DmwPlv3Location ];
assign csr_dmw0_mat_i    = csr_dmw0_i[`DmwMatLocation ]; 
assign csr_dmw0_pseg_i   = csr_dmw0_i[`DmwPsegLocation ];
assign csr_dmw0_vseg_i   = csr_dmw0_i[`DmwVsegLocation ];




assign csr_dmw1_plv0_i   = csr_dmw1_i[`DmwPlv0Location ];
assign csr_dmw1_plv3_i   = csr_dmw1_i[`DmwPlv3Location ];
assign csr_dmw1_mat_i    = csr_dmw1_i[`DmwMatLocation ];
assign csr_dmw1_pseg_i   = csr_dmw1_i[`DmwPsegLocation ];
assign csr_dmw1_vseg_i   = csr_dmw1_i[`DmwVsegLocation ];


/****************************************output code(输出解码)***************************************/
assign to_if_obus    = {inst_uncache_o,fetch_except_flag,fetch_tlb_excpet_type,p_inst_raddr};
assign to_mem_obus   = {data_uncache_o,exe_except_flag,data_tlb_except_type,p_data_rwaddr,tlb_s1_found,exe_tlbidx_index_o,exe_tlbidx_ne_o};
assign to_wb_obus    = {diff_refill_rand_index_o,
                        r_e,wb_tlbehi_o,wb_tlblo0_o,wb_tlblo1_o,wb_tlbidx_ps_o,wb_asid_asid_o};



assign   tlb_s0_ibus = {s0_vppn,s0_va_bit12,s0_asid} ;    
assign   tlb_s1_ibus = {s1_vppn,s1_va_bit12,s1_asid} ;   
   
assign   {s0_ppn,s0_ps,s0_plv,s0_mat,s0_d,s0_v} = tlb_s0_obus;  
assign   {s1_ppn,s1_ps,s1_plv,s1_mat,s1_d,s1_v} = tlb_s1_obus; //这里也写啦s0_plv导致多驱动，导致信号有问题  

assign   tlb_w_ibus = {
                  w_e,w_vppn,w_ps,w_asid,w_g,
                  w_ppn0,w_plv0,w_mat0,w_d0,w_v0,
                  w_ppn1,w_plv1,w_mat1,w_d1,w_v1       }    ; 
         
assign   tlb_r_ibus =  csr_tlbidx_index_i;

assign   {r_e,r_vppn,r_ps,r_asid,r_g,
                  r_ppn0,r_plv0,r_mat0,r_d0,r_v0,
                  r_ppn1,r_plv1,r_mat1,r_d1,r_v1} = tlb_r_obus ;
/*******************************complete logical function (逻辑功能实现)*******************************/
//assign fetch_dmw0_en = =()
   assign fetch_dmw0_en = ((csr_dmw0_plv0_i && csr_crmd_plv_i==2'd0) || (csr_dmw0_plv3_i&&csr_crmd_plv_i==2'd3)) && (pc_i[31:29]==csr_dmw0_vseg_i);
   assign fetch_dmw1_en = ((csr_dmw1_plv0_i && csr_crmd_plv_i==2'd0) || (csr_dmw1_plv3_i&&csr_crmd_plv_i==2'd3)) && (pc_i[31:29]==csr_dmw1_vseg_i);
     
   assign ls_dmw0_en  =  ((csr_dmw0_plv0_i && csr_crmd_plv_i==2'd0) || (csr_dmw0_plv3_i&&csr_crmd_plv_i==2'd3)) && (data_rw_addr_i[31:29]==csr_dmw0_vseg_i);
   assign ls_dmw1_en  =  ((csr_dmw1_plv0_i && csr_crmd_plv_i==2'd0) || (csr_dmw1_plv3_i&&csr_crmd_plv_i==2'd3)) && (data_rw_addr_i[31:29]==csr_dmw1_vseg_i);
  
  //查找指令
  //至于是csr的读出值，还是PC截断值，由EXE模块自己去确定
   assign   {s0_vppn,s0_va_bit12,s0_asid} = {pc_i[31:13],pc_i[12],csr_asid_asid_i};
   assign   {s1_vppn,s1_va_bit12,s1_asid} = (mem_type_i==2'b01) ? {csr_tlbehi_vppn_i,1'b0,csr_asid_asid_i } : {data_rw_addr_i[31:13],data_rw_addr_i[12],csr_asid_asid_i};
  
   //查找输出：
   assign exe_tlbidx_index_o = tlb_s1_found ? s1_index : 0;
   assign exe_tlbidx_ne_o    = tlb_s1_found ? 1'b0 :1'b1 ;
   //查找例外
    
   //PC,mem查找
   assign p_inst_raddr  =  (~csr_crmd_da_i & ~fetch_dmw0_en & ~fetch_dmw1_en) ? {s0_ppn,pc_i[11:0]}          ://映射模式不使用窗口
                           (~csr_crmd_da_i & fetch_dmw0_en)                   ? {csr_dmw0_pseg_i,pc_i[28:0]} ://映射模式使用窗口0
                           (~csr_crmd_da_i & fetch_dmw1_en)                   ? {csr_dmw1_pseg_i,pc_i[28:0]} :pc_i;//映射模式使用窗口1:直接映射
                            
   assign p_data_rwaddr = (~csr_crmd_da_i & ~ls_dmw0_en &~ls_dmw1_en)   ? {s1_ppn,data_rw_addr_i[11:0]}:
                          (~csr_crmd_da_i & ls_dmw0_en )                ? {csr_dmw0_pseg_i,data_rw_addr_i[28:0]}:
                          (~csr_crmd_da_i & ls_dmw1_en )                ? {csr_dmw1_pseg_i,data_rw_addr_i[28:0]}: data_rw_addr_i;
   //查找空间是不是uncache
    assign inst_uncache_o = (csr_crmd_da_i  && (csr_crmd_datf_i==2'b0)) ||
                            (fetch_dmw0_en  && (csr_dmw0_mat_i ==2'b0)) ||
                            (fetch_dmw1_en  && (csr_dmw1_mat_i ==2'b0)) ||
                            (~csr_crmd_da_i & ~fetch_dmw0_en & ~fetch_dmw1_en)&&(s0_mat==2'b0);
                            
    assign data_uncache_o = (csr_crmd_da_i  && (csr_crmd_datm_i==2'b0)) || //复制粘贴出现错误,忘记修改,查找了一天csr_crmd_da_i  && (csr_crmd_datm_i==2'b0)) ||
                            (ls_dmw0_en     && (csr_dmw0_mat_i ==2'b0)) ||
                            (ls_dmw1_en     && (csr_dmw1_mat_i ==2'b0)) ||
                            (~csr_crmd_da_i & ~ls_dmw0_en & ~ls_dmw1_en)&&(s1_mat==2'b0);
   //读逻辑
   assign  r_ibus = csr_tlbidx_index_i;
   
   assign  wb_tlbehi_o    = r_e ? {r_vppn,13'd0} : 32'd0                                 ;
   assign  wb_tlbidx_ps_o = r_e ? r_ps : 6'd0                                            ;
   assign  wb_asid_asid_o = r_e ? r_asid :10'd0                                          ;
   assign  wb_tlblo0_o    = r_e ? {4'd0,r_ppn0,1'd0,r_g,r_mat0,r_plv0,r_d0,r_v0} : 32'd0 ;                
   assign  wb_tlblo1_o    = r_e ? {4'd0,r_ppn1,1'd0,r_g,r_mat1,r_plv1,r_d1,r_v1} : 32'd0 ;

   
   
   //写逻辑
   //fill和wr指令的裁决放在wb阶段
   always @(posedge clk)begin//一个简单的随机设置，从0不断自+1
        if(rst_n ==1'b0)begin
            refill_rand_index <= 0;
        end else begin
            refill_rand_index <= refill_rand_index +1;
    end
        
   end
   assign tlb_w_index  =  tlb_we_i ? csr_tlbidx_index_i : tlb_fe_i ? refill_rand_index:0;//tlb写地址
   assign w_e          =  ~ csr_tlbidx_ne_i;//tlb表项是否存在，ne==1则填写无效0
   assign w_vppn       =  csr_tlbehi_vppn_i;//表项虚地址
   assign w_ps         =  csr_tlbidx_ps_i;//页大小
   assign w_asid       =  csr_asid_asid_i;//地址空间
   assign w_g          =  csr_tlbelo0_g_i & csr_tlbelo1_g_i;
   assign w_ppn0       =  csr_tlbelo0_ppn_i;
   assign w_plv0       =  csr_tlbelo0_plv_i;
   assign w_mat0       =  csr_tlbelo0_mat_i;
   assign w_d0         =  csr_tlbelo0_d_i;
   assign w_v0         =  csr_tlbelo0_v_i;
   assign w_ppn1       =  csr_tlbelo1_ppn_i;
   assign w_plv1       =  csr_tlbelo1_plv_i; 
   assign w_mat1       =  csr_tlbelo1_mat_i; 
   assign w_d1         =  csr_tlbelo1_d_i;     
   assign w_v1         =  csr_tlbelo1_v_i;     
   
   
   //TLB模块
  tlb  tlb_item (
    .clk           (clk      ),
    
    
    .s0_ibus       (tlb_s0_ibus    ),
    .s1_ibus       (tlb_s1_ibus    ),
    
    
    .invtlb_valid_i(tlb_ie_i     ),
    .invtlb_ibus   (tlb_invtlb_ibus    ),
                 
    .s0_found_o    (tlb_s0_found  ),
    .s0_index_o    (s0_index),
    .s0_obus       (tlb_s0_obus   ),
    .s1_found_o    (tlb_s1_found  ),
    .s1_index_o    (s1_index),
    .s1_obus       (tlb_s1_obus   ),
                    
    .we_i          (tlb_we_i|tlb_fe_i  ),  
    .w_index_i     (tlb_w_index   ),     
    .w_ibus        (tlb_w_ibus    ),
                 
    .r_ibus        (tlb_r_ibus    ),
    .r_obus        (tlb_r_obus    )
       
);  

//例外逻辑
//取指查找MMU的例外
assign tlb_fetch_adef_except = ~csr_crmd_da_i& ~fetch_dmw0_en & ~fetch_dmw1_en ?  (csr_crmd_plv_i==2'd3)&&pc_i[31] :1'b0 ;
assign tlb_fetchr_except     = ~csr_crmd_da_i& ~fetch_dmw0_en & ~fetch_dmw1_en ?  ~tlb_s0_found :1'b0; //取值重填
assign tlb_pif_except        = ~csr_crmd_da_i& ~fetch_dmw0_en & ~fetch_dmw1_en ?  tlb_s0_found & ~s0_v :1'b0;//取指令操作页无效例外
assign tlb_fetch_ppi_except  = ~csr_crmd_da_i& ~fetch_dmw0_en & ~fetch_dmw1_en ?  tlb_s0_found && s0_v && (csr_crmd_plv_i > s0_plv) :1'b0;//取指页特权等级不合规例外

assign fetch_except_flag     = ~csr_crmd_da_i& ~fetch_dmw0_en & ~fetch_dmw1_en ?  tlb_fetch_adef_except || tlb_fetchr_except || tlb_pif_except || tlb_fetch_ppi_except :1'b0;
assign fetch_tlb_excpet_type = ~csr_crmd_da_i& ~fetch_dmw0_en & ~fetch_dmw1_en ?  {tlb_fetch_adef_except,tlb_fetchr_except,tlb_pif_except,tlb_fetch_ppi_except} :`MmuFetchExcepNumLen'b0;

//exe查找MMU例外 查找例外有效的前提是当前是load,store指令，且处于映射地址模式
assign tlb_adem_except    = (~csr_crmd_da_i & mem_type_i[1]& ~ls_dmw0_en &~ls_dmw1_en) ? (csr_crmd_plv_i==2'd3) && data_rw_addr_i[31] : 1'b0;
assign tlb_memr_except    = (~csr_crmd_da_i & mem_type_i[1]& ~ls_dmw0_en &~ls_dmw1_en) ? mem_type_i[1] & ~tlb_s1_found :1'b0   ;//tlb重新填例外
assign tlb_pil_except     = (~csr_crmd_da_i & mem_type_i[1]& ~ls_dmw0_en &~ls_dmw1_en) ? !tlb_memr_except && mem_type_i==2'b10 && ~s1_v :1'b0;//没有发生重填例外，且是load指令，表项无效
assign tlb_pis_except     = (~csr_crmd_da_i & mem_type_i[1]& ~ls_dmw0_en &~ls_dmw1_en) ? !tlb_memr_except && mem_type_i==2'b11 && ~s1_v :1'b0;
assign tlb_exe_ppi_except = (~csr_crmd_da_i & mem_type_i[1]& ~ls_dmw0_en &~ls_dmw1_en) ? !(tlb_pil_except |tlb_pis_except) && (csr_crmd_plv_i > s1_plv) :1'b0 ;
assign tlb_pme_except     = (~csr_crmd_da_i & mem_type_i[1]& ~ls_dmw0_en &~ls_dmw1_en) ? !tlb_exe_ppi_except && mem_type_i == 2'b11 && (s1_d == 1'b0) :1'b0;
//如果load，store指令且是要进行虚拟地址转换则这部分例外信息有效，
assign  exe_except_flag     = (mem_type_i[1] &~csr_crmd_da_i& ~ls_dmw0_en &~ls_dmw1_en)? tlb_adem_except || tlb_memr_except || tlb_pil_except || tlb_pis_except || tlb_exe_ppi_except || tlb_pme_except :1'b0;
assign data_tlb_except_type = (mem_type_i[1] &~csr_crmd_da_i& ~ls_dmw0_en &~ls_dmw1_en)? {tlb_adem_except,tlb_memr_except,tlb_pil_except,tlb_pis_except,tlb_pme_except,tlb_exe_ppi_except} : `MmuLSExcepNumLen'd0;                                  




//diff
assign diff_refill_rand_index_o = refill_rand_index;















endmodule