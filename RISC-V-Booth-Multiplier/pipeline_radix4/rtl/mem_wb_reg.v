`timescale 1ns / 1ps
module mem_wb_reg (
    input  wire        clk,
    input  wire        rst,

    input  wire        RegWrite_in,
    input  wire [1:0]  RegWriteSrc_in,
    input  wire [31:0] ALUOut_in, ReadData_in, PCPlus4_in,
    input  wire [4:0]  rd_in,

    output reg          RegWrite_out,
    output reg  [1:0]   RegWriteSrc_out,
    output reg  [31:0]  ALUOut_out, ReadData_out, PCPlus4_out,
    output reg  [4:0]   rd_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            RegWrite_out    <= 1'b0;
            RegWriteSrc_out <= 2'b0;
            ALUOut_out      <= 32'b0;
            ReadData_out    <= 32'b0;
            PCPlus4_out     <= 32'b0;
            rd_out          <= 5'b0;
        end else begin
            RegWrite_out    <= RegWrite_in;
            RegWriteSrc_out <= RegWriteSrc_in;
            ALUOut_out      <= ALUOut_in;
            ReadData_out    <= ReadData_in;
            PCPlus4_out     <= PCPlus4_in;
            rd_out          <= rd_in;
        end
    end
endmodule
