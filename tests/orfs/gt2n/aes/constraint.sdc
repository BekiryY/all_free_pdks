current_design aes_cipher_top

# Same structure as GT2N's own AES example constraints.
set_units -time ps -resistance Ohm -capacitance pF -voltage V -current mA

set clk_name clk
set clk_port [get_ports clk]
set rst_port [get_ports rst]
set clk_period 500
set io_delay_max [expr $clk_period * 0.20]
set io_delay_min [expr $clk_period * 0.10]

create_clock -name $clk_name -period $clk_period $clk_port
set non_clock_inputs [all_inputs -no_clocks]
set_input_delay -max $io_delay_max -clock $clk_name $non_clock_inputs
set_input_delay -min $io_delay_min -clock $clk_name $non_clock_inputs
set_output_delay -max $io_delay_max -clock $clk_name [all_outputs]
set_output_delay -min $io_delay_min -clock $clk_name [all_outputs]

set_false_path -from $rst_port
# Block-level test: input hold depends on the parent's clock insertion delay
# (~160 ps here), which a standalone block cannot know.
set_false_path -hold -from $non_clock_inputs
