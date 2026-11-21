//=============================================================================
// booth_radix8_comb.v - Radix-8 Booth multiplier with carry-save reduction
// Signed 32-bit x 32-bit -> signed 64-bit product.
// Interface intentionally matches the original booth_radix8_comb module.
//=============================================================================
`timescale 1ns/1ps

module booth_radix8_comb (
    input  signed [31:0] a,
    input  signed [31:0] b,
    output signed [63:0] p
);
    localparam NGRP = 11;

    wire signed [63:0] a64 = {{32{a[31]}}, a};
    wire signed [63:0] a3  = a64 + (a64 <<< 1);

    // b[-1] = 0; sign extension supplies the final Radix-8 groups.
    wire [35:0] bx = {{3{b[31]}}, b, 1'b0};

    function signed [63:0] pp_sel;
        input [3:0] win;
        input signed [63:0] x1;
        input signed [63:0] x3;
        begin
            case (win)
                4'b0000, 4'b1111: pp_sel = 64'sd0;
                4'b0001, 4'b0010: pp_sel = x1;
                4'b0011, 4'b0100: pp_sel = (x1 <<< 1);
                4'b0101, 4'b0110: pp_sel = x3;
                4'b0111:          pp_sel = (x1 <<< 2);
                4'b1000:          pp_sel = -(x1 <<< 2);
                4'b1001, 4'b1010: pp_sel = -x3;
                4'b1011, 4'b1100: pp_sel = -(x1 <<< 1);
                4'b1101, 4'b1110: pp_sel = -x1;
                default:          pp_sel = 64'sd0;
            endcase
        end
    endfunction

    wire signed [63:0] pp [0:10];
    genvar i;
    generate
        for (i = 0; i < NGRP; i = i + 1) begin : g_pp
            assign pp[i] = pp_sel(bx[3*i +: 4], a64, a3) <<< (3*i);
        end
    endgenerate

    // CSA stage 1: 11 operands -> 8 operands
    wire [63:0] s1_0, c1_0, s1_1, c1_1, s1_2, c1_2;
    csa3_64 u_csa1_0(pp[0], pp[1], pp[2], s1_0, c1_0);
    csa3_64 u_csa1_1(pp[3], pp[4], pp[5], s1_1, c1_1);
    csa3_64 u_csa1_2(pp[6], pp[7], pp[8], s1_2, c1_2);

    // CSA stage 2: 8 operands -> 6 operands
    wire [63:0] s2_0, c2_0, s2_1, c2_1;
    csa3_64 u_csa2_0(s1_0, c1_0, s1_1, s2_0, c2_0);
    csa3_64 u_csa2_1(c1_1, s1_2, c1_2, s2_1, c2_1);

    // CSA stage 3: 6 operands -> 4 operands
    wire [63:0] s3_0, c3_0, s3_1, c3_1;
    csa3_64 u_csa3_0(s2_0, c2_0, s2_1, s3_0, c3_0);
    csa3_64 u_csa3_1(c2_1, pp[9], pp[10], s3_1, c3_1);

    // CSA stage 4: 4 operands -> 3 operands
    wire [63:0] s4_0, c4_0;
    csa3_64 u_csa4_0(s3_0, c3_0, s3_1, s4_0, c4_0);

    // CSA stage 5: 3 operands -> 2 operands
    wire [63:0] s5_0, c5_0;
    csa3_64 u_csa5_0(s4_0, c4_0, c3_1, s5_0, c5_0);

    // Only this final adder propagates carry across the full word.
    assign p = $signed(s5_0) + $signed(c5_0);
endmodule

// 3:2 carry-save compressor. Carry output is already shifted into its
// correct bit positions; sum + carry equals a + b + c modulo 2^64.
module csa3_64 (
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire [63:0] c,
    output wire [63:0] sum,
    output wire [63:0] carry
);
    assign sum   = a ^ b ^ c;
    assign carry = ((a & b) | (a & c) | (b & c)) << 1;
endmodule
