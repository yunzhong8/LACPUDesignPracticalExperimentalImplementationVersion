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
\*************/
`include "DefineModuleBus.h"
module MEM(
//    input  wire  clk      ,
//    input  wire  rst_n    ,

    input wire wb_allowin_i,//输入ex已经完成当前数据了,允许你清除id_ex锁存器中的数据，将新数据给ex执行，1为允许,由ex传入
    input wire mem_valid_i, //ID阶段流水是空的，没有要执行的数据，1为有效 ，由id_ex传入,
    
    //
    output wire mem_allowin_o,//传给if，和id_exe,id阶段已经完成数据，允许你清除if_id锁存器内容
    output wire mem_to_wb_valid_o,//传给exe_mem，id阶段已经完成当前数据，想要将运算结果写入id_ex锁存器中，
    input wire excep_flush_i,
    
    input wire data_sram_data_ok_i,
    input  wire [`LineExToMemBusWidth]    exmem_to_ibus       ,
    input wire [`MemDataWidth]  mem_rdata_i    ,
     
    output wire [`LineMemForwardBusWidth]forward_obus,
    output wire to_ex_obus,
    output wire    [`LineMemToWbBusWidth]to_memwb_obus            
);

/***************************************input variable define(输入变量定义)**************************************/
 wire [`PcWidth]pc_i;
 wire [`InstWidth]inst_i; 
  
  
    //存储器
         wire mem_req_i ;
         wire [`MemWeWidth]mem_we_i; 
         wire [`spMemRegsWdataSrcWidth] mem_regs_wdata_src_i;
         wire [`spMemMemDataSrcWidth] mem_mem_data_src_i;
         wire [`MemAddrWidth]         mem_rwaddr_i   ;
         wire [`MemDataWidth]   mem_wdata_i    ;
    //寄存器组
         wire[`RegsAddrWidth] regs_waddr_i;
         wire regs_we_i;
         wire [`RegsDataWidth] regs_wdata_i;
         wire  [`RegsDataWidth]regs_rdata1_i;
         wire  [`RegsDataWidth]regs_rdata2_i;
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
    //例外                                          
         wire [`ExceptionTypeWidth]excep_type_i;    
         wire excep_en_i;                     

/***************************************output variable define(输出变量定义)**************************************/
    //存储器
         wire mem_req_o;
         wire [`MemWeWidth]mem_we_o;
         wire [`MemAddrWidth]mem_rwaddr_o;
         reg [3:0]mem_rwsel_o;
         reg[`MemDataWidth]mem_wdata_o;
        
        
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
    //例外信号                                                          
         wire [`ExceptionTypeWidth] excep_type_o; 
         wire excep_en_o;  
    //相关检测器要求暂停
      wire dr_stall_o;
    
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
 reg [`MemDataWidth]mem_rdata;
 wire [1:0] mem_rwaddr_low2;
 //握手信号
 wire mem_ready_go;
 
/****************************************input decode(输入解码)***************************************/
 assign   {is_kernel_inst_i,
           csr_wdata_src_i,regs_rdata1_i,regs_rdata2_i,
           excep_en_i,excep_type_i,
           llbit_we_i,llbit_wdata_i,                                  
           csr_raddr_src_i,csr_we_i,csr_waddr_i,csr_wdata_i,//csr写使能  
           mem_regs_wdata_src_i,mem_mem_data_src_i,mem_req_i,mem_we_i,mem_rwaddr_i,mem_wdata_i,
           wb_regs_wdata_src_i,regs_we_i,regs_waddr_i,regs_wdata_i,
           pc_i,inst_i} = exmem_to_ibus;


/****************************************output code(输出解码)***************************************/
assign to_memwb_obus={is_kernel_inst_i,
                      csr_wdata_src_i,regs_rdata1_i,regs_rdata2_i,
                      excep_en_o,excep_type_o,mem_rwaddr_o,
                      llbit_we_o,llbit_wdata_o,                                 
                      csr_raddr_src_o,csr_we_o,csr_waddr_o,csr_wdata_o,//csr写使能 
                      wb_regs_wdata_src_i,regs_we_o,regs_waddr_o,regs_wdata_o,
                      pc_i,inst_i};
                      
assign forward_obus={llbit_we_o,llbit_wdata_o,                                                                      
                     regs_we_o,regs_waddr_o,regs_wdata_o,
                     dr_stall_o};
