`timescale 1ns / 1ps
// Since branches resolve in ID (reading Data1/Data2 straight from the
// register file), an immediately-preceding ALU instruction (still in
// EX/MEM, not yet written back) would otherwise cause a stale read.
// This forwards EX/MEM or MEM/WB results into the branch comparator's
// inputs. (Load-use hazards into a branch are still caught by the
// standard hazard_unit stall, since ID's rs1/rs2 are checked regardless
// of instruction type.)
module branch_forward_unit (
    input  wire [4:0]  rs1_ID, rs2_ID,
    input  wire [4:0]  rd_EXMEM,
    input  wire         RegWrite_EXMEM,
    input  wire [31:0]  ALUOut_EXMEM,
    input  wire [4:0]  rd_MEMWB,
    input  wire         RegWrite_MEMWB,
    input  wire [31:0]  WBData_MEMWB,
    input  wire [31:0]  RegFileData1, RegFileData2,
    output reg  [31:0]  Data1,
    output reg  [31:0]  Data2
);
    always @(*) begin
        if (RegWrite_EXMEM && (rd_EXMEM != 5'b0) && (rd_EXMEM == rs1_ID))
            Data1 = ALUOut_EXMEM;
        else if (RegWrite_MEMWB && (rd_MEMWB != 5'b0) && (rd_MEMWB == rs1_ID))
            Data1 = WBData_MEMWB;
        else
            Data1 = RegFileData1;

        if (RegWrite_EXMEM && (rd_EXMEM != 5'b0) && (rd_EXMEM == rs2_ID))
            Data2 = ALUOut_EXMEM;
        else if (RegWrite_MEMWB && (rd_MEMWB != 5'b0) && (rd_MEMWB == rs2_ID))
            Data2 = WBData_MEMWB;
        else
            Data2 = RegFileData2;
    end
endmodule
