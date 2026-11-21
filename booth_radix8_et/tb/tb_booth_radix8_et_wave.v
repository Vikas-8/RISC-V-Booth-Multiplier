`timescale 1ns/1ps
//=============================================================================
// tb_booth_radix8_et_wave.v - short waveform demo, Radix-8 Booth Early-Term.
// DUT = booth_radix8_et (iterative, start/done handshake, variable latency).
// Signals worth adding to the waveform:
//   clk, rst, start, A, B, MUL_Result, busy, done, iter_count
// Cases: pos x pos, neg x neg, pos x neg, neg x pos, zero, plus one
// full-width multiplier to contrast the latency (early termination).
// Tip: right-click A / B / MUL_Result > Radix > Signed Decimal.
// Full corner/random regression is in tb_booth_radix8_et.v.
//=============================================================================
module tb_booth_radix8_et_wave;

    reg                clk = 1'b0;
    reg                rst = 1'b1;
    reg                start = 1'b0;
    reg  signed [31:0] A = 32'sd0;
    reg  signed [31:0] B = 32'sd0;
    wire signed [63:0] MUL_Result;
    wire               done, busy;
    wire        [3:0]  iter_count;

    booth_radix8_et dut (
        .clk(clk), .rst(rst), .start(start),
        .multiplicand(A), .multiplier(B),
        .product(MUL_Result), .done(done), .busy(busy),
        .iter_count(iter_count)
    );

    always #5 clk = ~clk;   // 100 MHz

    integer fails = 0;
    integer cyc;

    // golden model: Booth digits needed before the remaining digits are all 0
    function integer exp_iters;
        input signed [31:0] m;
        reg signed [32:0] r;
        reg qq;
        reg fin;
        integer n;
        begin
            if (m == 0) exp_iters = 0;
            else begin
                r = {m[31], m};
                qq = 1'b0; n = 0; fin = 1'b0;
                while (!fin) begin
                    qq = r[2];
                    r  = r >>> 3;
                    n  = n + 1;
                    if ((r == 33'sd0 && !qq) || (r == -33'sd1 && qq)) fin = 1'b1;
                end
                exp_iters = n;
            end
        end
    endfunction

    task apply;
        input signed [31:0] x;
        input signed [31:0] y;
        input [8*24-1:0]    name;
        reg   signed [63:0] expected;
        reg                 timed_out;
        begin
            timed_out = 1'b0;
            expected  = x * y;

            @(negedge clk);
            A = x; B = y; start = 1'b1;     // operands held stable for the whole op
            @(negedge clk);
            start = 1'b0;
            cyc = 1;
            while (!done && !timed_out) begin
                @(negedge clk);
                cyc = cyc + 1;
                if (cyc > 20) timed_out = 1'b1;
            end

            if (timed_out) begin
                fails = fails + 1;
                $display("[FAIL] %0s : timeout", name);
            end else begin
                if (MUL_Result === expected && iter_count === exp_iters(y))
                    $display("[PASS] %0s : %0d x %0d = %0d  (iters=%0d, latency=%0d clk)",
                             name, x, y, MUL_Result, iter_count, cyc);
                else begin
                    fails = fails + 1;
                    $display("[FAIL] %0s : %0d x %0d = %0d (expected %0d), iters=%0d (expected %0d)",
                             name, x, y, MUL_Result, expected, iter_count, exp_iters(y));
                end
            end
            repeat (2) @(negedge clk);       // idle gap so each case is visible
        end
    endtask

    initial begin
        repeat (4) @(negedge clk);
        rst = 1'b0;

        apply(        7,         6, "pos x pos");
        apply(       -5,        -9, "neg x neg");
        apply(        4,        -8, "pos x neg");
        apply(      -10,        20, "neg x pos");
        apply(        0,        20, "zero");
        apply(123456789, 987654321, "large multiplier (full)");

        if (fails == 0) $display("*** ALL 6 CASES PASSED ***");
        else            $display("*** %0d CASE(S) FAILED ***", fails);
        $finish;
    end

endmodule