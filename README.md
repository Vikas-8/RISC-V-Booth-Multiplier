# 32-bit RISC-V Processor with Radix-4 and Radix-8 Booth Multipliers

A 32-bit RISC-V (RV32I subset + MUL) processor in Verilog HDL, built in two versions (single-cycle and 5-stage pipelined) and extended with signed Booth multipliers for hardware multiplication. It was designed, simulated and timing-analysed in Xilinx Vivado.

Final-year team project, Department of ECE, Amrita Vishwa Vidyapeetham, Amritapuri (2026).

## Repository layout

| Folder | Contents | Status |
|---|---|---|
| [`pipeline_radix4/`](pipeline_radix4) | 5-stage pipelined core with a Radix-4 Booth multiplier | ✅ Added |
| `pipeline_radix8/` | Pipelined core with a Radix-8 Booth multiplier and early termination | Coming soon |
| `single_cycle/` | Baseline single-cycle core | Coming soon |

Each folder contains `rtl/` (design), `tb/` (self-checking testbenches), `constraints/` (Vivado XDC) and a `run_sim.sh` script.

## Pipelined core (`pipeline_radix4`)

**Stages:** IF → ID → EX → MEM → WB, with IF/ID, ID/EX, EX/MEM and MEM/WB pipeline registers.

**Supported instructions:** `ADD`, `SUB`, `AND`, `OR`, `MUL`, `ADDI`, `LW`, `SW`, `BEQ`, `LUI`, `AUIPC`, `JAL`

**Hazard handling**
- **EX forwarding** (`forwarding_unit.v`) forwards results from EX/MEM and MEM/WB into the ALU inputs, so back-to-back dependent instructions run without stalls.
- **Load-use stall** (`hazard_unit.v`) inserts a one-cycle bubble when an instruction needs the result of the load just before it.
- **Early branch resolution in ID** (`branch_comparator.v`, `branch_forward_unit.v`): branches and jumps resolve in the decode stage, with forwarding into the comparator, so a taken branch costs only one flushed instruction.
- **Register-file write-first bypass** covers the WB→ID same-cycle case.

**Radix-4 Booth multiplier** (`booth_radix4_mul.v`)
- Signed 32×32 → 64-bit, combinational, used by `MUL` in the EX stage
- 16 partial products from {0, ±M, ±2M}, summed with a **balanced adder tree** (4 levels instead of a 15-deep adder chain) to shorten the critical path
- **Operand isolation:** the multiplier inputs are held at zero unless a `MUL` is in EX, which cuts switching activity and dynamic power

## Verification

All testbenches are self-checking and print `PASS`/`FAIL`. To run them with Icarus Verilog:

```sh
cd pipeline_radix4
sh run_sim.sh
```

| Testbench | What it checks | Result |
|---|---|---|
| `tb_riscv32_pipeline` | ADD, AND, ADDI and LW through the full pipeline | 4/4 pass |
| `tb_hazards` | EX/MEM forwarding, back-to-back forwarding, load-use stall and forward | 6/6 pass |
| `tb_booth` | Signed MUL in the pipeline (incl. negative operands and forwarding of MUL results), plus the Booth unit vs. Verilog `*` on **20,004 random and corner-case vectors** (incl. `0x80000000 × 0x80000000`) | 6/6 pass |
| `tb_mul_waveform` | Standalone multiplier waveform test | 4/4 pass |

In Vivado, add `rtl/` as design sources, `tb/` as simulation sources and `constraints/` as constraints, then run behavioral simulation with the testbench of your choice as top.

## Results (from the project report, Vivado timing analysis)

| Design | Max frequency |
|---|---|
| Single-cycle core | 60.64 MHz |
| 5-stage pipelined core | 72.82 MHz (~20% higher) |
| Radix-4 Booth multiplier | 84.57 MHz |
| Radix-8 Booth multiplier | 101.13 MHz (~19.6% higher; 11 partial-product groups vs. 16) |

Radix-8 with early termination cuts the average multiply cycle count by up to 46.5% for small operands.

## Notes

- Programs are loaded into instruction memory from the testbenches (hierarchical access in simulation).
- `riscv32_pipeline_hw.v` is a thin wrapper for implementation that exposes `PC[7:0]` on `debug_out`. For meaningful post-implementation utilization numbers, the instruction memory must hold a real program and more internal state should be routed to outputs. Otherwise Vivado optimises away logic it can't observe.
- Only `BEQ` is implemented among the conditional branches.
