`timescale 1ns / 1ps
// Register File - matches "Register Files" block in Fig. 2
// rd  = Inst[11:7]   (Register Destination)
// rs1 = Inst[19:15]  (Register 1)
// rs2 = Inst[24:20]  (Register 2)
module register_file #(parameter PRELOAD = 0) (
    input  wire        clk,
    input  wire        RFWEn,
    input  wire [4:0]  rd,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [31:0] D_In,     // write-back data
    output wire [31:0] Data1,
    output wire [31:0] Data2
);
    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
        if (PRELOAD) begin           // operands of the demo program
            regs[1]  = 32'd10;
            regs[2]  = 32'd20;
            regs[12] = 32'd255;
        end
    end

    always @(posedge clk) begin
        if (RFWEn && rd != 5'b0)   // x0 hardwired to 0
            regs[rd] <= D_In;
    end

    assign Data1 = regs[rs1];
    assign Data2 = regs[rs2];
endmodule
