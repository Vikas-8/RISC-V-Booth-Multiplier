
# Clock constraint: 10 ns = 100 MHz
create_clock -name clk -period 10.000 [get_ports clk]

# Clock uncertainty: 0.2 ns
set_clock_uncertainty 0.200 [get_clocks clk]

