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

# The low-power adder and multiplier are only used in low-power mode and get
# 20 cycles, as in the original constraints. Written against the nets they
# drive so it survives flattening.
set lp_nets [get_nets -quiet {adder_lp_out[*] mult_lp_out[*]}]
if { [llength $lp_nets] > 0 } {
  set_multicycle_path 20 -setup -through $lp_nets
  set_multicycle_path 19 -hold -through $lp_nets
}
