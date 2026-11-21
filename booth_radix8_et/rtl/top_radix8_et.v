`timescale 1ns/1ps
//==============================================================================
// Top wrapper for out-of-context synthesis / implementation.
// Registers all inputs and outputs so reported timing reflects the core only.
//==============================================================================
module top_radix8_et (
    input  wire               clk,
    input  wire               rst,
    input  wire               start,
    input  wire signed [31:0] multiplicand,
    input  wire signed [31:0] multiplier,
    output reg  signed [63:0] product,
    output reg                done,
    output reg                busy,
    output reg         [3:0]  iter_count
);

    reg               start_r;
    reg signed [31:0] a_r, b_r;

    wire signed [63:0] p_w;
    wire               done_w, busy_w;
    wire        [3:0]  it_w;

    always @(posedge clk) begin
        start_r <= start;
        a_r     <= multiplicand;
        b_r     <= multiplier;
    end

    booth_radix8_et u_core (
        .clk         (clk),
        .rst         (rst),
        .start       (start_r),
        .multiplicand(a_r),
        .multiplier  (b_r),
        .product     (p_w),
        .done        (done_w),
        .busy        (busy_w),
        .iter_count  (it_w)
    );

    always @(posedge clk) begin
        product    <= p_w;
        done       <= done_w;
        busy       <= busy_w;
        iter_count <= it_w;
    end

endmodule
