/*
*作者：zzq
*创建时间：2023-03-31
*email:3486829357@qq.com
*github:yunzhong8
*输入：
*输出：
*模块功能：实现7一个队列,这是一个只支持一个写，一个读队列
问题：队列的的关键元素是什么，我需要根据这个这元素设置输入输出
*队尾移动
lunch允许输入
    
lunch:发射了两条指令,则移动两个
lunch:发射了两条空指令,则不移动
lunch:发射了一条指令,则移动一个
队头移动
当前阶段允许输入
输入两条有效指令则队头移动2
输入一条有效指令则队头移动1
输入0条有效指令,则不移动
*/
/*************\
bug:
\*************/
//`include "DefineModuleBus.h"
`include "define.v"
module diff
(
    input  wire  clk      ,
    input  wire  rst_n    ,
    
    output wire error_o,
    //队列写使能
    input wire  [`ZzqWbToDiffBusWidth]wb_to_ibus
   
);

/***************************************input variable define(输入变量定义)**************************************/
wire [`LineZzqWbToDiffBusWidth]line2_to_diff_bus,line1_to_diff_bus;
//wb阶段是load指令
wire line2_diff_load_en_i,line1_diff_load_en_i ;
//wb阶段是load指令
wire line2_diff_store_en_i,line1_diff_store_en_i; 
//load/store指令的访问虚地址
wire[31:0] line2_diff_ls_vaddr_i,line1_diff_ls_vaddr_i;
//load/store指令的访问实地址
wire[31:0] line2_diff_ls_paddr_i,line1_diff_ls_paddr_i;
//store指令的写数据
wire [31:0]line2_diff_store_wdata_i,line1_diff_store_wdata_i;

//wb阶段执行的执行指令有效
wire                  line2_valid_diff_i,line1_valid_diff_i ;   
//wb阶段执行的指令的pc                   
wire [`PcWidth]       line2_pc_diff_i,line1_pc_diff_i;   
//wb阶段执行的指令             
wire [`InstWidth]     line2_inst_diff_i,line1_inst_diff_i;  
//wb阶段写寄存器堆使能          
wire                   line2_regs_we_diff_i,line1_regs_we_diff_i; 
//wb阶段写寄存器堆写地址    
wire [`RegsAddrWidth] line2_regs_waddr_diff_i,line1_regs_waddr_diff_i;  
//wb阶段写寄存器堆写数据
wire [`RegsDataWidth] line2_regs_wdata_diff_i,line1_regs_wdata_diff_i;  
////wb阶段是计数器访问指令：3条
wire line2_diff_rdcn_en_i,line1_diff_rdcn_en_i;
//wire当前计数器的值
wire [63:0]line2_diff_time_value_i,line1_diff_time_value_i;

//csr是否写存储例外信息的csr寄存器
wire line2_diff_csr_rstat_en_i,line1_diff_csr_rstat_en_i;
//csr写使能
wire line2_diff_csr_we_i,line1_diff_csr_we_i;
//csr写地址
wire [`CsrAddrWidth]line2_diff_csr_waddr_i,line1_diff_csr_waddr_i;
//csr写数据
wire [31:0]line2_diff_csr_wdata_i,line1_diff_csr_wdata_i;

//跳转指令是否预测错误
wire line1_diiff_branch_inst_predict_error_i,line2_diiff_branch_inst_predict_error_i;



/***************************************output variable define(输出变量定义)**************************************/
/***************************************parameter define(常量定义)**************************************/

/***************************************inner variable define(内部变量定义)**************************************/
wire line1_is_branch,line2_is_branch;
assign  line1_is_branch = line1_inst_diff_i[30];
assign  line2_is_branch = line2_inst_diff_i[30];
reg [31:0]branch_inst_amount,branch_inst_predict_error_times;
//记录执行指令总数
reg [31:0] inst_amount,line1_exe_inst_amount,line2_exe_inst_amount;
 always @(posedge clk)begin
    if(rst_n==`RstEnable)begin
        inst_amount <= 32'h0;
    end else if(line1_valid_diff_i&line2_valid_diff_i)begin
        inst_amount <= inst_amount + 32'd2;
    end else if (line1_valid_diff_i|line2_valid_diff_i)begin
        inst_amount <=inst_amount + 32'd1;
    end else begin
        inst_amount <=inst_amount;
    end 
 end
//记录第一条流水执行的次数
 always @(posedge clk)begin
    if(rst_n==`RstEnable)begin
        line1_exe_inst_amount <= 32'h0;
    end else if(line1_valid_diff_i)begin
        line1_exe_inst_amount <= line1_exe_inst_amount + 32'd1;
    end else begin
        line1_exe_inst_amount <= line1_exe_inst_amount;
    end 
 end

