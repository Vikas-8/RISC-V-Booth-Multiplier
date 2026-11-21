`timescale 1ns / 1ps
module alu (
    input  wire [31:0] ALUInA,
    input  wire [31:0] ALUInB,
    input  wire [3:0]  ALUOp,
    output reg  [31:0] ALUOut,
    output wire         FZ
);
    localparam ALU_ADD   = 4'b0000;
    localparam ALU_SUB   = 4'b0001;
    localparam ALU_AND   = 4'b0010;
    localparam ALU_OR    = 4'b0011;
    localparam ALU_PASSB = 4'b0100; // used for LUI: ALUOut = ALUInB (immediate)
    localparam ALU_MUL   = 4'b0101; // MUL (RV32M): lower 32 bits of Booth product

    // Operand isolation: Booth inputs are forced to 0 unless a MUL is in EX,
    // so the multiplier does not toggle (dynamic power) for other instructions.
    wire        mul_en = (ALUOp == ALU_MUL);
    wire [31:0] mul_a  = mul_en ? ALUInA : 32'b0;
    wire [31:0] mul_b  = mul_en ? ALUInB : 32'b0;
    wire [63:0] mul_p;
    booth_radix4_mul #(32) u_booth (.multiplicand(mul_a), .multiplier(mul_b), .product(mul_p));

    always @(*) begin
        case (ALUOp)
            ALU_ADD:   ALUOut = ALUInA + ALUInB;
            ALU_SUB:   ALUOut = ALUInA - ALUInB;
            ALU_AND:   ALUOut = ALUInA & ALUInB;
            ALU_OR:    ALUOut = ALUInA | ALUInB;
            ALU_PASSB: ALUOut = ALUInB;
            ALU_MUL:   ALUOut = mul_p[31:0];
            default:   ALUOut = 32'b0;
        endcase
    end

    assign FZ = (ALUOut == 32'b0);
endmodule
