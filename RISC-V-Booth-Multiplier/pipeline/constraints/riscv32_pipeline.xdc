# 20 ns (50 MHz) is a safe first target; see the Fmax note below
create_clock -period 20.000 -name clk [get_ports clk]

# Study-only pins: don't time them
set_false_path -from [get_ports rst]
set_false_path -to   [get_ports {debug_out[*]}]

set_property IOSTANDARD LVCMOS33 [get_ports {clk rst debug_out[*]}]
set_property SEVERITY {Warning} [get_drc_checks {NSTD-1 UCIO-1}]
set_property BITSTREAM.GENERAL.UNCONSTRAINEDPINS {Allow} [current_design]