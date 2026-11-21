# 100 MHz target clock (10 ns period)
create_clock -period 10.000 -name clk [get_ports clk]
set_property BITSTREAM.GENERAL.UNCONSTRAINEDPINS {Allow} [current_design]
