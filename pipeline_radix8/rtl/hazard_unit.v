`timescale 1ns / 1ps
// Detects the load-use hazard: if the instruction in EX is a load (MemRead)
// and its destination register matches either source register of the
// instruction currently in ID, we must stall one cycle (the load's result
// isn't ready until after MEM, one cycle too late for EX-stage forwarding).
module hazard_unit (
    input  wire        MemRead_EX,
    input  wire [4:0]  rd_EX,
    input  wire [4:0]  rs1_ID,
    input  wire [4:0]  rs2_ID,
    output wire         stall
);
    assign stall = MemRead_EX && (rd_EX != 5'b0) &&
                   ((rd_EX == rs1_ID) || (rd_EX == rs2_ID));
endmodule