//必须在本级允许前一级写入数据的时候，阻塞ex一个时钟周期，确保mem阶段的指令一级流到了wb阶段            
assign to_ex_obus   = (excep_en_o | is_kernel_inst_i) & mem_valid_i & mem_allowin_o;//if 当前数据有效，then携带了例外信息则暂停ex阶段流水,当前是特权指令也要阻塞ex阶段，因为特权指令可能发生特权例外,凡是要回递送的，必须是当前阶段数据有效才行
//assign to_ex_obus   = 1'b0;
//assign to_data_obus={mem_req_o,mem_we_o,mem_rwaddr_o,mem_wdata_o};
/*******************************complete logical function (逻辑功能实现)*******************************/
  //forward
  //当前指令是在wb阶段写入的，且数据有效，要求暂停，当前指令是访存指令，但是数据还没有读出则要求暂停
  assign dr_stall_o =  mem_valid_i & (wb_regs_wdata_src_i | (mem_req_i & (~data_sram_data_ok_i)) );
  //寄存器组
    assign regs_waddr_o = regs_waddr_i;
    assign regs_we_o = regs_we_i && mem_valid_i && (!excep_en_o);//因为有forward，所以可能无效要立马实现，we——i=1&&当前数据有效，we_o=1
    assign regs_wdata_o = mem_regs_wdata_src_i ? mem_rdata :regs_wdata_i;

    assign mem_rwaddr_low2 = mem_rwaddr_i[1:0];
   
    always @(*)begin
            case(mem_mem_data_src_i)
                `spMemMemDataSrcLen'b000:begin//字
                    mem_rdata = mem_rdata_i ;
                end
                `spMemMemDataSrcLen'b010:begin//半字0扩展
                    case(mem_rwaddr_low2[1])
                        1'b0:begin
                            mem_rdata = {16'd0,mem_rdata_i[15:0]};
                        end
                        default:begin
                            mem_rdata = {16'd0,mem_rdata_i[31:16]};
                        end
                    endcase    
                end
                `spMemMemDataSrcLen'b011:begin//半字符号扩展
                    case(mem_rwaddr_low2[1])
                        1'b0:begin
                            mem_rdata = {{16{mem_rdata_i[15]}},mem_rdata_i[15:0]};
                        end
                        1'b1:begin
                            mem_rdata = { {16{mem_rdata_i[31]}},mem_rdata_i[31:16] };
                        end
                        default:begin
                            mem_rdata = `ZeroWord32B;
                        end
                    endcase
                end
                `spMemMemDataSrcLen'b100:begin//字节0扩展
                    case(mem_rwaddr_low2)
                        2'b00:begin
                            mem_rdata = {24'd0,mem_rdata_i[7:0]};
                        end
                        2'b01:begin
                            mem_rdata = {24'd0,mem_rdata_i[15:8]};
                        end
                        2'b10:begin
                            mem_rdata = {24'd0,mem_rdata_i[23:16]};
                        end
                        default:begin
                            mem_rdata = {24'd0,mem_rdata_i[31:24]};
                        end
                    endcase
                end
                `spMemMemDataSrcLen'b101:begin//字节符号扩展
                    case(mem_rwaddr_low2)
                        2'b00:begin
                            mem_rdata = { {24{mem_rdata_i[7]}},mem_rdata_i[7:0] };
                        end
                        2'b01:begin
                            mem_rdata = { {24{mem_rdata_i[15]}},mem_rdata_i[15:8]};
                        end
                        2'b10:begin
                            mem_rdata = {{24{mem_rdata_i[23]}},mem_rdata_i[23:16]};
                        end
                        default:begin
                            mem_rdata = {{24{mem_rdata_i[31]}},mem_rdata_i[31:24]};
                        end
                    endcase
                end default:begin
                            mem_rdata = `ZeroWord32B;
                end
            endcase
        end

//存储器  
    assign  mem_we_o     = mem_we_i;//写使能    
    assign  mem_rwaddr_o = mem_rwaddr_i; 
    assign  mem_req_o    = mem_req_i   ;
 //csr
    assign csr_raddr_src_o =  csr_raddr_src_i; 
    assign csr_we_o        =  csr_we_i && mem_valid_i && (!excep_en_o);        
    assign csr_waddr_o     =  csr_waddr_i;     
    assign csr_wdata_o     =  csr_wdata_i;     
    //llbit                                    
    assign llbit_we_o    =   llbit_we_i && mem_valid_i && (!excep_en_o);       
    assign llbit_wdata_o =  llbit_wdata_i;     
    
    
     //例外
     assign excep_en_o =  excep_en_i & mem_valid_i;
     assign excep_type_o = excep_type_i ;//当前例外信号必须的前提是当前数据不为空                      
     
 
  //握手信号
    assign mem_ready_go   = mem_req_i  ? (data_sram_data_ok_i ? 1'b1:1'b0) :1'b1; //id阶段数据是否运算好了，1：是
    assign mem_allowin_o  = !mem_valid_i //本级数据为空，允许if阶段写入
                             || (mem_ready_go && wb_allowin_i);//本级有数据要运行，本时钟周期，id阶段运算好了，exe也同时允许写入，同写，和取走数据
    assign mem_to_wb_valid_o = mem_valid_i && mem_ready_go;//id阶段打算写入


       
       
endmodule

