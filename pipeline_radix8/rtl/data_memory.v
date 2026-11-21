`timescale 1ns / 1ps
module data_memory (
    input  wire        clk,
    input  wire        MemWrite,
    input  wire        MemRead,
    input  wire [31:0] Address,
    input  wire [31:0] Write_Data,
    output wire [31:0] Read_Data
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
    end

    always @(posedge clk) begin
        if (MemWrite)
            mem[Address[9:2]] <= Write_Data;
    end

    assign Read_Data = MemRead ? mem[Address[9:2]] : 32'b0;
endmodule
