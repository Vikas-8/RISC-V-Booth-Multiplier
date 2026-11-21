`timescale 1ns / 1ps
module alu (
    input  wire [31:0] ALUInA,
    input  wire [31:0] ALUInB,
    input  wire [3:0]  ALUOp,
    output reg  [31:0] ALUOut,
    output wire         FZ
);
    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_MUL = 4'b0100;   // RV32M MUL: lower 32 bits of the product

    always @(*) begin
        case (ALUOp)
            ALU_ADD: ALUOut = ALUInA + ALUInB;
            ALU_SUB: ALUOut = ALUInA - ALUInB;
            ALU_AND: ALUOut = ALUInA & ALUInB;
            ALU_OR : ALUOut = ALUInA | ALUInB;
            ALU_MUL: ALUOut = ALUInA * ALUInB;
            default: ALUOut = 32'b0;
        endcase
    end
    assign FZ = (ALUOut == 32'b0);
endmodule
