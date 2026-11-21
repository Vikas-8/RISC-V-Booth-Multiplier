`timescale 1ns / 1ps
module ex_mem_reg (
    input  wire        clk,
    input  wire        rst,

    input  wire        RegWrite_in, MemRead_in, MemWrite_in,
    input  wire [1:0]  RegWriteSrc_in,
    input  wire [31:0] ALUOut_in, WriteData_in, PCPlus4_in,
    input  wire [4:0]  rd_in,

    output reg          RegWrite_out, MemRead_out, MemWrite_out,
    output reg  [1:0]   RegWriteSrc_out,
    output reg  [31:0]  ALUOut_out, WriteData_out, PCPlus4_out,
    output reg  [4:0]   rd_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            RegWrite_out    <= 1'b0;
            MemRead_out     <= 1'b0;
            MemWrite_out    <= 1'b0;
            RegWriteSrc_out <= 2'b0;
            ALUOut_out      <= 32'b0;
            WriteData_out   <= 32'b0;
            PCPlus4_out     <= 32'b0;
            rd_out          <= 5'b0;
        end else begin
            RegWrite_out    <= RegWrite_in;
            MemRead_out     <= MemRead_in;
            MemWrite_out    <= MemWrite_in;
            RegWriteSrc_out <= RegWriteSrc_in;
            ALUOut_out      <= ALUOut_in;
            WriteData_out   <= WriteData_in;
            PCPlus4_out     <= PCPlus4_in;
            rd_out          <= rd_in;
        end
    end
endmodule
