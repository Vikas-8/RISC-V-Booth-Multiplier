`timescale 1ns / 1ps
// Checks the hardware top (PRELOAD program: ALU ops, SW, LW, load-use, BEQ loop)
module tb_hw_check;
    reg clk = 0, rst = 1; wire [7:0] dbg;
    riscv32_top_hw dut (.clk(clk), .rst(rst), .debug_out(dbg));
    always #5 clk = ~clk;
    integer errors = 0;
    task check(input [31:0] got, input [31:0] exp, input [127:0] name);
        if (got !== exp) begin errors = errors + 1; $display("FAIL: %0s = %0d (expected %0d)", name, got, exp); end
        else $display("PASS: %0s = %0d", name, got);
    endtask
    initial begin
        #12 rst = 0;
        #1000;
        check(dut.u_core.u_rf.regs[3],  32'd30,  "x3  ADD");
        check(dut.u_core.u_rf.regs[4],  32'd20,  "x4  SUB");
        check(dut.u_core.u_rf.regs[7],  32'd200, "x7  MUL");
        check(dut.u_core.u_rf.regs[10], 32'd200, "x10 AND");
        check(dut.u_core.u_dmem.mem[0], 32'd200, "mem0 SW");
        check(dut.u_core.u_rf.regs[13], 32'd200, "x13 LW ");
        check(dut.u_core.u_rf.regs[14], 32'd230, "x14 ADD");
        if (dut.u_core.debug_pc > 32'h28) begin errors = errors + 1; $display("FAIL: PC left the loop: %h", dut.u_core.debug_pc); end
        else $display("PASS: PC is looping (pc=%h)", dut.u_core.debug_pc);
        if (errors == 0) $display("ALL TESTS PASSED"); else $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
