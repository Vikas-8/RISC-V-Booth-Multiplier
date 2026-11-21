// Synthesis top for the Radix-8 registered multiplier
`timescale 1ns/1ps
module top_radix8 (
    input  wire               clk, rst, in_valid,
    input  wire signed [31:0] a, b,
    output wire               out_valid,
    output wire signed [63:0] p
);
    booth_pipe_wrapper u (.clk(clk), .rst(rst), .in_valid(in_valid),
                          .a(a), .b(b), .out_valid(out_valid), .p(p));
endmodule
