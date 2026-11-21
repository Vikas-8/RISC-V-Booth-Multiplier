set_property IOSTANDARD LVCMOS33 [get_ports {clk rst {debug_out[*]}}]
# Timing constraints - riscv32_single_cycle
# Top module: riscv32_top_hw
# 100 MHz clock. To find Fmax: lower -period step by step (8, 6, 5 ...) and re-run
# until WNS is just above 0.  Fmax ~= 1 / (period - WNS).
create_clock -period 10.000 -name clk [get_ports clk]

# I/O timing (removes the "missing input/output delay" TIMING-18 warnings)
set_input_delay -clock clk 2.000 [get_ports rst]
set_output_delay -clock clk 2.000 [get_ports {debug_out[*]}]

# No board pinout is used (timing/area/power study only)
set_property BITSTREAM.GENERAL.UNCONSTRAINEDPINS Allow [current_design]

create_clock -period 20.000 -name clk [get_ports clk]
