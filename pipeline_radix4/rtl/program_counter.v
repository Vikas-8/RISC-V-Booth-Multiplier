`timescale 1ns / 1ps
module program_counter (
    input  wire        clk,
    input  wire        rst,
    input  wire        PCWrite,   // low during load-use stall
    input  wire [31:0] PCIn,
    output reg  [31:0] PCOut
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            PCOut <= 32'b0;
        else if (PCWrite)
            PCOut <= PCIn;
    end
endmodule
