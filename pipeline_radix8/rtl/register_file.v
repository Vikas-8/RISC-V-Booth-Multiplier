`timescale 1ns / 1ps
// Register File for the pipelined core. Includes a write-first bypass:
// if the WB stage is writing to the same register being read this cycle,
// the new value is forwarded immediately rather than waiting a cycle -
// this covers the RAW hazard distance-3 case (WB and ID happen same cycle).
module register_file (
    input  wire        clk,
    input  wire        RFWEn,
    input  wire [4:0]  rd,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [31:0] D_In,
    output wire [31:0] Data1,
    output wire [31:0] Data2
);
    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end

    always @(posedge clk) begin
        if (RFWEn && rd != 5'b0)
            regs[rd] <= D_In;
    end

    // write-first bypass
    assign Data1 = (RFWEn && rd != 5'b0 && rd == rs1) ? D_In : regs[rs1];
    assign Data2 = (RFWEn && rd != 5'b0 && rd == rs2) ? D_In : regs[rs2];
endmodule