//记录第二条流水线执行的次数
 always @(posedge clk)begin
    if(rst_n==`RstEnable)begin
        line2_exe_inst_amount <= 32'h0;
    end else if(line2_valid_diff_i)begin
        line2_exe_inst_amount <= line2_exe_inst_amount + 32'd1;
    end else begin
        line2_exe_inst_amount <= line2_exe_inst_amount;
    end 
 end
 
 
 

 //记录跳转指令预测错误的次数
   always @(posedge clk)begin
    if(rst_n==`RstEnable)begin
        branch_inst_predict_error_times <= 32'h0;
    end else if(line1_valid_diff_i&line1_diiff_branch_inst_predict_error_i)begin
        branch_inst_predict_error_times <= branch_inst_predict_error_times + 32'd1;
    end else if (line2_valid_diff_i&line2_diiff_branch_inst_predict_error_i)begin
       branch_inst_predict_error_times <=branch_inst_predict_error_times + 32'd1;
    end else begin
        branch_inst_predict_error_times <=branch_inst_predict_error_times;
    end 
 end
 
 
 //计算执行的跳转指令总数
   always @(posedge clk)begin
    if(rst_n==`RstEnable)begin
        branch_inst_amount <= 32'h0;
    end else if((line1_valid_diff_i&line1_is_branch)&(line2_valid_diff_i&line2_is_branch))begin
         branch_inst_amount<=  branch_inst_amount + 32'd2;
    end else if ((line1_valid_diff_i&line1_is_branch)|(line2_valid_diff_i&line2_is_branch))begin
         branch_inst_amount <= branch_inst_amount + 32'd1;
    end else begin
         branch_inst_amount <= branch_inst_amount;
    end 
 end
 

/****************************************input decode(输入解码)***************************************/
assign {line2_to_diff_bus,line1_to_diff_bus} = wb_to_ibus;
assign {
        line1_diiff_branch_inst_predict_error_i,
        line1_diff_csr_rstat_en_i,
        line1_diff_csr_we_i,line1_diff_csr_waddr_i,line1_diff_csr_wdata_i,
        line1_diff_rdcn_en_i,line1_diff_time_value_i,
        
        line1_diff_load_en_i,line1_diff_store_en_i,line1_diff_ls_vaddr_i,line1_diff_ls_paddr_i,line1_diff_store_wdata_i,
        line1_regs_we_diff_i,line1_regs_waddr_diff_i,line1_regs_wdata_diff_i,
        line1_inst_diff_i,line1_pc_diff_i,line1_valid_diff_i
        } = line1_to_diff_bus;
 assign {
        line2_diiff_branch_inst_predict_error_i,
        line2_diff_csr_rstat_en_i,
        line2_diff_csr_we_i,line2_diff_csr_waddr_i,line2_diff_csr_wdata_i,
        
        line2_diff_rdcn_en_i,line2_diff_time_value_i,
        line2_diff_load_en_i,line2_diff_store_en_i,line2_diff_ls_vaddr_i,line2_diff_ls_paddr_i,line2_diff_store_wdata_i,
        line2_regs_we_diff_i,line2_regs_waddr_diff_i,line2_regs_wdata_diff_i,
        line2_inst_diff_i,line2_pc_diff_i,line2_valid_diff_i
        } = line2_to_diff_bus;       
        
        
/****************************************output code(输出解码)***************************************/
assign error_store = line1_diff_store_en_i&line1_diff_ls_vaddr_i==32'h1c002ec0;
assign error_load = line1_diff_load_en_i&line1_diff_ls_vaddr_i==32'h1c002ec0;
//assign error_o=error_store;
//assign error_o = error_load;
assign error_o = 1'b0;
/*******************************complete logical function (逻辑功能实现)*******************************/
integer handle_whole,handle_simply;

initial
    begin
        //r方式，被读的文件，用于获取激励信号输入值
       // handle1= $fopen("D:/Documents/Hardware_verlog/Teacher_example/txt/51.txt","r");
        //w方式，被写入的文件，用于写入系统函数的输出值
        if(`record_right_trace)begin
            handle_simply= $fopen(`RIGHT_TRACE_WRITE_FILE,"w");
            handle_whole = $fopen(`Test_TRACE_WRITE_FILE_WHOLE ,"w");
        end else begin
            handle_simply= $fopen(`Test_TRACE_WRITE_FILE,"w");
            handle_whole = $fopen(`Test_TRACE_WRITE_FILE_WHOLE ,"w");
            
        end

