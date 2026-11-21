//=============================================================================
// tb_booth_radix8.v - self-checking testbench for the RADIX-8 Booth multiplier
//  Phase 1 : back-to-back stimulus (1 op/clock): directed + corner + random
//  Phase 2 : random stimulus with random bubbles (in_valid gaps)
//  Checks  : product vs. behavioural reference $signed(a)*$signed(b), out_valid
//            timing, measured latency, back-to-back throughput.
//  Drive and check both happen on the FALLING clock edge (no races).
//  LATENCY CONVENTION: operands are driven on the falling edge before capture edge E_k and
//  the result is observed on the falling edge after E_k+1. The counter therefore shows 2
//  (= inclusive count of the two capture edges E_k and E_k+1). The elapsed
//  register-to-register latency E_k -> E_k+1 is ONE clock period.
//  Identical stimulus/seed in the Radix-4 and Radix-8 projects.
//=============================================================================
`timescale 1ns/1ps
module tb_booth_radix8;
    localparam integer N_DIR  = 40;
    localparam integer N_RND  = 2000;
    localparam integer N_P2   = 1000;
    localparam integer N_MAX  = N_DIR + N_RND + N_P2 + 8;
    localparam integer CLK_NS = 10;

    reg                clk = 0, rst = 1, in_valid = 0;
    reg  signed [31:0] a = 0, b = 0;
    wire               vld;
    wire signed [63:0] prod;

    booth_pipe_wrapper dut (.clk(clk), .rst(rst), .in_valid(in_valid),
                            .a(a), .b(b), .out_valid(vld), .p(prod));

    always #(CLK_NS/2) clk = ~clk;

    reg signed [31:0] A_t [0:N_MAX-1];
    reg signed [31:0] B_t [0:N_MAX-1];
    reg signed [63:0] E_t [0:N_MAX-1];
    integer           T_in [0:N_MAX-1];
    integer n_ops, n_p1;

    integer cyc = 0;
    always @(negedge clk) cyc <= cyc + 1;

    task add_op(input signed [31:0] x, input signed [31:0] y);
        begin
            A_t[n_ops] = x;  B_t[n_ops] = y;
            E_t[n_ops] = $signed(x) * $signed(y);
            n_ops = n_ops + 1;
        end
    endtask

    integer k, seed;
    initial begin
        n_ops = 0; seed = 32'h1BADB002;
        add_op(  7,   6);          //  42
        add_op(  5,   9);          //  45
        add_op(  4,   8);          //  32
        add_op( 10,  20);          // 200
        add_op( -7,   6);          // negative x positive
        add_op(  7,  -6);          // positive x negative
        add_op( -7,  -6);          // negative x negative
        add_op(  0,   0);          // zero
        add_op(  0, 12345);
        add_op(12345,  0);
        add_op(-12345, 0);
        add_op(32'sh7FFFFFFF, 32'sh7FFFFFFF);   // max x max
        add_op(32'sh80000000, 32'sh80000000);   // min x min
        add_op(32'sh7FFFFFFF, 32'sh80000000);   // max x min
        add_op(32'sh80000000, 32'sh7FFFFFFF);   // min x max
        add_op(32'sh80000000, -1);              // min x -1 (= +2^31)
        add_op(-1, 32'sh80000000);
        add_op(-1, -1);
        add_op( 1, 32'sh80000000);
        add_op(32'sh80000000, 1);
        add_op(32'sh7FFFFFFF, 1);
        add_op(32'sh7FFFFFFF, -1);
        add_op(32'sh7FFFFFFF, 32'sh00000003);
        add_op(32'sh55555555, 32'sh55555555);
        add_op(32'shAAAAAAAA, 32'shAAAAAAAA);
        add_op(32'sh55555555, 32'shAAAAAAAA);
        add_op(32'shFFFFFFFF, 32'sh00000001);
        add_op(32'sh00010000, 32'sh00010000);
        add_op(32'sh0000FFFF, 32'sh0000FFFF);
        add_op(32'shFFFF0000, 32'sh0000FFFF);
        add_op(  100, -100);
        add_op( -100, 100);
        add_op( 1000000, 1000000);
        add_op(-1000000, 1000000);
        add_op(  3,   3);
        add_op( -3,   3);
        add_op(  5,  -5);
        add_op(  2147483000, -2147483000);
        add_op( 32'sh0000_0007, 32'sh4000_0000);
        add_op( 32'sh0000_0007, 32'shC000_0000);
        while (n_ops < N_DIR) add_op(n_ops, -n_ops);
        for (k = 0; k < N_RND; k = k + 1) add_op($random(seed), $random(seed));
        n_p1 = n_ops;
        for (k = 0; k < N_P2; k = k + 1) begin
            if (k % 3 == 0) add_op($random(seed) % 256, $random(seed) % 256);
            else            add_op($random(seed), $random(seed));
        end
    end

    integer drv_idx = 0, gap_seed = 7;
    integer first_drive_cyc = -1;
    reg     started = 0;

    always @(negedge clk) if (started) begin
        if (drv_idx < n_p1) begin
            a <= A_t[drv_idx]; b <= B_t[drv_idx]; in_valid <= 1'b1;
            T_in[drv_idx] = cyc;
            if (drv_idx == 0) first_drive_cyc = cyc;
            drv_idx = drv_idx + 1;
        end else if (drv_idx < n_ops) begin
            if ($random(gap_seed) & 1) begin
                a <= A_t[drv_idx]; b <= B_t[drv_idx]; in_valid <= 1'b1;
                T_in[drv_idx] = cyc;
                drv_idx = drv_idx + 1;
            end else begin
                a <= $random(gap_seed); b <= $random(gap_seed);   // garbage, must be ignored
                in_valid <= 1'b0;
            end
        end else in_valid <= 1'b0;
    end

    integer chk = 0, err = 0, lat, lat_min = 1000, lat_max = 0;
    integer first_out = -1, last_out_p1 = -1;

    always @(negedge clk) if (started && vld) begin
        if (chk < n_ops) begin
            lat = cyc - T_in[chk];
            if (lat < lat_min) lat_min = lat;
            if (lat > lat_max) lat_max = lat;
            if (prod !== E_t[chk]) begin
                err = err + 1;
                $display("[8 FAIL] #%0d %0d x %0d : got %0d expected %0d",
                         chk, A_t[chk], B_t[chk], prod, E_t[chk]);
            end else if (chk < N_DIR)
                $display("[8 ok  ] #%0d %0d x %0d = %0d", chk, A_t[chk], B_t[chk], prod);
            if (chk == 0)      first_out   = cyc;
            if (chk == n_p1-1) last_out_p1 = cyc;
        end
        chk = chk + 1;
    end

    initial begin
        repeat (4) @(posedge clk);
        @(negedge clk) rst = 0;
        @(negedge clk) started = 1;
        wait (drv_idx == n_ops);
        repeat (6) @(negedge clk);
        $display("");
        $display("============ RESULT SUMMARY (Radix-8) ============");
        $display("Operations driven : %0d (phase1 %0d back-to-back, phase2 %0d with bubbles)",
                 n_ops, n_p1, n_ops - n_p1);
        $display("Results checked   : %0d, errors %0d", chk, err);
        $display("TB-observed latency (drive -> observe, falling-edge count) min/max : %0d / %0d", lat_min, lat_max);
        $display("  = inclusive count of input-capture edge E_k and output-capture edge E_k+1 (2 register stages)");
        $display("  elapsed register-to-register latency E_k -> E_k+1 = 1 clock period");
        $display("First result observed %0d falling-edge counts after first drive", first_out - first_drive_cyc);
        $display("Back-to-back      : last of %0d results observed %0d counts after the first drive = N + 1 (pipeline fill); steady-state 1 mult/clock",
                 n_p1, last_out_p1 - first_drive_cyc);
        if (chk != n_ops)
            $display("*** TEST FAILED: result count %0d != %0d ***", chk, n_ops);
        else if (err == 0 && lat_min == 2 && lat_max == 2)
            $display("*** ALL TESTS PASSED ***");
        else
            $display("*** TEST FAILED ***");
        $display("===================================================");
        $finish;
    end

    initial begin
        #(CLK_NS * (N_MAX*3 + 200));
        $display("*** TIMEOUT ***");
        $finish;
    end
endmodule
