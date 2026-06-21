# Default SDC for Top_module_pipeline_RISC_V_32I
# Override values to match your target technology and board assumptions.

# Tần số 20MHz tương ứng với chu kỳ 50ns
create_clock -name clk -period 50.000 [get_ports clk]
set_clock_transition 0.100 [get_clocks clk]

# Ignore asynchronous reset path in timing.
set_false_path -from [get_ports rst_n]

# Input delays relative to clk (Điều chỉnh lên 2.0ns để phù hợp với chu kỳ 50ns)
set_input_delay 2.000 -clock [get_clocks clk] [get_ports start]
set_input_delay 2.000 -clock [get_clocks clk] [get_ports DataOrReg]
set_input_delay 2.000 -clock [get_clocks clk] [get_ports {check_address[*]}]
set_input_delay 2.000 -clock [get_clocks clk] [get_ports {instruction[*]}]
set_input_delay 2.000 -clock [get_clocks clk] [get_ports {address[*]}]

# Output delay relative to clk.
set_output_delay 2.000 -clock [get_clocks clk] [get_ports {value[*]}]