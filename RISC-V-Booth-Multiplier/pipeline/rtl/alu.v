`timescale 1ns / 1ps

module alu (
    input  wire [31:0] ALUInA,
    input  wire [31:0] ALUInB,
    input  wire [3:0]  ALUOp,
    output reg  [31:0] ALUOut,
    output wire        FZ
);

    localparam ALU_ADD   = 4'b0000;
    localparam ALU_SUB   = 4'b0001;
    localparam ALU_AND   = 4'b0010;
    localparam ALU_OR    = 4'b0011;
    localparam ALU_PASSB = 4'b0100;
    localparam ALU_MUL   = 4'b0101;

    // Shared adder/subtractor (bit0 = 1 only for SUB among ADD/SUB)
    wire        is_sub     = ALUOp[0];
    wire [31:0] add_result = ALUInA + (ALUInB ^ {32{is_sub}}) + is_sub;

    // Multiplier mapped to a DSP block
    (* use_dsp = "yes" *) wire [31:0] mul_result = ALUInA * ALUInB;

    always @(*) begin
        case (ALUOp)
            ALU_ADD,
            ALU_SUB:   ALUOut = add_result;
            ALU_AND:   ALUOut = ALUInA & ALUInB;
            ALU_OR:    ALUOut = ALUInA | ALUInB;
            ALU_PASSB: ALUOut = ALUInB;
            ALU_MUL:   ALUOut = mul_result;
            default:   ALUOut = 32'b0;
        endcase
    end

    // Zero flag from operand equality (shorter path than checking ALUOut)
    assign FZ = (ALUInA == ALUInB);

endmodule