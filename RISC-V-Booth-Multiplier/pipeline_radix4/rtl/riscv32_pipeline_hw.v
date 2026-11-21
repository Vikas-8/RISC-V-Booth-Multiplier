module riscv32_pipeline_hw (
    input  wire       clk,
    input  wire       rst,
    output wire [7:0] debug_out
);

    riscv32_pipeline_top dut (
        .clk(clk),
        .rst(rst)
    );

    // Make internal processor activity observable
    assign debug_out = dut.PCOut[7:0];

endmodule