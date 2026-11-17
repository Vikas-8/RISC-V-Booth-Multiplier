# Design and Implementation of a 32-Bit Pipelined RISC-V Processor with an Efficient Multiplier

## Project Overview

This project focuses on the design and implementation of a 32-bit pipelined RISC-V processor using Verilog HDL and Xilinx Vivado. It explores a five-stage pipelined architecture and the integration of an efficient multiplier to improve arithmetic operation performance.

The project investigates processor architecture, pipeline operation, hazard handling and multiplier optimization through RTL design, simulation and FPGA implementation.

## Key Features

- 32-bit RISC-V processor architecture.
- Single-cycle processor implementation.
- Five-stage pipelined processor architecture.
- Radix-4 Booth multiplication.
- Radix-8 Booth multiplication and optimization.
- ALU and control unit design.
- Pipeline hazard detection and data forwarding.
- Instruction and data memory modules.

## Pipelined Architecture

The pipelined processor follows five stages:

1. **Instruction Fetch (IF):** Fetches instructions from instruction memory.
2. **Instruction Decode (ID):** Decodes instructions and reads register operands.
3. **Execute (EX):** Performs arithmetic and logical operations.
4. **Memory Access (MEM):** Handles data memory operations.
5. **Write Back (WB):** Writes results back into the register file.

Pipeline registers, forwarding logic and hazard detection mechanisms support instruction execution.

## Booth Multiplication Techniques

### Radix-4 Booth Multiplier
Uses radix-4 Booth encoding to reduce the number of partial products during multiplication.

### Radix-8 Booth Multiplier
Explores radix-8 Booth encoding to further reduce partial products and investigate multiplication hardware optimization.

## Hardware and Software Tools

- Verilog HDL
- Xilinx Vivado
- RTL Design
- Functional Simulation
- FPGA Synthesis and Implementation

## Performance Evaluation

The project explores the following evaluation parameters:

- Maximum operating frequency (Fmax)
- Critical path delay
- Hardware resource utilization
- Power consumption
- Throughput
- Comparison of single-cycle and pipelined architectures
- Comparison of Radix-4 and Radix-8 multiplication approaches

## Applications

- RISC-V processor architecture research
- FPGA-based processor implementation
- Digital system design
- Hardware optimization
- Computer architecture education and research

## Future Scope

- Further optimization of Booth multiplier architectures.
- Improvement of processor throughput.
- Reduction of hardware area and power consumption.
- Support for additional RISC-V instructions.
- Further FPGA-based performance evaluation.

## Conclusion

This project provides practical experience in RISC-V processor architecture, Verilog-based RTL design, pipelining and hardware multiplier optimization using Xilinx Vivado.
