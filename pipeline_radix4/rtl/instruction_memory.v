`timescale 1ns / 1ps
module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
    end
    assign instr = mem[addr[9:2]];
endmodule
