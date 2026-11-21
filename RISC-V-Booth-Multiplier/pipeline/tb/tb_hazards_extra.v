`timescale 1ns / 1ps
module tb_hazards_extra;

    reg clk, rst;
    riscv32_pipeline_top dut (.clk(clk), .rst(rst));
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        // ADDI x1,x0,10 ; ADDI x2,x0,20 ; ADD x3,x1,x2 (RAW x1,x2)
        // ADD x4,x3,x3 (back-to-back RAW on x3)
        // LW x5,0(x11) ; ADD x6,x5,x1 (load-use hazard on x5)
        dut.u_imem.mem[0] = 32'h00a00093; // ADDI x1,x0,10
        dut.u_imem.mem[1] = 32'h01400113; // ADDI x2,x0,20
        dut.u_imem.mem[2] = 32'h002081b3; // ADD  x3,x1,x2
        dut.u_imem.mem[3] = 32'h00318233; // ADD  x4,x3,x3
        dut.u_imem.mem[4] = 32'h0005a283; // LW   x5,0(x11)
        dut.u_imem.mem[5] = 32'h00128333; // ADD  x6,x5,x1
        dut.u_imem.mem[6] = 32'h00000013; // NOP padding
        dut.u_imem.mem[7] = 32'h00000013;

        dut.u_rf.regs[11] = 32'h00000000; // x11 = address 0
        dut.u_dmem.mem[0] = 32'h00000063; // mem[0] = 99 (decimal)

        @(negedge clk);
        rst = 0;

        repeat (16) @(negedge clk);

        if (dut.u_rf.regs[1] !== 32'd10) $display("FAIL: x1 = %0d (expected 10)", dut.u_rf.regs[1]);
        else                              $display("PASS: x1 = %0d", dut.u_rf.regs[1]);

        if (dut.u_rf.regs[2] !== 32'd20) $display("FAIL: x2 = %0d (expected 20)", dut.u_rf.regs[2]);
        else                              $display("PASS: x2 = %0d", dut.u_rf.regs[2]);

        if (dut.u_rf.regs[3] !== 32'd30) $display("FAIL: x3 = %0d (expected 30, tests EX/MEM forward)", dut.u_rf.regs[3]);
        else                              $display("PASS: x3 = %0d (EX/MEM forwarding worked)", dut.u_rf.regs[3]);

        if (dut.u_rf.regs[4] !== 32'd60) $display("FAIL: x4 = %0d (expected 60, tests back-to-back forward)", dut.u_rf.regs[4]);
        else                              $display("PASS: x4 = %0d (back-to-back forwarding worked)", dut.u_rf.regs[4]);

        if (dut.u_rf.regs[5] !== 32'd99) $display("FAIL: x5 = %0d (expected 99)", dut.u_rf.regs[5]);
        else                              $display("PASS: x5 = %0d", dut.u_rf.regs[5]);

        if (dut.u_rf.regs[6] !== 32'd109) $display("FAIL: x6 = %0d (expected 109 = 99+10, tests load-use stall+forward)", dut.u_rf.regs[6]);
        else                               $display("PASS: x6 = %0d (load-use hazard handled correctly)", dut.u_rf.regs[6]);

        #20 $finish;
    end
endmodule
