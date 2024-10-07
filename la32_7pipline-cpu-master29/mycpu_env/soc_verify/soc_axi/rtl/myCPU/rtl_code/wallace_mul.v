//`include "def_cpu.v"

module wallace_mul(
    input  wire sign,
    input  wire [31:0] x,
    input  wire [31:0] y,
    output wire [63:0] r
);

    wire co00_1, co01_1, co02_1, co03_1, co10_1, co11_1, co20_1;
    wire co00_2, co01_2, co02_2, co03_2, co10_2, co11_2, co20_2;
    wire [63:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15, pp16 , pp17;
    wire [63:0] s00, s01, s02, s03, s10, s11;
    wire [63:0] c00, c01, c02, c03, c10, c11;
    wire [63:0] sum, carray;

    wire [32:0] x_ext = sign? {x[31], x} : {1'b0, x};
    wire [33:0] y_ext = sign? {{2{y[31]}}, y} : {2'b00, y};

    wire [33:0] c;

    booth_4 u_b0  (.x(x_ext), .y({y_ext[1:0], 1'b0}), .pp(pp0), .c(c[1 :0 ]));
    booth_4 u_b1  (.x(x_ext), .y(y_ext[3 :1 ]), .pp(pp1 ), .c(c[3 :2 ]));
    booth_4 u_b2  (.x(x_ext), .y(y_ext[5 :3 ]), .pp(pp2 ), .c(c[5 :4 ]));
    booth_4 u_b3  (.x(x_ext), .y(y_ext[7 :5 ]), .pp(pp3 ), .c(c[7 :6 ]));
    booth_4 u_b4  (.x(x_ext), .y(y_ext[9 :7 ]), .pp(pp4 ), .c(c[9 :8 ]));
    booth_4 u_b5  (.x(x_ext), .y(y_ext[11:9 ]), .pp(pp5 ), .c(c[11:10]));
    booth_4 u_b6  (.x(x_ext), .y(y_ext[13:11]), .pp(pp6 ), .c(c[13:12]));
    booth_4 u_b7  (.x(x_ext), .y(y_ext[15:13]), .pp(pp7 ), .c(c[15:14]));
    booth_4 u_b8  (.x(x_ext), .y(y_ext[17:15]), .pp(pp8 ), .c(c[17:16]));
    booth_4 u_b9  (.x(x_ext), .y(y_ext[19:17]), .pp(pp9 ), .c(c[19:18]));
    booth_4 u_b10 (.x(x_ext), .y(y_ext[21:19]), .pp(pp10), .c(c[21:20]));
    booth_4 u_b11 (.x(x_ext), .y(y_ext[23:21]), .pp(pp11), .c(c[23:22]));
    booth_4 u_b12 (.x(x_ext), .y(y_ext[25:23]), .pp(pp12), .c(c[25:24]));
    booth_4 u_b13 (.x(x_ext), .y(y_ext[27:25]), .pp(pp13), .c(c[27:26]));
    booth_4 u_b14 (.x(x_ext), .y(y_ext[29:27]), .pp(pp14), .c(c[29:28]));
    booth_4 u_b15 (.x(x_ext), .y(y_ext[31:29]), .pp(pp15), .c(c[31:30]));
    booth_4 u_b16 (.x(x_ext), .y(y_ext[33:31]), .pp(pp16), .c(c[33:32]));

    assign pp17 = c | 64'b0;

    csa4 u_c00 (.x1(pp0      ), .x2(pp1 << 2 ), .x3(pp2 << 4 ), .x4(pp3 << 6 ), .sum(s00), .carray(c00));
    csa5 u_c01 (.x1(pp4 << 8 ), .x2(pp5 << 10), .x3(pp6 << 12), .x4(pp7 << 14), .x5(pp8 << 16), .sum(s01), .carray(c01));
    csa4 u_c02 (.x1(pp9 << 18), .x2(pp10<< 20), .x3(pp11<< 22), .x4(pp12<< 24), .sum(s02), .carray(c02));
    csa5 u_c03 (.x1(pp13<< 26), .x2(pp14<< 28), .x3(pp15<< 30), .x4(pp16<< 32), .x5(pp17     ), .sum(s03), .carray(c03));

    csa4 u_c10 (.x1(s00      ), .x2(c00 << 1 ), .x3(s01      ), .x4(c01 << 1 ), .sum(s10), .carray(c10));
    csa4 u_c11 (.x1(s02      ), .x2(c02 << 1 ), .x3(s03      ), .x4(c03 << 1 ), .sum(s11), .carray(c11));

    csa4 u_c20 (.x1(s10      ), .x2(c10 << 1 ), .x3(s11      ), .x4(c11 << 1 ), .sum(sum), .carray(carray));

     assign r = sum + (carray << 1);
    //fa64 u_fa64(.a(sum), .b(carray << 1), .cin(1'b0), .sub(1'b0), .s(r), .cout());
    
endmodule

// radix-4 booth encoding
module booth_4(
    input  wire [32:0] x,
    input  wire [2 :0] y,
    output wire [63:0] pp,
    output wire [1 :0] c
);

wire [32:0] xn = ~x;
assign pp = (y == 3'b001 | y == 3'b010)? {{31{x [32]}}, x } :
            (y == 3'b101 | y == 3'b110)? {{31{xn[32]}}, xn} :
            (y == 3'b011)? {{30{x [32]}}, x , 1'b0} :
            (y == 3'b100)? {{30{xn[32]}}, xn, 1'b0} : 32'b0;

assign c  = (y == 3'b101 | y == 3'b110)? 2'b01 :
            (y == 3'b100)? 2'b10 : 2'b00;

endmodule

// carry saving adder (4:2)
module csa4 (
    input  wire [63 : 0] x1,
    input  wire [63 : 0] x2,
    input  wire [63 : 0] x3,
    input  wire [63 : 0] x4,

    output wire [63 : 0] sum,
    output wire [63 : 0] carray
);

wire [64:0] cio_array = {((x4 & x3 | x3 & x2 | x4 & x2)), 1'b0};

assign sum    = x1 ^ x2 ^ x3 ^ x4 ^ cio_array[63:0];
assign carray = (x1 ^ x2 ^ x3 ^ x4) & cio_array[63:0] | ~(x1 ^ x2 ^ x3 ^ x4) & x1;

endmodule

//carry saving adder (5:2)
module csa5 (
    input  wire [63 : 0] x1,
    input  wire [63 : 0] x2,
    input  wire [63 : 0] x3,
    input  wire [63 : 0] x4,
    input  wire [63 : 0] x5,

    output wire [63 : 0] sum,
    output wire [63 : 0] carray
);

wire [63:0] xor12  = x1 ^ x2;
wire [63:0] xor123 = xor12 ^ x3;
wire [63:0] xor45  = x4 ^ x5;

wire [64:0] cio1_array = {((x1 | x2) & x3 |  x1 & x2), 1'b0};
wire [64:0] cio2_array = {(xor45 & cio1_array[63:0] | ~xor45 & x4), 1'b0};

wire [63:0] xor456 = xor45 ^ cio1_array[63:0];

wire [63:0] t = xor123 ^ xor456;

assign sum    = t ^ cio2_array[63:0];
assign carray = t & cio2_array[63:0] | (~t) & xor123;

endmodule