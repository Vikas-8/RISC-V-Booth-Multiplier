`timescale 1ns / 1ps
// Radix-8 Booth multiplier (signed N x N -> 2N), combinational, for the EX stage.
// Drop-in replacement for booth_radix4_mul (same ports).
//
// Radix-8 recodes the multiplier in overlapping 4-bit groups (3 new bits + 1 overlap bit):
//     digit = -4*b3 + 2*b2 + b1 + b0   in {-4,-3,-2,-1,0,+1,+2,+3,+4}
// so it needs only NPP = ceil((N+1)/3) = 11 partial products for N = 32
// (radix-4 needs 16). The price is the "hard multiple" 3M = M + 2M, which is
// computed once by a single adder before the partial-product selection.
//
// The 11 partial products are zero-padded to 16 and summed with a BALANCED
// adder tree (4 levels), same style as the radix-4 version.
module booth_radix8_mul #(parameter N = 32) (
    input  wire signed [N-1:0]   multiplicand,
    input  wire signed [N-1:0]   multiplier,
    output wire signed [2*N-1:0] product
);
    localparam NPP = (N + 3) / 3;                 // 11 for N = 32
    // smallest power of two >= NPP (16 for N = 32) for the balanced tree
    function integer pow2_ceil(input integer n);
        integer p;
        begin
            p = 1;
            while (p < n) p = p * 2;
            pow2_ceil = p;
        end
    endfunction
    localparam NT = pow2_ceil(NPP);

    wire signed [2*N-1:0] m1 = {{N{multiplicand[N-1]}}, multiplicand};  // +M
    wire signed [2*N-1:0] m2 = m1 <<< 1;                                // +2M
    wire signed [2*N-1:0] m3 = m1 + m2;                                 // +3M (hard multiple)
    wire signed [2*N-1:0] m4 = m1 <<< 2;                                // +4M

    // sign-extend multiplier so 3*NPP bits are available, append q[-1] = 0
    wire [3*NPP:0] mq = {{(3*NPP - N){multiplier[N-1]}}, multiplier, 1'b0};

    wire signed [2*N-1:0] pp [0:NPP-1];
    genvar g;
    generate
        for (g = 0; g < NPP; g = g + 1) begin : gen_pp
            wire [3:0] grp = mq[3*g +: 4];
            reg signed [2*N-1:0] sel;
            always @(*) begin
                case (grp)
                    4'b0000, 4'b1111: sel = {2*N{1'b0}};
                    4'b0001, 4'b0010: sel =  m1;
                    4'b0011, 4'b0100: sel =  m2;
                    4'b0101, 4'b0110: sel =  m3;
                    4'b0111:          sel =  m4;
                    4'b1000:          sel = -m4;
                    4'b1001, 4'b1010: sel = -m3;
                    4'b1011, 4'b1100: sel = -m2;
                    default:          sel = -m1;   // 4'b1101, 4'b1110
                endcase
            end
            assign pp[g] = sel <<< (3*g);
        end
    endgenerate

    // balanced pairwise reduction tree (unused leaves are zero)
    reg signed [2*N-1:0] t [0:NT-1];
    integer s, j;
    always @(*) begin
        for (j = 0; j < NT; j = j + 1) t[j] = (j < NPP) ? pp[j] : {2*N{1'b0}};
        for (s = NT/2; s >= 1; s = s/2)
            for (j = 0; j < s; j = j + 1)
                t[j] = t[2*j] + t[2*j+1];
    end

    assign product = t[0];
endmodule
