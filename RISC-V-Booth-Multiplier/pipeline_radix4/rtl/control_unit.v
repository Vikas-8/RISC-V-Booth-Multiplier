`timescale 1ns / 1ps
// Control Unit for pipelined core - decode stage.
// RegWriteSrc encoding for the write-back mux:
//   00 -> ALUOut (covers R-type, ADDI, LUI [via ALU pass-through], AUIPC)
//   10 -> Data Memory Read Data (LW)
//   11 -> PC+4 (JAL link address)
module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg          RegWrite,
    output reg           MemRead,
    output reg           MemWrite,
    output reg           Branch,
    output reg           ALUSelA,   // 0 = Data1(rs1), 1 = PC (for AUIPC)
    output reg           ALUSelB,   // 0 = Data2(rs2), 1 = immediate
    output reg  [3:0]    ALUOp,
    output reg  [1:0]    RegWriteSrc,
    output reg           IsJAL
);
    localparam OP_R      = 7'b0110011;
    localparam OP_I_ALU  = 7'b0010011;
    localparam OP_I_LD   = 7'b0000011;
    localparam OP_S      = 7'b0100011;
    localparam OP_B      = 7'b1100011;
    localparam OP_U_LUI  = 7'b0110111;
    localparam OP_U_AUI  = 7'b0010111;
    localparam OP_J      = 7'b1101111;

    localparam ALU_ADD   = 4'b0000;
    localparam ALU_SUB   = 4'b0001;
    localparam ALU_AND   = 4'b0010;
    localparam ALU_OR    = 4'b0011;
    localparam ALU_PASSB = 4'b0100;
    localparam ALU_MUL   = 4'b0101;

    always @(*) begin
        RegWrite    = 1'b0;
        MemRead     = 1'b0;
        MemWrite    = 1'b0;
        Branch      = 1'b0;
        ALUSelA     = 1'b0;
        ALUSelB     = 1'b0;
        ALUOp       = ALU_ADD;
        RegWriteSrc = 2'b00;
        IsJAL       = 1'b0;

        case (opcode)
            OP_R: begin
                RegWrite = 1'b1;
                case ({funct7, funct3})
                    10'b0000000_000: ALUOp = ALU_ADD;
                    10'b0100000_000: ALUOp = ALU_SUB;
                    10'b0000000_111: ALUOp = ALU_AND;
                    10'b0000000_110: ALUOp = ALU_OR;
                    10'b0000001_000: ALUOp = ALU_MUL; // MUL
                    default:         ALUOp = ALU_ADD;
                endcase
            end
            OP_I_ALU: begin
                RegWrite = 1'b1;
                ALUSelB  = 1'b1;
                ALUOp    = ALU_ADD;
            end
            OP_I_LD: begin
                RegWrite    = 1'b1;
                ALUSelB     = 1'b1;
                ALUOp       = ALU_ADD;
                MemRead     = 1'b1;
                RegWriteSrc = 2'b10;
            end
            OP_S: begin
                ALUSelB  = 1'b1;
                ALUOp    = ALU_ADD;
                MemWrite = 1'b1;
            end
            OP_B: begin
                Branch = 1'b1;
            end
            OP_U_LUI: begin
                RegWrite = 1'b1;
                ALUSelB  = 1'b1;   // immediate
                ALUOp    = ALU_PASSB;
            end
            OP_U_AUI: begin
                RegWrite = 1'b1;
                ALUSelA  = 1'b1;   // PC
                ALUSelB  = 1'b1;   // immediate
                ALUOp    = ALU_ADD;
            end
            OP_J: begin
                RegWrite    = 1'b1;
                RegWriteSrc = 2'b11;
                IsJAL       = 1'b1;
            end
            default: ;
        endcase
    end
endmodule
