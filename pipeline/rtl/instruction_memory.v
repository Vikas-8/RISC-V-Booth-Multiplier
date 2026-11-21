`timescale 1ns / 1ps
// PRELOAD = 0 : all zeros (testbenches load the program by hierarchical access)
// PRELOAD = 1 : built-in demo program used for FPGA synthesis/implementation.
//               It loops forever, so every unit (ALU incl. MUL, regfile, data
//               memory, branch) stays alive in the synthesized design.
module instruction_memory #(parameter PRELOAD = 0) (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
        if (PRELOAD) begin
            mem[0] = 32'h002081b3; // ADD x3,x1,x2
            mem[1] = 32'h40118233; // SUB x4,x3,x1
            mem[2] = 32'h021203b3; // MUL x7,x4,x1
            mem[3] = 32'h00c3f533; // AND x10,x7,x12
            mem[4] = 32'h00a02023; // SW  x10,0(x0)
            mem[5] = 32'h00002683; // LW  x13,0(x0)
            mem[6] = 32'h00368733; // ADD x14,x13,x3
            mem[7] = 32'hfe0002e3; // BEQ x0,x0,-28  (loop back to address 0)
        end
    end
    assign instr = mem[addr[9:2]];
endmodule
