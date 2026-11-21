`timescale 1ns / 1ps
// Control Unit - matches the blue "Control Unit" block in Fig. 2
// Outputs exactly the signal set shown in the figure:
// PCSel, PCLd, IMWEn, IGWEn, RFWEn, BrC, ALUSelB, ALUSelA, ALUOp,
// DMWrite, DMRead, RFSel
//
// RFSel write-back mux mapping (feeds the 4:1 mux into Register File D_In):
//   00 -> ALUOut        (R-type, ADDI results)
//   01 -> IGOut          (LUI - immediate loaded directly)
//   10 -> Data_Memory Read Data (LW)
//   11 -> PC + 4          (JAL link address)

module control_unit (
    input  wire [6:0] opcode,   // IMOut[6:0]
    input  wire [2:0] funct3,   // IMOut[14:12]
    input  wire [6:0] funct7,   // IMOut[31:25]
    input  wire        BEq,

    output reg          PCSel,
    output wire          PCLd,
    output reg           IGWEn,
    output reg           RFWEn,
    output reg           BrC,
    output reg           ALUSelA,
    output reg           ALUSelB,
    output reg  [3:0]    ALUOp,
    output reg           DMWrite,
    output reg           DMRead,
    output reg  [1:0]    RFSel
);
    localparam OP_R      = 7'b0110011;
    localparam OP_I_ALU  = 7'b0010011; // ADDI
    localparam OP_I_LD   = 7'b0000011; // LW
    localparam OP_S      = 7'b0100011; // SW
    localparam OP_B      = 7'b1100011; // BEQ
    localparam OP_U_LUI  = 7'b0110111;
    localparam OP_U_AUI  = 7'b0010111; // AUIPC
    localparam OP_J      = 7'b1101111; // JAL

    localparam ALU_ADD = 4'b0000;
    localparam ALU_SUB = 4'b0001;
    localparam ALU_AND = 4'b0010;
    localparam ALU_OR  = 4'b0011;
    localparam ALU_MUL = 4'b0100;

    assign PCLd = 1'b1; // single-cycle: PC updates every clock edge

    always @(*) begin
        // safe defaults (NOP / unimplemented opcode)
        PCSel   = 1'b0;
        IGWEn   = 1'b1;
        RFWEn   = 1'b0;
        BrC     = 1'b0;
        ALUSelA = 1'b0;
        ALUSelB = 1'b0;
        ALUOp   = ALU_ADD;
        DMWrite = 1'b0;
        DMRead  = 1'b0;
        RFSel   = 2'b00;

        case (opcode)
            OP_R: begin
                RFWEn   = 1'b1;
                ALUSelA = 1'b0;  // Data1
                ALUSelB = 1'b0;  // Data2
                RFSel   = 2'b00; // ALUOut
                case ({funct7, funct3})
                    10'b0000000_000: ALUOp = ALU_ADD; // ADD
                    10'b0100000_000: ALUOp = ALU_SUB; // SUB
                    10'b0000000_111: ALUOp = ALU_AND; // AND
                    10'b0000000_110: ALUOp = ALU_OR;  // OR
                    10'b0000001_000: ALUOp = ALU_MUL; // MUL
                    default:         ALUOp = ALU_ADD;
                endcase
            end

            OP_I_ALU: begin // ADDI
                RFWEn   = 1'b1;
                ALUSelA = 1'b0;  // Data1
                ALUSelB = 1'b1;  // IGOut
                ALUOp   = ALU_ADD;
                RFSel   = 2'b00; // ALUOut
            end

            OP_I_LD: begin // LW
                RFWEn   = 1'b1;
                ALUSelA = 1'b0;
                ALUSelB = 1'b1;  // base + offset
                ALUOp   = ALU_ADD;
                DMRead  = 1'b1;
                RFSel   = 2'b10; // Data Memory Read Data
            end

            OP_S: begin // SW
                ALUSelA = 1'b0;
                ALUSelB = 1'b1;  // base + offset
                ALUOp   = ALU_ADD;
                DMWrite = 1'b1;
            end

            OP_B: begin // BEQ
                BrC   = 1'b1;
                PCSel = BEq;     // take branch if equal
            end

            OP_U_LUI: begin // LUI
                RFWEn = 1'b1;
                RFSel = 2'b01;   // IGOut straight into register
            end

            OP_U_AUI: begin // AUIPC
                RFWEn   = 1'b1;
                ALUSelA = 1'b1;  // PC
                ALUSelB = 1'b1;  // IGOut
                ALUOp   = ALU_ADD;
                RFSel   = 2'b00; // ALUOut = PC + imm
            end

            OP_J: begin // JAL
                RFWEn = 1'b1;
                RFSel = 2'b11;   // link address = PC + 4
                PCSel = 1'b1;    // jump
            end

            default: ; // NOP - all defaults already safe
        endcase
    end
endmodule
