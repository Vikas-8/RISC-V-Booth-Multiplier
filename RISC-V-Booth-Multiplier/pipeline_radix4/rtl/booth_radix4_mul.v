`timescale 1ns / 1ps
// Radix-4 Booth multiplier (signed N x N -> 2N), combinational, for the EX stage.
// N/2 partial products from {0, +M, +2M, -2M, -M}, summed with a BALANCED adder
// tree (log2(N/2) = 4 adder levels for N=32) instead of a 15-deep adder chain,
// to shorten the critical path. Requires N/2 to be a power of two (N=32 OK).
module booth_radix4_mul #(parameter N = 32) (
    input  wire signed [N-1:0]   multiplicand,
    input  wire signed [N-1:0]   multiplier,
    output wire signed [2*N-1:0] product
);
    localparam NPP = N/2;

    wire signed [2*N-1:0] m_ext = {{N{multiplicand[N-1]}}, multiplicand};
    wire [N:0] mq = {multiplier, 1'b0};          // append q[-1] = 0

    // partial product generation (one per 3-bit group), pre-shifted by 2*i
    wire signed [2*N-1:0] pp [0:NPP-1];
    genvar g;
    generate
        for (g = 0; g < NPP; g = g + 1) begin : gen_pp
            wire [2:0] grp = mq[2*g +: 3];
            reg signed [2*N-1:0] sel;
            always @(*) begin
                case (grp)
                    3'b000, 3'b111: sel = {2*N{1'b0}};
                    3'b001, 3'b010: sel =  m_ext;
                    3'b011:         sel =  m_ext <<< 1;
                    3'b100:         sel = -(m_ext <<< 1);
                    default:        sel = -m_ext;
                endcase
            end
            assign pp[g] = sel <<< (2*g);
        end
    endgenerate

    // balanced pairwise reduction tree
    reg signed [2*N-1:0] t [0:NPP-1];
    integer s, j;
    always @(*) begin
        for (j = 0; j < NPP; j = j + 1) t[j] = pp[j];
        for (s = NPP/2; s >= 1; s = s/2)
            for (j = 0; j < s; j = j + 1)
                t[j] = t[2*j] + t[2*j+1];
    end

    assign product = t[0];
endmodule
