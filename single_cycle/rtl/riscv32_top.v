`timescale 1ns / 1ps
// Single-cycle 32-bit RV32I processor (ADD SUB MUL AND OR ADDI LW SW BEQ LUI AUIPC JAL)
module riscv32_top #(parameter PRELOAD = 0) (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] debug_pc,
    output wire [31:0] debug_wb
);
    // ---------------- PC ----------------
    wire [31:0] PCOut, PCIn, PCPlus4, PCBranch;
    wire        PCSel, PCLd;
    program_counter u_pc (.clk(clk), .rst(rst), .PCLd(PCLd), .PCIn(PCIn), .PCOut(PCOut));
    assign PCPlus4 = PCOut + 32'd4;

    // ---------------- Instruction memory ----------------
    wire [31:0] IMOut;
    instruction_memory #(.PRELOAD(PRELOAD)) u_imem (.addr(PCOut), .instr(IMOut));

    // ---------------- Decode ----------------
    wire [6:0] opcode = IMOut[6:0];
    wire [2:0] funct3 = IMOut[14:12];
    wire [6:0] funct7 = IMOut[31:25];
    wire [4:0] rd     = IMOut[11:7];
    wire [4:0] rs1    = IMOut[19:15];
    wire [4:0] rs2    = IMOut[24:20];

    // ---------------- Register file ----------------
    wire [31:0] Data1, Data2, D_In;
    wire        RFWEn;
    register_file #(.PRELOAD(PRELOAD)) u_rf (
        .clk(clk), .RFWEn(RFWEn), .rd(rd), .rs1(rs1), .rs2(rs2),
        .D_In(D_In), .Data1(Data1), .Data2(Data2));

    // ---------------- Immediate / branch ----------------
    wire [31:0] IGOut;
    immediate_generator u_immgen (.IMOut(IMOut), .IGOut(IGOut));

    wire BEq;
    branch_comparator u_bcomp (.Data1(Data1), .Data2(Data2), .BEq(BEq));

    assign PCBranch = PCOut + IGOut;
    mux2to1 #(32) u_pcsel (.sel(PCSel), .in0(PCPlus4), .in1(PCBranch), .out(PCIn));

    // ---------------- ALU ----------------
    wire [31:0] ALUInA, ALUInB, ALUOut;
    wire        ALUSelA, ALUSelB, FZ;
    wire [3:0]  ALUOp;
    mux2to1 #(32) u_aluA (.sel(ALUSelA), .in0(Data1), .in1(PCOut), .out(ALUInA));
    mux2to1 #(32) u_aluB (.sel(ALUSelB), .in0(Data2), .in1(IGOut), .out(ALUInB));
    alu u_alu (.ALUInA(ALUInA), .ALUInB(ALUInB), .ALUOp(ALUOp), .ALUOut(ALUOut), .FZ(FZ));

    // ---------------- Data memory ----------------
    wire [31:0] ReadData;
    wire        DMWrite, DMRead;
    data_memory u_dmem (.clk(clk), .DMWrite(DMWrite), .DMRead(DMRead),
        .Address(ALUOut), .Write_Data(Data2), .Read_Data(ReadData));

    // ---------------- Write back ----------------
    wire [1:0] RFSel;
    mux4to1 #(32) u_wbmux (.sel(RFSel), .in00(ALUOut), .in01(IGOut),
        .in10(ReadData), .in11(PCPlus4), .out(D_In));

    // ---------------- Control ----------------
    wire IGWEn, BrC;
    control_unit u_ctrl (
        .opcode(opcode), .funct3(funct3), .funct7(funct7), .BEq(BEq),
        .PCSel(PCSel), .PCLd(PCLd), .IGWEn(IGWEn), .RFWEn(RFWEn), .BrC(BrC),
        .ALUSelA(ALUSelA), .ALUSelB(ALUSelB), .ALUOp(ALUOp),
        .DMWrite(DMWrite), .DMRead(DMRead), .RFSel(RFSel));

    assign debug_pc = PCOut;
    assign debug_wb = D_In;
endmodule
