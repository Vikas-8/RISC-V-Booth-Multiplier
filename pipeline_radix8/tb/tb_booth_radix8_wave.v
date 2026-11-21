`timescale 1ns / 1ps
// Same stimulus as the Radix-4 run: 4 vectors, 10 ns apart, 40 ns total.
module tb_booth_radix8_wave;
    reg  signed [31:0] A, B;
    wire signed [63:0] MUL_Result;

    booth_radix8_mul #(32) dut (.multiplicand(A), .multiplier(B), .product(MUL_Result));

    task check(input integer a, input integer b);
        begin
            A = a; B = b; #10;
            if (MUL_Result === a*b) $display("PASS: MUL %0d x %0d = %0d", a, b, MUL_Result);
            else $display("FAIL: MUL %0d x %0d = %0d (expected %0d)", a, b, MUL_Result, a*b);
        end
    endtask

    initial begin
        $dumpfile("tb_booth_radix8_wave.vcd");
        $dumpvars(0, tb_booth_radix8_wave);
        $display("        RADIX-8 BOOTH MULTIPLIER");
        $display("========================================");
        check(7, 6);
        check(5, 9);
        check(4, 8);
        check(10, 20);
        $display("----------------------------------------");
        $finish;
    end
endmodule
