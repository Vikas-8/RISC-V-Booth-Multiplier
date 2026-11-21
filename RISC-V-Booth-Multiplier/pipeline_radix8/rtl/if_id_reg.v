`timescale 1ns / 1ps
module if_id_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,   // hold current value (load-use hazard)
    input  wire        flush,   // insert bubble (branch taken)
    input  wire [31:0] instr_in,
    input  wire [31:0] pc_in,
    output reg  [31:0] instr_out,
    output reg  [31:0] pc_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            instr_out <= 32'b0;
            pc_out    <= 32'b0;
        end else if (flush) begin
            instr_out <= 32'b0;   // NOP
            pc_out    <= 32'b0;
        end else if (!stall) begin
            instr_out <= instr_in;
            pc_out    <= pc_in;
        end
        // else: hold current value (stall)
    end
endmodule
