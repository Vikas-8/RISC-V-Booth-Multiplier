#!/bin/sh
# Runs every testbench in tb/ with Icarus Verilog (iverilog 11+).
# Usage: sh run_sim.sh
set -e
cd "$(dirname "$0")"
mkdir -p build
for f in tb/*.v; do
    tb=$(sed -n 's/^[[:space:]]*module[[:space:]]\{1,\}\([A-Za-z0-9_]*\).*/\1/p' "$f" | head -n 1)
    echo "==== $tb"
    iverilog -g2012 -o "build/$tb.vvp" -s "$tb" rtl/*.v "$f"
    (cd build && vvp -n "$tb.vvp")
done
