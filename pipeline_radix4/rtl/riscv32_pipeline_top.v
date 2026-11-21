`timescale 1ns / 1ps
module riscv32_pipeline_top (
    input wire clk,
    input wire rst
);

    // =================== IF stage ===================
    wire [31:0] PCOut, PCIn, PCPlus4, BranchTarget;
    wire        PCWrite, PCSrc;

    program_counter u_pc (
        .clk(clk), .rst(rst), .PCWrite(PCWrite), .PCIn(PCIn), .PCOut(PCOut)
    );
    assign PCPlus4 = PCOut + 32'd4;

    wire [31:0] IF_instr;
    instruction_memory u_imem (.addr(PCOut), .instr(IF_instr));

    // =================== IF/ID register ===================
    wire        hazard_stall;
    wire [31:0] IFID_instr, IFID_PC;

    if_id_reg u_ifid (
        .clk(clk), .rst(rst), .stall(hazard_stall), .flush(PCSrc),
        .instr_in(IF_instr), .pc_in(PCOut),
        .instr_out(IFID_instr), .pc_out(IFID_PC)
    );

    // =================== ID stage ===================
    wire [6:0] ID_opcode = IFID_instr[6:0];
    wire [2:0] ID_funct3 = IFID_instr[14:12];
    wire [6:0] ID_funct7 = IFID_instr[31:25];
    wire [4:0] ID_rd     = IFID_instr[11:7];
    wire [4:0] ID_rs1    = IFID_instr[19:15];
    wire [4:0] ID_rs2    = IFID_instr[24:20];

    wire ID_RegWrite, ID_MemRead, ID_MemWrite, ID_Branch;
    wire ID_ALUSelA, ID_ALUSelB, ID_IsJAL;
    wire [3:0] ID_ALUOp;
    wire [1:0] ID_RegWriteSrc;

    control_unit u_ctrl (
        .opcode(ID_opcode), .funct3(ID_funct3), .funct7(ID_funct7),
        .RegWrite(ID_RegWrite), .MemRead(ID_MemRead), .MemWrite(ID_MemWrite),
        .Branch(ID_Branch), .ALUSelA(ID_ALUSelA), .ALUSelB(ID_ALUSelB),
        .ALUOp(ID_ALUOp), .RegWriteSrc(ID_RegWriteSrc), .IsJAL(ID_IsJAL)
    );

    // register file (written by WB stage, read here)
    wire [31:0] RF_Data1, RF_Data2, WB_D_In;
    wire        WB_RegWrite;
    wire [4:0]  WB_rd;

    register_file u_rf (
        .clk(clk), .RFWEn(WB_RegWrite), .rd(WB_rd),
        .rs1(ID_rs1), .rs2(ID_rs2), .D_In(WB_D_In),
        .Data1(RF_Data1), .Data2(RF_Data2)
    );

    // immediate
    wire [31:0] ID_Imm;
    immediate_generator u_immgen (.IMOut(IFID_instr), .IGOut(ID_Imm));

    // EX/MEM and MEM/WB rd/RegWrite needed for branch forwarding (declared below, used here)
    wire [4:0]  EXMEM_rd, MEMWB_rd;
    wire        EXMEM_RegWrite, MEMWB_RegWrite;
    wire [31:0] EXMEM_ALUOut;

    wire [31:0] BF_Data1, BF_Data2;
    branch_forward_unit u_bfwd (
        .rs1_ID(ID_rs1), .rs2_ID(ID_rs2),
        .rd_EXMEM(EXMEM_rd), .RegWrite_EXMEM(EXMEM_RegWrite), .ALUOut_EXMEM(EXMEM_ALUOut),
        .rd_MEMWB(MEMWB_rd), .RegWrite_MEMWB(MEMWB_RegWrite), .WBData_MEMWB(WB_D_In),
        .RegFileData1(RF_Data1), .RegFileData2(RF_Data2),
        .Data1(BF_Data1), .Data2(BF_Data2)
    );

    wire BEq;
    branch_comparator u_bcomp (.Data1(BF_Data1), .Data2(BF_Data2), .BEq(BEq));

    assign BranchTarget = IFID_PC + ID_Imm;
    wire PCSrc_raw = (ID_Branch && BEq) || ID_IsJAL;
    assign PCSrc = PCSrc_raw && !hazard_stall;
    assign PCIn  = PCSrc ? BranchTarget : PCPlus4;

    wire [31:0] IFID_PCPlus4 = IFID_PC + 32'd4;

    // hazard detection (load-use)
    wire [4:0] EX_rd_forhazard;   // ID/EX.rd (declared below)
    wire       EX_MemRead_forhazard;
    hazard_unit u_hazard (
        .MemRead_EX(EX_MemRead_forhazard), .rd_EX(EX_rd_forhazard),
        .rs1_ID(ID_rs1), .rs2_ID(ID_rs2), .stall(hazard_stall)
    );
    assign PCWrite = !hazard_stall;

    // =================== ID/EX register ===================
    wire EX_RegWrite, EX_MemRead, EX_MemWrite, EX_Branch;
    wire EX_ALUSelA, EX_ALUSelB, EX_IsJAL;
    wire [3:0] EX_ALUOp;
    wire [1:0] EX_RegWriteSrc;
    wire [31:0] EX_PC, EX_Data1, EX_Data2, EX_Imm, EX_PCPlus4;
    wire [4:0]  EX_rd, EX_rs1, EX_rs2;

    id_ex_reg u_idex (
        .clk(clk), .rst(rst), .flush(hazard_stall),
        .RegWrite_in(ID_RegWrite), .MemRead_in(ID_MemRead), .MemWrite_in(ID_MemWrite),
        .Branch_in(ID_Branch), .ALUSelA_in(ID_ALUSelA), .ALUSelB_in(ID_ALUSelB),
        .IsJAL_in(ID_IsJAL), .ALUOp_in(ID_ALUOp), .RegWriteSrc_in(ID_RegWriteSrc),
        .PC_in(IFID_PC), .Data1_in(RF_Data1), .Data2_in(RF_Data2),
        .Imm_in(ID_Imm), .PCPlus4_in(IFID_PCPlus4),
        .rd_in(ID_rd), .rs1_in(ID_rs1), .rs2_in(ID_rs2),

        .RegWrite_out(EX_RegWrite), .MemRead_out(EX_MemRead), .MemWrite_out(EX_MemWrite),
        .Branch_out(EX_Branch), .ALUSelA_out(EX_ALUSelA), .ALUSelB_out(EX_ALUSelB),
        .IsJAL_out(EX_IsJAL), .ALUOp_out(EX_ALUOp), .RegWriteSrc_out(EX_RegWriteSrc),
        .PC_out(EX_PC), .Data1_out(EX_Data1), .Data2_out(EX_Data2),
        .Imm_out(EX_Imm), .PCPlus4_out(EX_PCPlus4),
        .rd_out(EX_rd), .rs1_out(EX_rs1), .rs2_out(EX_rs2)
    );
    assign EX_rd_forhazard      = EX_rd;
    assign EX_MemRead_forhazard = EX_MemRead;

    // =================== EX stage ===================
    wire [1:0] ForwardA, ForwardB;
    forwarding_unit u_fwd (
        .rs1_EX(EX_rs1), .rs2_EX(EX_rs2),
        .rd_MEM(EXMEM_rd), .RegWrite_MEM(EXMEM_RegWrite),
        .rd_WB(MEMWB_rd), .RegWrite_WB(WB_RegWrite),
        .ForwardA(ForwardA), .ForwardB(ForwardB)
    );

    reg [31:0] FwdA_val, FwdB_val;
    always @(*) begin
        case (ForwardA)
            2'b10:   FwdA_val = EXMEM_ALUOut;
            2'b01:   FwdA_val = WB_D_In;
            default: FwdA_val = EX_Data1;
        endcase
        case (ForwardB)
            2'b10:   FwdB_val = EXMEM_ALUOut;
            2'b01:   FwdB_val = WB_D_In;
            default: FwdB_val = EX_Data2;
        endcase
    end

    wire [31:0] ALUInA = EX_ALUSelA ? EX_PC  : FwdA_val;
    wire [31:0] ALUInB = EX_ALUSelB ? EX_Imm : FwdB_val;

    wire [31:0] EX_ALUOut_wire;
    wire        EX_FZ;
    alu u_alu (.ALUInA(ALUInA), .ALUInB(ALUInB), .ALUOp(EX_ALUOp),
               .ALUOut(EX_ALUOut_wire), .FZ(EX_FZ));

    // =================== EX/MEM register ===================
    wire MEM_RegWrite, MEM_MemRead, MEM_MemWrite;
    wire [1:0] MEM_RegWriteSrc;
    wire [31:0] MEM_ALUOut, MEM_WriteData, MEM_PCPlus4;
    wire [4:0]  MEM_rd;

    ex_mem_reg u_exmem (
        .clk(clk), .rst(rst),
        .RegWrite_in(EX_RegWrite), .MemRead_in(EX_MemRead), .MemWrite_in(EX_MemWrite),
        .RegWriteSrc_in(EX_RegWriteSrc), .ALUOut_in(EX_ALUOut_wire),
        .WriteData_in(FwdB_val), .PCPlus4_in(EX_PCPlus4), .rd_in(EX_rd),

        .RegWrite_out(MEM_RegWrite), .MemRead_out(MEM_MemRead), .MemWrite_out(MEM_MemWrite),
        .RegWriteSrc_out(MEM_RegWriteSrc), .ALUOut_out(MEM_ALUOut),
        .WriteData_out(MEM_WriteData), .PCPlus4_out(MEM_PCPlus4), .rd_out(MEM_rd)
    );
    assign EXMEM_rd       = MEM_rd;
    assign EXMEM_RegWrite = MEM_RegWrite;
    assign EXMEM_ALUOut   = MEM_ALUOut;

    // =================== MEM stage ===================
    wire [31:0] MEM_ReadData;
    data_memory u_dmem (
        .clk(clk), .MemWrite(MEM_MemWrite), .MemRead(MEM_MemRead),
        .Address(MEM_ALUOut), .Write_Data(MEM_WriteData), .Read_Data(MEM_ReadData)
    );

    // =================== MEM/WB register ===================
    wire [1:0] WB_RegWriteSrc;
    wire [31:0] WB_ALUOut, WB_ReadData, WB_PCPlus4;

    mem_wb_reg u_memwb (
        .clk(clk), .rst(rst),
        .RegWrite_in(MEM_RegWrite), .RegWriteSrc_in(MEM_RegWriteSrc),
        .ALUOut_in(MEM_ALUOut), .ReadData_in(MEM_ReadData), .PCPlus4_in(MEM_PCPlus4),
        .rd_in(MEM_rd),

        .RegWrite_out(WB_RegWrite), .RegWriteSrc_out(WB_RegWriteSrc),
        .ALUOut_out(WB_ALUOut), .ReadData_out(WB_ReadData), .PCPlus4_out(WB_PCPlus4),
        .rd_out(WB_rd)
    );
    assign MEMWB_rd       = WB_rd;
    assign MEMWB_RegWrite = WB_RegWrite;

    // =================== WB stage ===================
    reg [31:0] WB_D_In_reg;
    always @(*) begin
        case (WB_RegWriteSrc)
            2'b10:   WB_D_In_reg = WB_ReadData;
            2'b11:   WB_D_In_reg = WB_PCPlus4;
            default: WB_D_In_reg = WB_ALUOut;
        endcase
    end
    assign WB_D_In = WB_D_In_reg;

endmodule
