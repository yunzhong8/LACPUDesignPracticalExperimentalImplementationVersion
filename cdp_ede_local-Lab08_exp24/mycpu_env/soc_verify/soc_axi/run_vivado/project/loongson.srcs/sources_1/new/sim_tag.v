`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/05/30 11:04:51
// Design Name: 
// Module Name: sim_tag
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sim_tag(

    );
    
    reg clk;
    reg req;
    reg tagv_wea    ;
    reg [7:0]tagv_addra;
    reg [20:0]tagv_wdata_i;
    wire [20:0]tagv_rdata_o;
    
    
    
    initial begin
         clk=1;
         req=1'b0             ;
         tagv_wea =1'b0          ;
         #9 req=1'b1             ;
          tagv_wea =1'b1          ;
          tagv_addra = 8'd2       ;
          tagv_wdata_i = 21'd001  ;
         #5 tagv_wdata_i = 21'd100  ;
         #6  req = 1;
             tagv_wea =1'b0         ;
             tagv_wdata_i = 21'd000  ;
             tagv_addra = 8'd2 ; 
         #10 req = 1;
             tagv_wea =1'b0          ;
             tagv_wdata_i = 21'd1  ;
            tagv_addra = 8'd2 ; 
         #10 req = 1;
             tagv_wea =1'b0          ;
             tagv_wdata_i = 21'd0  ;
            tagv_addra = 8'd2 ; 
        #10 req = 1;
             tagv_wea =1'b0          ;
             tagv_wdata_i = 21'd0  ;
            tagv_addra = 8'd2 ; 
        # 100
            tagv_wdata_i = 21'd100  ;
    end
    always   #5
        begin
            clk = ~clk;
        end
        
        
      tagv_ram tagv_ram_item (                                                         
       .clka             ( clk         ),    // input wire clka                        
       .ena              ( req       ),      // input wire ena                       
       .wea              ( tagv_wea    ),      // input wire [0 : 0] wea               
       .addra            ( tagv_addra  ),  // input wire [7 : 0] addra                 
       .dina             ( tagv_wdata_i),    // input wire [20 : 0] dina               
       .douta            ( tagv_rdata_o)  // output wire [20 : 0] douta                
     );                                                                                
        
        
        
endmodule
