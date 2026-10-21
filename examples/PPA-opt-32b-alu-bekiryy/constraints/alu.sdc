# Constraints for ALU_TOP on the open PDKs, adapted from the original
# genus/inputs/ALU_TOP.sdc (GPDK045, 0.355 ns). The clock period comes from
# the flow, in the PDK's own time unit:
#   LibreLane: CLOCK_PERIOD (ns)
#   ORFS:      ALU_CLOCK_PERIOD (ns, or ps on asap7/gt2n)
if { [info exists ::env(ALU_CLOCK_PERIOD)] } {
  set clk_period $::env(ALU_CLOCK_PERIOD)
} else {
  set clk_period $::env(CLOCK_PERIOD)
}

create_clock -name clk -period $clk_period [get_ports clk]
set_clock_uncertainty [expr {0.02 * $clk_period}] [get_clocks clk]

set inputs [get_ports {A[*] B[*] CMD[*] input_valid idle low_power reset_n}]
set outputs [all_outputs]

set_input_delay -max [expr {0.20 * $clk_period}] -clock clk $inputs
set_input_delay -min [expr {0.10 * $clk_period}] -clock clk $inputs
set_output_delay -max [expr {0.20 * $clk_period}] -clock clk $outputs
set_output_delay -min [expr {0.0 * $clk_period}] -clock clk $outputs

# Block-level example: input hold depends on the parent's clock insertion delay.
set_false_path -hold -from $inputs

# Time turbo mode. The original constraints gave the combinational low-power
# adder/multiplier 20 cycles via -through [get_cells adder_lp/mult_lp]; those
# instances do not survive flattening, so the mode is fixed instead: with
# low_power = 0 their inputs are forced to 0 and their paths are not timed.
# Low-power mode itself (180 MHz in the original) is not analysed here.
set_case_analysis 0 [get_ports low_power]
