`timescale 1ns / 1ps
module tb_basic_pipeline;

    reg clk, rst;

    riscv32_pipeline_top dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        // preload instruction memory directly (hierarchical access, sim-only)
        dut.u_imem.mem[0] = 32'h003100b3; // ADD  x1,x2,x3
        dut.u_imem.mem[1] = 32'h009473b3; // AND  x7,x8,x9
        dut.u_imem.mem[2] = 32'h01978713; // ADDI x14,x15,25
        dut.u_imem.mem[3] = 32'h008bab03; // LW   x22,8(x23)
        dut.u_imem.mem[4] = 32'h00000013; // NOP (ADDI x0,x0,0) - padding
        dut.u_imem.mem[5] = 32'h00000013;
        dut.u_imem.mem[6] = 32'h00000013;

        // preload register file / data memory (sim-only setup, matches paper's Tables 3-6)
        dut.u_rf.regs[2]  = 32'h0000004A; // x2
        dut.u_rf.regs[3]  = 32'h00000014; // x3
        dut.u_rf.regs[8]  = 32'hFF00FF00; // x8
        dut.u_rf.regs[9]  = 32'h0F0F0F0F; // x9
        dut.u_rf.regs[15] = 32'h00000010; // x15
        dut.u_rf.regs[23] = 32'h00000010; // x23
        dut.u_dmem.mem[32'h18 >> 2] = 32'h12345678;

        @(negedge clk);
        rst = 0;

        // 4 instructions, 5-stage pipeline -> first result at cycle 5,
        // last instruction issued at cycle 4 finishes at cycle 8. Give margin.
        repeat (12) @(negedge clk);

        if (dut.u_rf.regs[1]  !== 32'h0000005E) $display("FAIL: ADD  x1 = %h (expected 5E)", dut.u_rf.regs[1]);
        else                                    $display("PASS: ADD  x1 = %h", dut.u_rf.regs[1]);

        if (dut.u_rf.regs[7]  !== 32'h0F000F00) $display("FAIL: AND  x7 = %h (expected 0F000F00)", dut.u_rf.regs[7]);
        else                                    $display("PASS: AND  x7 = %h", dut.u_rf.regs[7]);

        if (dut.u_rf.regs[14] !== 32'h00000029) $display("FAIL: ADDI x14 = %h (expected 29)", dut.u_rf.regs[14]);
        else                                    $display("PASS: ADDI x14 = %h", dut.u_rf.regs[14]);

        if (dut.u_rf.regs[22] !== 32'h12345678) $display("FAIL: LW   x22 = %h (expected 12345678)", dut.u_rf.regs[22]);
        else                                    $display("PASS: LW   x22 = %h", dut.u_rf.regs[22]);

        #20 $finish;
    end

endmodule
