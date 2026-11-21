`timescale 1ns / 1ps

module mux2to1 #(parameter WIDTH = 32) (
    input  wire                  sel,
    input  wire [WIDTH-1:0]      in0,
    input  wire [WIDTH-1:0]      in1,
    output wire [WIDTH-1:0]      out
);
    assign out = sel ? in1 : in0;
endmodule

module mux4to1 #(parameter WIDTH = 32) (
    input  wire [1:0]            sel,
    input  wire [WIDTH-1:0]      in00,
    input  wire [WIDTH-1:0]      in01,
    input  wire [WIDTH-1:0]      in10,
    input  wire [WIDTH-1:0]      in11,
    output reg  [WIDTH-1:0]      out
);
    always @(*) begin
        case (sel)
            2'b00: out = in00;
            2'b01: out = in01;
            2'b10: out = in10;
            default: out = in11;
        endcase
    end
endmodule
