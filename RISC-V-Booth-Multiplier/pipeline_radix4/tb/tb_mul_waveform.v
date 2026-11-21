
`timescale 1ns / 1ps

module tb_mul_waveform;

    reg signed [31:0] A;
    reg signed [31:0] B;
    wire signed [63:0] MUL_Result;

    booth_radix4_mul #(32) uut (
        .multiplicand(A),
        .multiplier(B),
        .product(MUL_Result)
    );

    initial begin
        $display("========================================");
        $display("       RADIX-4 BOOTH MULTIPLIER");
        $display("========================================");

        // MUL 1: 7 x 6 = 42
        A = 32'sd7;
        B = 32'sd6;
        #10;
        if (MUL_Result == 64'sd42)
            $display("PASS: MUL 7 x 6 = %0d", MUL_Result);
        else
            $display("FAIL: MUL 7 x 6 = %0d", MUL_Result);

        // MUL 2: 5 x 9 = 45
        A = 32'sd5;
        B = 32'sd9;
        #10;
        if (MUL_Result == 64'sd45)
            $display("PASS: MUL 5 x 9 = %0d", MUL_Result);
        else
            $display("FAIL: MUL 5 x 9 = %0d", MUL_Result);

        // MUL 3: 4 x 8 = 32
        A = 32'sd4;
        B = 32'sd8;
        #10;
        if (MUL_Result == 64'sd32)
            $display("PASS: MUL 4 x 8 = %0d", MUL_Result);
        else
            $display("FAIL: MUL 4 x 8 = %0d", MUL_Result);

        // MUL 4: 10 x 20 = 200
        A = 32'sd10;
        B = 32'sd20;
        #10;
        if (MUL_Result == 64'sd200)
            $display("PASS: MUL 10 x 20 = %0d", MUL_Result);
        else
            $display("FAIL: MUL 10 x 20 = %0d", MUL_Result);

        $display("----------------------------------------");
        $display("       MULTIPLIER TESTS COMPLETED");
        $display("========================================");

        $finish;
    end

endmodule