end
always @(posedge clk)begin    
    if(`simply_trace_record_open)begin
        
        if (line1_regs_we_diff_i&line2_regs_we_diff_i)begin
            $fwrite(handle_simply,$time,"%h %h %h %h\n%h %h %h %h\n", line1_regs_we_diff_i,line1_pc_diff_i,line1_regs_waddr_diff_i,line1_regs_wdata_diff_i,
                                                                            line2_regs_we_diff_i,line2_pc_diff_i,line2_regs_waddr_diff_i,line2_regs_wdata_diff_i
                                                                               );
        end else if (line1_regs_we_diff_i & ~line2_regs_we_diff_i)begin
            $fwrite(handle_simply,$time,"%h %h %h %h\n", line1_regs_we_diff_i,line1_pc_diff_i,line1_regs_waddr_diff_i,line1_regs_wdata_diff_i          
                                                                               );
        end else if (~line1_regs_we_diff_i & line2_regs_we_diff_i)begin
            $fwrite(handle_simply,$time,"%h %h %h %h\n",                               
                                                      line2_regs_we_diff_i,line2_pc_diff_i,line2_regs_waddr_diff_i,line2_regs_wdata_diff_i           
                                                                               );
        end
    end
    
        if(`whole_trace_record_open)begin
             if (line1_valid_diff_i&line2_valid_diff_i)begin
                  //line1
                   $fwrite(handle_whole,"%h\t%h\t",line1_pc_diff_i,line1_inst_diff_i);//2
                    
                    if(line1_regs_we_diff_i&line1_regs_waddr_diff_i!=0)begin
                        $fwrite(handle_whole,"%h\t%h\t%h\t",line1_regs_we_diff_i,line1_regs_waddr_diff_i,line1_regs_wdata_diff_i);//3
                    end
                    
                    
                    if(line1_diff_csr_rstat_en_i)begin
                        $fwrite(handle_whole,"重置例外状态:%h\t",line1_diff_csr_rstat_en_i);
                    end
                    
                    
                    if(line1_diff_load_en_i)begin
                        $fwrite(handle_whole,"load:%h\t%h\t%h\t%h\t\n",line1_diff_load_en_i,line1_diff_ls_vaddr_i,line1_diff_ls_paddr_i&{32{1'b0}},line1_regs_wdata_diff_i); //2     
                    end else if (line1_diff_store_en_i)begin
                        $fwrite(handle_whole,"store:%h\t%h\t%h\t%h\t\n",line1_diff_store_en_i,line1_diff_ls_vaddr_i,line1_diff_ls_paddr_i&{32{1'b0}},line1_diff_store_wdata_i); //3   
                    end else if(line1_diff_rdcn_en_i)begin
                         $fwrite(handle_whole,"rdcn:%h\t%h\t\n",line1_diff_rdcn_en_i,line1_diff_time_value_i); //2                        
//                    end else if (line1_diff_csr_we_o)begin
//                         $fwrite(handle_whole,"csr:%h\t%h\t%h\t\n", line1_diff_csr_we_o,line1_diff_csr_waddr_o,line1_diff_csr_wdata_o); //2                   
                    end else begin
                        $fwrite(handle_whole,"\n");
                    end 
                    
                    //line2
                     $fwrite(handle_whole,"%h\t%h\t",line2_pc_diff_i,line2_inst_diff_i);//2
                    
                    if(line2_regs_we_diff_i&line2_regs_waddr_diff_i!=0)begin
                        $fwrite(handle_whole,"%h\t%h\t%h\t",line2_regs_we_diff_i,line2_regs_waddr_diff_i,line2_regs_wdata_diff_i);//3
                    end
                    
                    
                    if(line2_diff_csr_rstat_en_i)begin
                        $fwrite(handle_whole,"重置例外状态:%h\t",line2_diff_csr_rstat_en_i);
                    end
                    
                    
                    if(line2_diff_load_en_i)begin
                        $fwrite(handle_whole,"load:%h\t%h\t%h\t%h\t\n",line2_diff_load_en_i,line2_diff_ls_vaddr_i,line2_diff_ls_paddr_i&{32{1'b0}},line2_regs_wdata_diff_i); //2     
                    end else if (line2_diff_store_en_i)begin
                        $fwrite(handle_whole,"store:%h\t%h\t%h\t%h\t\n",line2_diff_store_en_i,line2_diff_ls_vaddr_i,line2_diff_ls_paddr_i&{32{1'b0}},line2_diff_store_wdata_i); //3   
                    end else if(line2_diff_rdcn_en_i)begin
                         $fwrite(handle_whole,"rdcn:%h\t%h\t\n",line2_diff_rdcn_en_i,line2_diff_time_value_i); //2                        
//                    end else if (line2_diff_csr_we_o)begin
//                         $fwrite(handle_whole,"csr:%h\t%h\t%h\t\n", line2_diff_csr_we_o,line2_diff_csr_waddr_o,line2_diff_csr_wdata_o); //2                   
                    end else begin
                        $fwrite(handle_whole,"\n");
                    end 
                             
             
                 
             end else if (line1_valid_diff_i & ~line2_valid_diff_i)begin
                    $fwrite(handle_whole,"%h\t%h\t",line1_pc_diff_i,line1_inst_diff_i);//2
                    
                    if(line1_regs_we_diff_i&line1_regs_waddr_diff_i!=0)begin
                        $fwrite(handle_whole,"%h\t%h\t%h\t",line1_regs_we_diff_i,line1_regs_waddr_diff_i,line1_regs_wdata_diff_i);//3
                    end
                    
                    
                    if(line1_diff_csr_rstat_en_i)begin
                        $fwrite(handle_whole,"重置例外状态:%h\t",line1_diff_csr_rstat_en_i);
                    end
                    
                    
                    if(line1_diff_load_en_i)begin
                        $fwrite(handle_whole,"load:%h\t%h\t%h\t%h\t\n",line1_diff_load_en_i,line1_diff_ls_vaddr_i,line1_diff_ls_paddr_i&{32{1'b0}},line1_regs_wdata_diff_i); //2     
                    end else if (line1_diff_store_en_i)begin
                        $fwrite(handle_whole,"store:%h\t%h\t%h\t%h\t\n",line1_diff_store_en_i,line1_diff_ls_vaddr_i,line1_diff_ls_paddr_i&{32{1'b0}},line1_diff_store_wdata_i); //3   
                    end else if(line1_diff_rdcn_en_i)begin
                         $fwrite(handle_whole,"rdcn:%h\t%h\t\n",line1_diff_rdcn_en_i,line1_diff_time_value_i); //2                        
//                    end else if (line1_diff_csr_we_o)begin
//                         $fwrite(handle_whole,"csr:%h\t%h\t%h\t\n", line1_diff_csr_we_o,line1_diff_csr_waddr_o,line1_diff_csr_wdata_o); //2                   
                    end else begin
                        $fwrite(handle_whole,"\n");
                    end 
                    
                                                                                   
             end else if (~line1_valid_diff_i & line2_valid_diff_i)begin
                    $fwrite(handle_whole,"%h\t%h\t",line2_pc_diff_i,line2_inst_diff_i);//2
                    
                    if(line2_regs_we_diff_i&line2_regs_waddr_diff_i!=0)begin
                        $fwrite(handle_whole,"%h\t%h\t%h\t",line2_regs_we_diff_i,line2_regs_waddr_diff_i,line2_regs_wdata_diff_i);//3
                    end
                    
                    
                    if(line2_diff_csr_rstat_en_i)begin
                        $fwrite(handle_whole,"重置例外状态:%h\t",line2_diff_csr_rstat_en_i);
                    end
                    
                    
                    if(line2_diff_load_en_i)begin
                        $fwrite(handle_whole,"load:%h\t%h\t%h\t%h\t\n",line2_diff_load_en_i,line2_diff_ls_vaddr_i,line2_diff_ls_paddr_i&{32{1'b0}},line2_regs_wdata_diff_i); //2     
                    end else if (line2_diff_store_en_i)begin
                        $fwrite(handle_whole,"store:%h\t%h\t%h\t%h\t\n",line2_diff_store_en_i,line2_diff_ls_vaddr_i,line2_diff_ls_paddr_i&{32{1'b0}},line2_diff_store_wdata_i); //3   
                    end else if(line2_diff_rdcn_en_i)begin
                         $fwrite(handle_whole,"rdcn:%h\t%h\t\n",line2_diff_rdcn_en_i,line2_diff_time_value_i); //2                        
//                    end else if (line2_diff_csr_we_o)begin
//                         $fwrite(handle_whole,"csr:%h\t%h\t%h\t\n", line2_diff_csr_we_o,line2_diff_csr_waddr_o,line2_diff_csr_wdata_o); //2                   
                    end else begin
                        $fwrite(handle_whole,"\n");
                    end           
                                                                                   
             end
        end 
  
    
       
end

endmodule
























