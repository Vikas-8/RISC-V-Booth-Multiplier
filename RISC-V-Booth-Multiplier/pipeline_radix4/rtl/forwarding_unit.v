`timescale 1ns / 1ps
// Standard EX-stage forwarding: resolves RAW hazards where the producing
// instruction is currently in EX/MEM (1 instr ahead) or MEM/WB (2 instr
// ahead) of the consuming instruction now in EX.
// ForwardA/B: 00 = no forward (use ID/EX value), 10 = forward from EX/MEM,
// 01 = forward from MEM/WB.
module forwarding_unit (
    input  wire [4:0] rs1_EX, rs2_EX,
    input  wire [4:0] rd_MEM,
    input  wire        RegWrite_MEM,
    input  wire [4:0] rd_WB,
    input  wire        RegWrite_WB,
    output reg  [1:0] ForwardA,
    output reg  [1:0] ForwardB
);
    always @(*) begin
        // ForwardA
        if (RegWrite_MEM && (rd_MEM != 5'b0) && (rd_MEM == rs1_EX))
            ForwardA = 2'b10;
        else if (RegWrite_WB && (rd_WB != 5'b0) && (rd_WB == rs1_EX))
            ForwardA = 2'b01;
        else
            ForwardA = 2'b00;

        // ForwardB
        if (RegWrite_MEM && (rd_MEM != 5'b0) && (rd_MEM == rs2_EX))
            ForwardB = 2'b10;
        else if (RegWrite_WB && (rd_WB != 5'b0) && (rd_WB == rs2_EX))
            ForwardB = 2'b01;
        else
            ForwardB = 2'b00;
    end
endmodule
