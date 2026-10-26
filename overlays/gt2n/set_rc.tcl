# all_free_pdks: GT2N layer RC plus a realistic max slew.
#
# ORFS sources this after the SDC in every stage (LAYER_PARASITICS_FILE).
# GT2N's Liberty sets default_max_transition to 1000 ps, so repair accepts nets
# with hundreds of ps of slew: on low, resistive metal a long high-fanout net
# then costs 100-500 ps of wire delay. A tighter limit makes repair buffer them.
source $::env(PLATFORM_DIR)/setRC_fspdn.tcl
set_max_transition $::env(GT2N_MAX_TRANSITION) [current_design]
