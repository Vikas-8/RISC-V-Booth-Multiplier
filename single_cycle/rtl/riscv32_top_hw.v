`timescale 1ns / 1ps
module riscv32_top_hw (
    input  wire       clk,
    input  wire       rst,
    output reg  [7:0] debug_out
);
    wire [31:0] pc, wb;
    riscv32_top #(.PRELOAD(1)) u_core (.clk(clk), .rst(rst), .debug_pc(pc), .debug_wb(wb));

    always @(posedge clk or posedge rst)
        if (rst) debug_out <= 8'b0;
        else     debug_out <= wb[7:0] ^ wb[15:8] ^ wb[23:16] ^ wb[31:24] ^ pc[9:2];
endmodule