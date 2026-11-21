`timescale 1ns / 1ps
// Branch Comparator - matches "Branch Comparator" block in Fig. 2
module branch_comparator (
    input  wire [31:0] Data1,
    input  wire [31:0] Data2,
    output wire         BEq
);
    assign BEq = (Data1 == Data2);
endmodule
