# Constraints for ALU_TOP on the open PDKs, adapted from the original
# genus/inputs/ALU_TOP.sdc (GPDK045, 0.355 ns). The clock period comes from
# the flow, in the PDK's own time unit:
#   LibreLane: CLOCK_PERIOD (ns)
#   ORFS:      ALU_CLOCK_PERIOD (ns, or ps on asap7/gt2n)
# ALU_MODE=lowpower (set by lowpower_report.sh) analyses low-power mode with
# ALU_LP_CLOCK_PERIOD instead.
set alu_mode [expr {[info exists ::env(ALU_MODE)] ? $::env(ALU_MODE) : "turbo"}]
if { [info exists ::env(ALU_CLOCK_PERIOD)] } {
  set turbo_period $::env(ALU_CLOCK_PERIOD)
} else {
  set turbo_period $::env(CLOCK_PERIOD)
}
set clk_period [expr {$alu_mode eq "lowpower" ? $::env(ALU_LP_CLOCK_PERIOD) : $turbo_period}]

create_clock -name clk -period $clk_period [get_ports clk]
# Jitter/skew margin does not grow with a slower clock: same in both modes.
set_clock_uncertainty [expr {0.02 * $turbo_period}] [get_clocks clk]

set inputs [get_ports {A[*] B[*] CMD[*] input_valid idle low_power reset_n}]
set outputs [all_outputs]

set_input_delay -max [expr {0.20 * $clk_period}] -clock clk $inputs
set_input_delay -min [expr {0.10 * $clk_period}] -clock clk $inputs
set_output_delay -max [expr {0.20 * $clk_period}] -clock clk $outputs
set_output_delay -min [expr {0.0 * $clk_period}] -clock clk $outputs

# Block-level example: input hold depends on the parent's clock insertion delay.
set_false_path -hold -from $inputs

# The ALU is dual-mode. Implementation is timed in turbo mode: the original
# constraints gave the combinational low-power adder/multiplier 20 cycles via
# -through [get_cells adder_lp/mult_lp], but those instances do not survive
# flattening, so the mode is fixed instead (with low_power = 0 their inputs
# are forced to 0). Low-power mode is analysed on the finished layout.
set_case_analysis [expr {$alu_mode eq "lowpower" ? 1 : 0}] [get_ports low_power]
