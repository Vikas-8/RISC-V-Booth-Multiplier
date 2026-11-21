`timescale 1ns / 1ps
// Program Counter - matches "Program Counter" block in Fig. 2
module program_counter (
    input  wire        clk,
    input  wire        rst,
    input  wire        PCLd,      // load enable
    input  wire [31:0] PCIn,      // selected next PC (output of PCSel mux)
    output reg  [31:0] PCOut
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            PCOut <= 32'b0;
        else if (PCLd)
            PCOut <= PCIn;
    end
endmodule
