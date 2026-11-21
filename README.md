# 32-bit RISC-V Processor with Radix-4 and Radix-8 Booth Multipliers

A 32-bit RISC-V processor (RV32I subset plus `MUL`) in Verilog HDL. It comes in a single-cycle version and a 5-stage pipelined version, and the pipeline is extended with signed Radix-4 and Radix-8 Booth multipliers. Everything was designed, simulated and timing-analysed in Xilinx Vivado (Artix-7).

Final-year team project, Department of ECE, Amrita Vishwa Vidyapeetham, Amritapuri (2026).

## Repository layout

| Folder | Design |
|---|---|
| [`single_cycle/`](single_cycle) | Baseline single-cycle core |
| [`pipeline/`](pipeline) | 5-stage pipelined core with hazard handling |
| [`pipeline_radix4/`](pipeline_radix4) | Pipelined core with a Radix-4 Booth multiplier in EX |
| [`pipeline_radix8/`](pipeline_radix8) | Pipelined core with a Radix-8 Booth multiplier in EX |
| [`booth_radix8_standalone/`](booth_radix8_standalone) | Registered Radix-8 multiplier, used to measure multiplier timing |
| [`booth_radix8_et/`](booth_radix8_et) | Iterative Radix-8 Booth multiplier with **early termination** |

Each folder contains `rtl/` (design), `tb/` (self-checking testbenches), `constraints/` (Vivado XDC) and `run_sim.sh`.

## Processor

**Supported instructions:** `ADD`, `SUB`, `AND`, `OR`, `MUL`, `ADDI`, `LW`, `SW`, `BEQ`, `LUI`, `AUIPC`, `JAL` (single-cycle: R-type, `ADDI`, `LW`, `SW`, `BEQ`, `JAL`)

**Single-cycle core:** program counter, instruction memory, register file, control unit, immediate generator, ALU and data memory. Every instruction completes in one clock.

**5-stage pipeline:** IF → ID → EX → MEM → WB, with IF/ID, ID/EX, EX/MEM and MEM/WB registers.
- **EX forwarding** (`forwarding_unit.v`) forwards from EX/MEM and MEM/WB into the ALU, so dependent instructions run back-to-back.
- **Load-use stall** (`hazard_unit.v`) inserts a one-cycle bubble after a load whose result is needed immediately.
- **Early branch resolution in ID** (`branch_comparator.v`, `branch_forward_unit.v`): branches and jumps resolve in decode with forwarding into the comparator, so a taken branch flushes only one instruction.
- **Register-file write-first bypass** covers the WB→ID same-cycle case.

## Booth multipliers

| | Radix-4 | Radix-8 |
|---|---|---|
| Recoding | 3-bit overlapping groups, digits {0, ±1, ±2} | 4-bit overlapping groups, digits {0, ±1, ±2, ±3, ±4} |
| Partial products (32-bit) | 16 | 11 |
| Hard multiple | none | 3M = M + 2M, computed once |
| Summation | Balanced adder tree (4 levels) | Balanced adder tree (4 levels) |

Both are signed 32×32 → 64-bit and combinational, used by `MUL` in the EX stage. **Operand isolation** keeps the multiplier inputs at zero unless a `MUL` is in EX, which cuts switching activity. The single-cycle and plain pipeline cores use Vivado's `*` operator, which maps to DSP blocks, as the baseline.

`booth_radix8_standalone` wraps a Radix-8 core between input and output registers (one multiplication per clock, 2 register stages). That gives a clean register-to-register path for measuring timing: `Tmin = Ttarget − WNS`, `Fmax = 1000 / Tmin`.

## Early termination (`booth_radix8_et`)

An iterative Radix-8 Booth multiplier that processes one Booth digit (3 multiplier bits) per clock, using a start/done handshake.

- After each step it checks the multiplier bits not yet processed. If they're all sign-extension bits (all 0s after a 0, or all 1s after a 1), every remaining Booth digit is zero, so it **stops early** and releases the product.
- Worst case is 11 digit steps (12 clocks). Small-magnitude multipliers finish in far fewer.
- `iter_count` reports how many digits were actually processed.

Average latency measured by the regression testbench (12 clocks without early termination):

| Operand class | Avg latency | Reduction |
|---|---|---|
| Random 16-bit multipliers | 6.42 clk | **46.5%** |
| Powers of two | 8.64 clk | 28.0% |
| Dense bit patterns | 9.92 clk | 17.3% |
| Sparse bit patterns | 10.03 clk | 16.4% |
| Random full 32-bit | 11.71 clk | 2.4% |

## Verification

All testbenches are self-checking. In any folder, run:

```sh
sh run_sim.sh     # needs Icarus Verilog
```

| Design | Testbenches | Result |
|---|---|---|
| `single_cycle` | ADD, SUB, MUL, AND, SW, LW; a looping program on the hardware wrapper | 14/14 pass |
| `pipeline` | Basic pipeline flow, EX/MEM and back-to-back forwarding, load-use stall, a hardware-wrapper program | 24/24 pass |
| `pipeline_radix4` | Pipeline + hazards; signed `MUL` incl. negative operands and forwarding; Booth vs. Verilog `*` on **20,004 random and corner-case vectors** | 20/20 pass |
| `pipeline_radix8` | Same suite with the Radix-8 multiplier, incl. 20,004-vector Booth check | 20/20 pass |
| `booth_radix8_standalone` | 40 directed corner cases (e.g. `−2³¹ × −2³¹`) plus **3,040 back-to-back and bubbled operations**, 0 errors, 1 result per clock | All pass |
| `booth_radix8_et` | **12,871 operations** (sign combinations, boundaries, powers of two, sparse/dense patterns, random 4- to 32-bit), checking the product, iteration count against a golden model, latency and the done/busy handshake | 12,871/12,871 pass |

In Vivado, add `rtl/` as design sources, `tb/` as simulation sources and `constraints/` as constraints, then run behavioral simulation with any testbench as top.

## Results (Vivado timing analysis, from the project report)

| Design | Fmax |
|---|---|
| Single-cycle core | 60.64 MHz |
| 5-stage pipelined core | 72.82 MHz (~20% higher) |
| Radix-4 Booth multiplier | 84.57 MHz |
| Radix-8 Booth multiplier | 101.13 MHz (~19.6% higher than Radix-4) |

## Notes

- Programs are loaded into instruction memory by the testbenches (or by `PRELOAD` in the single-cycle and pipeline hardware wrappers).
- `pipeline_radix4/rtl/riscv32_pipeline_hw.v` only exposes `PC[7:0]` and its instruction memory is empty, so Vivado optimises most of that core away during implementation. Use the single-cycle and pipeline wrappers (which preload a program and observe write-back data) as the model for implementation runs.
- Only `BEQ` is implemented among the conditional branches.
