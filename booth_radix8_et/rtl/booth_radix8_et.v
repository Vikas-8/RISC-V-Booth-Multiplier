`timescale 1ns/1ps
//==============================================================================
// 32-bit signed Radix-8 Booth multiplier with EARLY TERMINATION
//------------------------------------------------------------------------------
// - Iterative shift-and-add: one radix-8 Booth digit (3 multiplier bits) per clock.
// - Digit set {-4,-3,-2,-1,0,+1,+2,+3,+4}; 3*multiplicand is pre-computed at load.
// - Early termination: after every step the remaining (not yet processed)
//   multiplier bits are checked. If they are all sign-extension bits
//   (all 0 with previous bit 0, or all 1 with previous bit 1) every remaining
//   Booth digit is 0, so the loop stops and the product is released.
//   Worst case = 11 iterations (33-bit sign-extended multiplier / 3).
//   Small-magnitude multipliers finish in 1..4 iterations.
//
// Handshake:
//   - Pulse 'start' for one cycle while busy == 0. Operands are latched.
//   - 'done' pulses for one cycle when 'product' is valid; product is held
//     until the next start.
//   - Latency (start edge to done visible) = iter_count + 1 clocks
//     (multiplier == 0 finishes in 1 clock with iter_count = 0).
//==============================================================================
module booth_radix8_et (
    input  wire               clk,
    input  wire               rst,          // synchronous, active high
    input  wire               start,
    input  wire signed [31:0] multiplicand,
    input  wire signed [31:0] multiplier,
    output reg  signed [63:0] product,
    output reg                done,
    output wire               busy,
    output reg         [3:0]  iter_count     // Booth digits actually processed
);

    reg               running;
    reg signed [63:0] m1;      // multiplicand      << (3*k)
    reg signed [63:0] m3;      // 3*multiplicand    << (3*k)
    reg signed [63:0] acc;     // partial product
    reg signed [32:0] mr;      // remaining multiplier (33-bit, sign extended)
    reg               q;       // previous (already consumed) multiplier bit

    assign busy = running;

    //--------------------------------------------------------------------------
    // Radix-8 Booth digit decode: group = {b[3k+2], b[3k+1], b[3k], b[3k-1]}
    // digit = -4*b2 + 2*b1 + b0 + b(-1)
    //--------------------------------------------------------------------------
    wire [3:0] grp = {mr[2:0], q};

    reg [2:0] sel;   // magnitude select: 0,1,2,3,4
    reg       neg;   // negative digit
    always @(*) begin
        case (grp)
            4'b0000, 4'b1111: begin sel = 3'd0; neg = 1'b0; end
            4'b0001, 4'b0010: begin sel = 3'd1; neg = 1'b0; end
            4'b0011, 4'b0100: begin sel = 3'd2; neg = 1'b0; end
            4'b0101, 4'b0110: begin sel = 3'd3; neg = 1'b0; end
            4'b0111:          begin sel = 3'd4; neg = 1'b0; end
            4'b1000:          begin sel = 3'd4; neg = 1'b1; end
            4'b1001, 4'b1010: begin sel = 3'd3; neg = 1'b1; end
            4'b1011, 4'b1100: begin sel = 3'd2; neg = 1'b1; end
            default:          begin sel = 3'd1; neg = 1'b1; end // 1101, 1110
        endcase
    end

    reg [63:0] mag;
    always @(*) begin
        case (sel)
            3'd0:    mag = 64'd0;
            3'd1:    mag = m1;
            3'd2:    mag = {m1[62:0], 1'b0};
            3'd3:    mag = m3;
            default: mag = {m1[61:0], 2'b00};
        endcase
    end

    // two's complement negate = invert + carry-in
    wire [63:0] addend   = mag ^ {64{neg}};
    wire [63:0] acc_next = acc + addend + {63'd0, neg};

    //--------------------------------------------------------------------------
    // Early-termination detect on the multiplier remaining AFTER this step:
    //   upper bits mr[32:3] all 0 and mr[2] (new previous bit) = 0, or
    //   upper bits all 1 and mr[2] = 1  -> all following digits are zero.
    //--------------------------------------------------------------------------
    wire rem_zero = ~|mr[32:3];
    wire rem_ones =  &mr[32:3];
    wire term_next = (rem_zero & ~mr[2]) | (rem_ones & mr[2]);

    wire signed [63:0] a_ext = {{32{multiplicand[31]}}, multiplicand};

    always @(posedge clk) begin
        if (rst) begin
            running    <= 1'b0;
            done       <= 1'b0;
            product    <= 64'sd0;
            acc        <= 64'sd0;
            m1         <= 64'sd0;
            m3         <= 64'sd0;
            mr         <= 33'sd0;
            q          <= 1'b0;
            iter_count <= 4'd0;
        end else begin
            done <= 1'b0;

            if (!running) begin
                if (start) begin
                    m1         <= a_ext;
                    m3         <= a_ext + {a_ext[62:0], 1'b0};   // 3*A
                    acc        <= 64'sd0;
                    mr         <= {multiplier[31], multiplier};
                    q          <= 1'b0;
                    iter_count <= 4'd0;
                    if (multiplier == 32'sd0) begin
                        // zero multiplier: nothing to do (immediate termination)
                        product <= 64'sd0;
                        done    <= 1'b1;
                    end else begin
                        running <= 1'b1;
                    end
                end
            end else begin
                // one Booth digit per clock
                acc        <= acc_next;
                m1         <= {m1[60:0], 3'b000};
                m3         <= {m3[60:0], 3'b000};
                mr         <= mr >>> 3;
                q          <= mr[2];
                iter_count <= iter_count + 4'd1;

                if (term_next) begin
                    product <= acc_next;
                    done    <= 1'b1;
                    running <= 1'b0;
                end
            end
        end
    end

endmodule
