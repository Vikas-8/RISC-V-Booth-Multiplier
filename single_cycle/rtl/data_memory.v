`timescale 1ns / 1ps
// Data Memory - matches "Data Memory" block in Fig. 2
module data_memory (
    input  wire        clk,
    input  wire        DMWrite,
    input  wire        DMRead,
    input  wire [31:0] Address,     // = ALUOut
    input  wire [31:0] Write_Data,  // = Data2 (rs2 value)
    output wire [31:0] Read_Data
);
    reg [31:0] mem [0:255]; // 256 words = 1KB data space

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
    end

    always @(posedge clk) begin
        if (DMWrite)
            mem[Address[9:2]] <= Write_Data;
    end

    assign Read_Data = DMRead ? mem[Address[9:2]] : 32'b0;
endmodule
