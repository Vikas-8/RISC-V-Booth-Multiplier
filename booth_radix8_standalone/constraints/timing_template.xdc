# Clock constraint for the GUI project. IDENTICAL in the Radix-4 and Radix-8 projects.
# 5.000 ns is only a *target* given to the tools (same value as TARGET_NS in run_timing.tcl).
# It is NOT the measured Fmax. Fmax is calculated afterwards:  Tmin = T_target - WNS ; Fmax = 1000 / Tmin
create_clock -period 5.000 -name clk [get_ports clk]

create_clock -period 5.000 -name clk [get_ports clk]
