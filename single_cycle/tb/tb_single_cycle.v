`timescale 1ns / 1ps
// Reference test: ADD, SUB, MUL, AND (each uses the previous result)
//   x1=10  x2=20  x12=255
//   ADD x3,x1,x2   = 10+20  = 30
//   SUB x4,x3,x1   = 30-10  = 20
//   MUL x7,x4,x1   = 20*10  = 200
//   AND x10,x7,x12 = 200&255 = 200
module tb_single_cycle;

    reg clk = 0;
    reg rst = 1;
    wire [31:0] dbg_pc, dbg_wb;

    riscv32_top dut (.clk(clk), .rst(rst), .debug_pc(dbg_pc), .debug_wb(dbg_wb));

    always #5 clk = ~clk;

    // Actual ALU signals (add these to the waveform)
    wire [31:0] A   = dut.u_alu.ALUInA;
    wire [31:0] B   = dut.u_alu.ALUInB;
    wire [31:0] OUT = dut.u_alu.ALUOut;

    integer errors = 0;
    task check(input [31:0] got, input [31:0] exp, input [127:0] name);
        if (got !== exp) begin errors = errors + 1; $display("FAIL: %0s = %0d (expected %0d)", name, got, exp); end
        else $display("PASS: %0s = %0d", name, got);
    endtask

    initial begin
        #1;  // let the memories finish their own initial blocks first
        dut.u_imem.mem[0] = 32'h002081b3; // ADD x3,x1,x2
        dut.u_imem.mem[1] = 32'h40118233; // SUB x4,x3,x1
        dut.u_imem.mem[2] = 32'h021203b3; // MUL x7,x4,x1
        dut.u_imem.mem[3] = 32'h00c3f533; // AND x10,x7,x12
        dut.u_imem.mem[4] = 32'h00000013; // NOP
        dut.u_imem.mem[5] = 32'h00000013; // NOP
        dut.u_imem.mem[6] = 32'h00000013; // NOP
        dut.u_imem.mem[7] = 32'h00000013; // NOP

        dut.u_rf.regs[1]  = 32'd10;
        dut.u_rf.regs[2]  = 32'd20;
        dut.u_rf.regs[12] = 32'd255;

        $dumpfile("wave.vcd");
        $dumpvars(0, clk, rst, A, B, OUT);

        repeat (2) @(negedge clk);
        rst = 0;
        repeat (16) @(negedge clk);

        $display("========================================");
        $display("       SINGLE-CYCLE PROCESSOR");
        $display("========================================");
        check(dut.u_rf.regs[3],  32'd30,  "ADD x3 ");
        check(dut.u_rf.regs[4],  32'd20,  "SUB x4 ");
        check(dut.u_rf.regs[7],  32'd200, "MUL x7 ");
        check(dut.u_rf.regs[10], 32'd200, "AND x10");
        if (errors == 0) $display("ALL TESTS PASSED"); else $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
