# all_free_pdks: POST_PDN_TCL for GT2N designs.
#
# Runs GT2N's own tap-to-M3 hookup (from its ORFS example), then removes empty
# special wires. With OpenROAD dcf3613 (LibreLane 3.0.6) the PDN leaves an
# empty swire on VDD/VSS, written to DEF as a bare "+ ROUTED"; KLayout 0.30
# cannot parse that, so the final GDS merge fails.
if { [env_var_exists_and_non_empty GT2N_POST_PDN_TCL] } {
  source $::env(GT2N_POST_PDN_TCL)
}

foreach net [[ord::get_db_block] getNets] {
  foreach sw [$net getSWires] {
    if { [llength [$sw getWires]] == 0 } {
      puts "all_free_pdks: removing empty special wire on [$net getName]"
      odb::dbSWire_destroy $sw
    }
  }
}
