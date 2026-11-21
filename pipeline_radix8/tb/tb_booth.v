`timescale 1ns / 1ps
// (1) Pipeline MUL test incl. negative operands + forwarding of MUL results
// (2) Booth multiplier vs. Verilog '*' on random + corner-case vectors
module tb_booth;
    reg clk = 0, rst = 1;
    riscv32_pipeline_top dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    reg signed [31:0] ta, tb_; wire signed [63:0] tp;
    booth_radix8_mul #(32) u_chk (.multiplicand(ta), .multiplier(tb_), .product(tp));
    integer k, errs;

    task chk(input [4:0] r, input [31:0] exp, input [127:0] name);
        if (dut.u_rf.regs[r] !== exp) $display("FAIL: %0s x%0d = %h (expected %h)", name, r, dut.u_rf.regs[r], exp);
        else                          $display("PASS: %0s x%0d = %h", name, r, dut.u_rf.regs[r]);
    endtask

    initial begin
        dut.u_imem.mem[0]  = 32'h00700093; // ADDI x1,x0,7
        dut.u_imem.mem[1]  = 32'h00600113; // ADDI x2,x0,6
        dut.u_imem.mem[2]  = 32'h022081B3; // MUL  x3,x1,x2
        dut.u_imem.mem[3]  = 32'hFFB00213; // ADDI x4,x0,-5
        dut.u_imem.mem[4]  = 32'h00900293; // ADDI x5,x0,9
        dut.u_imem.mem[5]  = 32'h02520333; // MUL  x6,x4,x5
        dut.u_imem.mem[6]  = 32'hFFC00393; // ADDI x7,x0,-4
        dut.u_imem.mem[7]  = 32'hFF800413; // ADDI x8,x0,-8
        dut.u_imem.mem[8]  = 32'h028384B3; // MUL  x9,x7,x8
        dut.u_imem.mem[9]  = 32'h02118533; // MUL  x10,x3,x1  (x3 forwarded)
        dut.u_imem.mem[10] = 32'h001505B3; // ADD  x11,x10,x1 (x10 forwarded from MUL)
        @(negedge clk); rst = 0;
        repeat (25) @(negedge clk);
        chk(3,  32'd42,        "MUL 7*6");
        chk(6,  32'hFFFFFFD3,  "MUL -5*9");
        chk(9,  32'd32,        "MUL -4*-8");
        chk(10, 32'd294,       "MUL fwd 42*7");
        chk(11, 32'd301,       "ADD fwd 294+7");

        // standalone Booth check
        errs = 0;
        ta = 32'sh80000000; tb_ = 32'sh80000000; #1; if (tp !== ta*tb_) errs=errs+1;
        ta = 32'sh7FFFFFFF; tb_ = 32'sh80000000; #1; if (tp !== ta*tb_) errs=errs+1;
        ta = -1;            tb_ = -1;            #1; if (tp !== ta*tb_) errs=errs+1;
        ta = 0;             tb_ = 32'sh12345678; #1; if (tp !== ta*tb_) errs=errs+1;
        for (k = 0; k < 20000; k = k + 1) begin
            ta = $random; tb_ = $random; #1;
            if (tp !== ta*tb_) errs = errs + 1;
        end
        if (errs == 0) $display("PASS: Booth == '*' on 20004 vectors (signed 32x32->64)");
        else           $display("FAIL: Booth mismatches = %0d", errs);
        $finish;
    end
endmodule
