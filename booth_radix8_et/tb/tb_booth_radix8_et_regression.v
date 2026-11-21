`timescale 1ns/1ps
//==============================================================================
// tb_booth_radix8_et_regression.v
// Self-checking regression testbench: 32-bit signed Radix-8 Booth multiplier
// with early termination (DUT = booth_radix8_et).
//
// Per operation it checks:
//   1) product == A * B                       (64-bit signed reference)
//   2) iter_count == golden early-term model  (exp_iters)
//   3) latency (start edge -> done) == iter_count + 1 clocks
//   4) done is a single-cycle pulse, busy is low when done is seen
//   5) product is held after done
//   6) timeout protection (per-op cycle limit + global watchdog)
//
// Coverage:
//   - all four sign combinations (+ +, - -, + -, - +)
//   - zero and signed boundary values (0, +/-1, INT_MAX, INT_MIN, ...)
//   - powers of two (+/-2^k, k = 0..31) in both operand positions
//   - sparse and dense binary patterns (directed cross product)
//   - >= 1000 random pairs per class (reproducible seed), incl. small-magnitude
//     multipliers to exercise early termination
//
// Prints per-class latency statistics and an iteration-count histogram.
// Set 'tb_booth_radix8_et_regression' as the simulation top.
//==============================================================================
module tb_booth_radix8_et_regression;

    //--------------------------------------------------------------------------
    // DUT hookup
    //--------------------------------------------------------------------------
    reg                clk   = 1'b0;
    reg                rst   = 1'b1;
    reg                start = 1'b0;
    reg  signed [31:0] a     = 32'sd0;
    reg  signed [31:0] b     = 32'sd0;
    wire signed [63:0] p;
    wire               done, busy;
    wire        [3:0]  it;

    booth_radix8_et dut (
        .clk(clk), .rst(rst), .start(start),
        .multiplicand(a), .multiplier(b),
        .product(p), .done(done), .busy(busy), .iter_count(it)
    );

    always #5 clk = ~clk;                    // 100 MHz

    localparam integer TIMEOUT_CYC = 20;     // per-operation limit (max legal = 12)
    localparam integer MAX_ITERS   = 11;     // 33-bit multiplier / 3

    //--------------------------------------------------------------------------
    // Bookkeeping
    //--------------------------------------------------------------------------
    integer errors = 0;
    integer tests  = 0;
    integer timeouts = 0;
    integer cyc;

    // per-class statistics
    integer cls_tests, cls_err0, total_cyc, max_cyc, min_cyc;
    // global iteration histogram (index = iter_count)
    integer hist [0:15];
    integer hi;

    reg signed [63:0] ea, eb, expected;

    //--------------------------------------------------------------------------
    // Global watchdog (guards against a hung simulation)
    //--------------------------------------------------------------------------
    initial begin
        #200_000_000;
        $display("FATAL: global watchdog expired - simulation hung.");
        $display("FAIL");
        $finish;
    end

    //--------------------------------------------------------------------------
    // Golden model: number of Booth digits needed before all remaining
    // digits are zero (matches the DUT's early-termination rule).
    //--------------------------------------------------------------------------
    function integer exp_iters;
        input signed [31:0] m;
        reg signed [32:0] r;
        reg qq;
        reg fin;
        integer n;
        begin
            if (m == 0) begin
                exp_iters = 0;
            end else begin
                r   = {m[31], m};
                qq  = 1'b0;
                n   = 0;
                fin = 1'b0;
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

    //--------------------------------------------------------------------------
    // One multiplication with full checking
    //--------------------------------------------------------------------------
    task run_test;
        input signed [31:0] ma;
        input signed [31:0] mb;
        reg   timed_out;
        begin
            timed_out = 1'b0;
            @(negedge clk);
            a = ma; b = mb; start = 1'b1;
            @(negedge clk);                  // load edge has occurred
            start = 1'b0;
            cyc = 1;
            while (!done && !timed_out) begin
                @(negedge clk);
                cyc = cyc + 1;
                if (cyc > TIMEOUT_CYC) begin
                    $display("ERROR: timeout a=%0d b=%0d (done never asserted)", ma, mb);
                    errors   = errors + 1;
                    timeouts = timeouts + 1;
                    timed_out = 1'b1;
                end
            end

            if (timed_out) begin
                // recover a possibly stuck DUT with a reset pulse
                rst = 1'b1;
                repeat (2) @(negedge clk);
                rst = 1'b0;
            end else begin
                ea = ma;                     // sign-extend to 64 bits
                eb = mb;
                expected = ea * eb;
                tests     = tests + 1;
                cls_tests = cls_tests + 1;

                // 1) functional result
                if (p !== expected) begin
                    errors = errors + 1;
                    $display("ERROR: %0d * %0d = %0d, expected %0d", ma, mb, p, expected);
                end
                // 2) iteration count vs golden model
                if (it !== exp_iters(mb)) begin
                    errors = errors + 1;
                    $display("ERROR: iter_count=%0d expected %0d for multiplier %0d (0x%08h)",
                             it, exp_iters(mb), mb, mb);
                end
                // 3) latency = iterations + 1
                if (cyc != exp_iters(mb) + 1) begin
                    errors = errors + 1;
                    $display("ERROR: latency=%0d clk expected %0d for multiplier %0d",
                             cyc, exp_iters(mb) + 1, mb);
                end
                // iteration bound
                if (it > MAX_ITERS) begin
                    errors = errors + 1;
                    $display("ERROR: iter_count=%0d exceeds maximum %0d", it, MAX_ITERS);
                end
                // 4a) busy must be low when done is seen
                if (busy) begin
                    errors = errors + 1;
                    $display("ERROR: busy still high when done asserted (a=%0d b=%0d)", ma, mb);
                end

                hist[it] = hist[it] + 1;

                // 4b) done is a one-cycle pulse; 5) product is held
                @(negedge clk);
                if (done) begin
                    errors = errors + 1;
                    $display("ERROR: done held for more than one cycle");
                end
                if (p !== expected) begin
                    errors = errors + 1;
                    $display("ERROR: product not held after done (a=%0d b=%0d)", ma, mb);
                end

                total_cyc = total_cyc + cyc;
                if (cyc > max_cyc) max_cyc = cyc;
                if (cyc < min_cyc) min_cyc = cyc;
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Per-class statistics helpers
    //--------------------------------------------------------------------------
    task begin_class;
        begin
            cls_tests = 0;
            cls_err0  = errors;
            total_cyc = 0;
            max_cyc   = 0;
            min_cyc   = 1000;
        end
    endtask

    task end_class;
        input [8*32-1:0] name;
        begin
            if (cls_tests == 0)
                $display("%0s : no completed ops", name);
            else
                $display("%-32s : %5d ops, %3d errors, avg latency = %0d.%02d clk, min = %0d, max = %0d",
                         name, cls_tests, errors - cls_err0,
                         total_cyc / cls_tests, ((total_cyc * 100) / cls_tests) % 100,
                         min_cyc, max_cyc);
        end
    endtask

    //--------------------------------------------------------------------------
    // Directed data
    //--------------------------------------------------------------------------
    localparam integer NPAT = 24;
    reg [31:0] pat [0:NPAT-1];

    integer i, j, k;
    integer seed;
    reg signed [31:0] ra, rb, pw;

    initial begin
        // sparse and dense binary patterns
        pat[0]  = 32'h00000000;   // all zeros
        pat[1]  = 32'hFFFFFFFF;   // all ones (-1)
        pat[2]  = 32'h55555555;   // alternating 0101...
        pat[3]  = 32'hAAAAAAAA;   // alternating 1010...
        pat[4]  = 32'h33333333;
        pat[5]  = 32'hCCCCCCCC;
        pat[6]  = 32'h0F0F0F0F;
        pat[7]  = 32'hF0F0F0F0;
        pat[8]  = 32'h00FF00FF;
        pat[9]  = 32'hFF00FF00;
        pat[10] = 32'h0000FFFF;
        pat[11] = 32'hFFFF0000;
        pat[12] = 32'h7FFFFFFF;   // INT_MAX (dense, positive)
        pat[13] = 32'h80000000;   // INT_MIN (sparse, negative)
        pat[14] = 32'h80000001;
        pat[15] = 32'h7FFFFFFE;
        pat[16] = 32'h00000001;   // sparse
        pat[17] = 32'h00010001;   // sparse, two bits
        pat[18] = 32'h80008000;   // sparse, two bits (negative)
        pat[19] = 32'h01010101;   // sparse
        pat[20] = 32'hFEFEFEFE;   // dense negative
        pat[21] = 32'hFFFEFFFF;   // dense, single zero
        pat[22] = 32'h7FFF7FFF;   // dense positive
        pat[23] = 32'h12492492;   // 001 001 001 ... digit-boundary pattern
    end

    //--------------------------------------------------------------------------
    // Main test sequence
    //--------------------------------------------------------------------------
    initial begin
        for (hi = 0; hi < 16; hi = hi + 1) hist[hi] = 0;
        seed = 32'h1BADC0DE;
        begin_class;
        repeat (4) @(negedge clk);
        rst = 1'b0;
        repeat (2) @(negedge clk);

        //----------------------------------------------------------------------
        // 1) All four sign combinations
        //----------------------------------------------------------------------
        begin_class;
        run_test( 32'sd7,         32'sd6);          // + x +
        run_test(-32'sd5,        -32'sd9);          // - x -
        run_test( 32'sd4,        -32'sd8);          // + x -
        run_test(-32'sd10,        32'sd20);         // - x +
        run_test( 32'sd123456789, 32'sd987654321);  // + x + large
        run_test(-32'sd123456789,-32'sd987654321);  // - x - large
        run_test( 32'sd123456789,-32'sd987654321);  // + x - large
        run_test(-32'sd123456789, 32'sd987654321);  // - x + large
        run_test( 32'sd1,         32'sd1);
        run_test(-32'sd1,        -32'sd1);
        run_test( 32'sd1,        -32'sd1);
        run_test(-32'sd1,         32'sd1);
        end_class("sign combinations");

        //----------------------------------------------------------------------
        // 2) Zero and signed boundary cases
        //----------------------------------------------------------------------
        begin_class;
        run_test(0, 0);
        run_test(32'sd123456789, 0);
        run_test(0, 32'sd123456789);
        run_test(-32'sd123456789, 0);
        run_test(0, -32'sd123456789);
        run_test(32'sd2147483647,  32'sd2147483647);   // MAX x MAX
        run_test(-32'sd2147483648, -32'sd2147483648);  // MIN x MIN
        run_test(-32'sd2147483648,  32'sd2147483647);  // MIN x MAX
        run_test(32'sd2147483647, -32'sd2147483648);   // MAX x MIN
        run_test(-32'sd2147483648, -32'sd1);
        run_test(-32'sd1,          -32'sd2147483648);
        run_test(-32'sd2147483648,  32'sd1);
        run_test(32'sd1,           -32'sd2147483648);
        run_test(32'sd2147483647,   32'sd1);
        run_test(32'sd2147483647,  -32'sd1);
        run_test(-32'sd2147483648,  32'sd0);
        run_test(32'sd0,           -32'sd2147483648);
        run_test(32'sd2147483647,   32'sd0);
        run_test(32'sd7,  32'sd7);       // radix-8 digit boundaries
        run_test(32'sd8,  32'sd8);
        run_test(-32'sd8, 32'sd8);
        run_test(32'sd4,  32'sd4);
        run_test(-32'sd4, 32'sd4);
        run_test(32'sd3,  32'sd3);
        run_test(32'sd255,   32'sd255);
        run_test(32'sd256,  -32'sd256);
        run_test(32'sd65535, -32'sd65535);
        end_class("zero / boundary");

        //----------------------------------------------------------------------
        // 3) Powers of two, +/-2^k, k = 0..31, in both operand positions
        //----------------------------------------------------------------------
        begin_class;
        for (k = 0; k < 32; k = k + 1) begin
            pw = 32'sd1 << k;                          // k=31 -> INT_MIN
            run_test(32'sd123456789,  pw);             // multiplier = +2^k
            run_test(32'sd123456789, -pw);             // multiplier = -2^k
            run_test(-32'sd987654321, pw);
            run_test(-32'sd987654321, -pw);
            run_test(pw,  32'sd123456789);             // multiplicand = +2^k
            run_test(-pw, 32'sd123456789);
            run_test(pw,  -32'sd987654321);
            run_test(pw, 32'sd1 << (31 - k));          // 2^k x 2^(31-k)
        end
        end_class("powers of two");

        //----------------------------------------------------------------------
        // 4) Sparse / dense binary patterns: full cross product
        //----------------------------------------------------------------------
        begin_class;
        for (i = 0; i < NPAT; i = i + 1)
            for (j = 0; j < NPAT; j = j + 1)
                run_test(pat[i], pat[j]);
        end_class("sparse/dense patterns (cross)");

        //----------------------------------------------------------------------
        // 5) Random: full-range operands
        //----------------------------------------------------------------------
        begin_class;
        for (i = 0; i < 5000; i = i + 1) begin
            ra = $random(seed); rb = $random(seed);
            run_test(ra, rb);
        end
        end_class("random full 32-bit");

        //----------------------------------------------------------------------
        // 6) Random: small-magnitude signed multipliers (early termination)
        //----------------------------------------------------------------------
        begin_class;
        for (i = 0; i < 1500; i = i + 1) begin
            ra = $random(seed); rb = $random(seed);
            rb = {{16{rb[15]}}, rb[15:0]};
            run_test(ra, rb);
        end
        end_class("random 16-bit multiplier");

        begin_class;
        for (i = 0; i < 1500; i = i + 1) begin
            ra = $random(seed); rb = $random(seed);
            rb = {{24{rb[7]}}, rb[7:0]};
            run_test(ra, rb);
        end
        end_class("random 8-bit multiplier");

        begin_class;
        for (i = 0; i < 1000; i = i + 1) begin
            ra = $random(seed); rb = $random(seed);
            rb = {{28{rb[3]}}, rb[3:0]};
            run_test(ra, rb);
        end
        end_class("random 4-bit multiplier");

        begin_class;
        for (i = 0; i < 1000; i = i + 1) begin
            ra = $random(seed); rb = $random(seed);
            ra = {{20{ra[11]}}, ra[11:0]};
            rb = {{20{rb[11]}}, rb[11:0]};
            run_test(ra, rb);
        end
        end_class("random 12-bit x 12-bit");

        //----------------------------------------------------------------------
        // 7) Random: sparse (few 1s) and dense (few 0s) operands
        //----------------------------------------------------------------------
        begin_class;
        for (i = 0; i < 1000; i = i + 1) begin
            ra = $random(seed) & $random(seed) & $random(seed);   // sparse
            rb = $random(seed) & $random(seed) & $random(seed);
            run_test(ra, rb);
        end
        end_class("random sparse");

        begin_class;
        for (i = 0; i < 1000; i = i + 1) begin
            ra = ~($random(seed) & $random(seed) & $random(seed)); // dense
            rb = ~($random(seed) & $random(seed) & $random(seed));
            run_test(ra, rb);
        end
        end_class("random dense");

        //----------------------------------------------------------------------
        // Summary
        //----------------------------------------------------------------------
        $display("--------------------------------------------------");
        $display("Iteration-count histogram (all tests):");
        for (hi = 0; hi <= MAX_ITERS; hi = hi + 1)
            $display("  %2d iterations (latency %2d clk) : %0d ops", hi, hi + 1, hist[hi]);
        $display("Baseline fixed Radix-8 iterative = %0d digit steps for every operand.", MAX_ITERS);
        $display("--------------------------------------------------");
        $display("Total ops: %0d, errors: %0d, timeouts: %0d", tests, errors, timeouts);
        if (errors == 0)
            $display("PASS: all %0d tests passed.", tests);
        else
            $display("FAIL: %0d errors in %0d tests.", errors, tests);
        $finish;
    end

endmodule
