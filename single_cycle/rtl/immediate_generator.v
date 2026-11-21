`timescale 1ns / 1ps
// Immediate Generator - matches "Immediate Generator" block in Fig. 2
// Decodes and sign-extends the immediate field per Table 1 in the paper.
module immediate_generator (
    input  wire [31:0] IMOut,   // full instruction word
    output reg  [31:0] IGOut
);
    wire [6:0] opcode = IMOut[6:0];

    always @(*) begin
        case (opcode)
            7'b0010011, 7'b0000011: // I-type: ADDI, LW
                IGOut = {{20{IMOut[31]}}, IMOut[31:20]};

            7'b0100011: // S-type: SW
                IGOut = {{20{IMOut[31]}}, IMOut[31:25], IMOut[11:7]};

            7'b1100011: // B-type: BEQ
                IGOut = {{19{IMOut[31]}}, IMOut[31], IMOut[7],
                          IMOut[30:25], IMOut[11:8], 1'b0};

            7'b0110111, 7'b0010111: // U-type: LUI, AUIPC
                IGOut = {IMOut[31:12], 12'b0};

            7'b1101111: // J-type: JAL
                IGOut = {{11{IMOut[31]}}, IMOut[31], IMOut[19:12],
                          IMOut[20], IMOut[30:21], 1'b0};

            default:
                IGOut = 32'b0;
        endcase
    end
endmodule
