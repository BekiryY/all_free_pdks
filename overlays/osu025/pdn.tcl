# All values are multiples of the 0.075 um manufacturing grid.
# Cell rails: vdd/gnd on metal1, 0.9 um wide, centred on the row boundaries.
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^vdd$} -power
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^gnd$} -ground
global_connect

set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}

define_pdn_grid -name {grid} -voltage_domains {CORE} -pins {metal5}
add_pdn_stripe -grid {grid} -layer {metal1} -width {0.9} -followpins
add_pdn_stripe -grid {grid} -layer {metal4} -width {2.4} -pitch {60.0} -offset {7.5}
add_pdn_stripe -grid {grid} -layer {metal5} -width {2.4} -pitch {60.0} -offset {7.5}
add_pdn_connect -grid {grid} -layers {metal1 metal4}
add_pdn_connect -grid {grid} -layers {metal4 metal5}
