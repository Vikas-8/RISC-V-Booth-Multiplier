//=============================================================================
// booth_pipe_wrapper.v  (Radix-8 project, v2)
// Registered wrapper - byte-for-byte the same structure in the Radix-4 and Radix-8 projects.
//
//   Stage 0 (INPUT REGISTERS)  : a_q, b_q, v_q  captured on rising edge E_k
//   Combinational Radix-8 Booth core : a_q, b_q -> p_core
//   Stage 1 (OUTPUT REGISTER)  : p, out_valid   captured on rising edge E_k+1
//
//   Input-capture  edge : rising edge E_k   (a_q, b_q, v_q load the operands)
//   Output-capture edge : rising edge E_k+1 (p / out_valid load the result of THOSE operands)
//
//   LATENCY DEFINITIONS (do not mix them):
//     * Capture-to-capture elapsed latency = E_k+1 - E_k = ONE clock period.
//       This is what the combinational core must fit into -> Tmin, Fmax, execution time.
//     * Register stages = 2 (input regs + output regs).
//     * Testbench inclusive edge count = 2 (it counts E_k and E_k+1 both). The TB drives on the
//       falling edge before E_k and observes on the falling edge after E_k+1, i.e. it sees
//       the result two falling-edge counts after driving. It is a counting convention,
//       NOT two clock periods of combinational delay.
//   Initiation interval = 1 -> one multiplication accepted and one completed per clock
//   once the pipeline is full.
//=============================================================================
`timescale 1ns/1ps
module booth_pipe_wrapper (
    input  wire               clk,
    input  wire               rst,       // synchronous, active-high (clears valid only)
    input  wire               in_valid,
    input  wire signed [31:0] a,
    input  wire signed [31:0] b,
    output reg                out_valid,
    output reg  signed [63:0] p
);
    reg signed [31:0] a_q, b_q;
    reg               v_q;
    wire signed [63:0] p_core;

    booth_radix8_comb u_core (.a(a_q), .b(b_q), .p(p_core));

    always @(posedge clk) begin
        a_q <= a;
        b_q <= b;
        v_q <= rst ? 1'b0 : in_valid;
        p         <= p_core;
        out_valid <= rst ? 1'b0 : v_q;
    end
endmodule
