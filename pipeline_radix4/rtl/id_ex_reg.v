`timescale 1ns / 1ps
module id_ex_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        flush,     // insert bubble (load-use stall or branch flush)

    // control signals in
    input  wire        RegWrite_in, MemRead_in, MemWrite_in, Branch_in,
    input  wire        ALUSelA_in, ALUSelB_in, IsJAL_in,
    input  wire [3:0]  ALUOp_in,
    input  wire [1:0]  RegWriteSrc_in,

    // data signals in
    input  wire [31:0] PC_in, Data1_in, Data2_in, Imm_in, PCPlus4_in,
    input  wire [4:0]  rd_in, rs1_in, rs2_in,

    // control signals out
    output reg          RegWrite_out, MemRead_out, MemWrite_out, Branch_out,
    output reg          ALUSelA_out, ALUSelB_out, IsJAL_out,
    output reg  [3:0]   ALUOp_out,
    output reg  [1:0]   RegWriteSrc_out,

    // data signals out
    output reg  [31:0] PC_out, Data1_out, Data2_out, Imm_out, PCPlus4_out,
    output reg  [4:0]  rd_out, rs1_out, rs2_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            RegWrite_out    <= 1'b0;
            MemRead_out     <= 1'b0;
            MemWrite_out    <= 1'b0;
            Branch_out      <= 1'b0;
            ALUSelA_out     <= 1'b0;
            ALUSelB_out     <= 1'b0;
            IsJAL_out       <= 1'b0;
            ALUOp_out       <= 4'b0;
            RegWriteSrc_out <= 2'b0;
            PC_out          <= 32'b0;
            Data1_out       <= 32'b0;
            Data2_out       <= 32'b0;
            Imm_out         <= 32'b0;
            PCPlus4_out     <= 32'b0;
            rd_out          <= 5'b0;
            rs1_out         <= 5'b0;
            rs2_out         <= 5'b0;
        end else begin
            RegWrite_out    <= RegWrite_in;
            MemRead_out     <= MemRead_in;
            MemWrite_out    <= MemWrite_in;
            Branch_out      <= Branch_in;
            ALUSelA_out     <= ALUSelA_in;
            ALUSelB_out     <= ALUSelB_in;
            IsJAL_out       <= IsJAL_in;
            ALUOp_out       <= ALUOp_in;
            RegWriteSrc_out <= RegWriteSrc_in;
            PC_out          <= PC_in;
            Data1_out       <= Data1_in;
            Data2_out       <= Data2_in;
            Imm_out         <= Imm_in;
            PCPlus4_out     <= PCPlus4_in;
            rd_out          <= rd_in;
            rs1_out         <= rs1_in;
            rs2_out         <= rs2_in;
        end
    end
endmodule
