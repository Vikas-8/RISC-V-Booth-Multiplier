#!/bin/sh
# Runs every testbench with Icarus Verilog (iverilog 11+).
# Usage: sh run_sim.sh
set -e
cd "$(dirname "$0")"
mkdir -p build
for tb in tb_riscv32_pipeline tb_hazards tb_booth tb_mul_waveform; do
    echo "==== $tb"
    iverilog -g2012 -o build/$tb.vvp -s $tb rtl/*.v tb/$tb.v
    vvp -n build/$tb.vvp
done
