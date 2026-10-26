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

# A row crossed by a global M2 PDN stripe (and often a tap's M2 jog beside it)
# has too few free M2 tracks for pin access. The router then drops V1 vias at
# pin ends next to the row boundary, which violates M1 end-of-line keepout
# against pins in the neighbouring row (Lef58EolKeepOut, which detailed routing
# cannot repair). Keep standard cells other than taps out of those rows; the
# stripes are 3 um apart, so this blocks about 5% of the rows.
set block [ord::get_db_block]
set core [$block getCoreArea]
set half_core [expr {([$core xMax] - [$core xMin]) / 2}]
# M2 minimum spacing, 12 nm
set m2_space [expr {int(0.012 * [$block getDefUnits])}]
set stripes {}
foreach net {VDD VSS} {
  foreach sw [[$block findNet $net] getSWires] {
    foreach box [$sw getWires] {
      if { [$box isVia] || [[$box getTechLayer] getName] ne "M2" } { continue }
      if { [$box xMax] - [$box xMin] > $half_core } {
        lappend stripes [list [expr {[$box yMin] - $m2_space}] [expr {[$box yMax] + $m2_space}]]
      }
    }
  }
}
set taps {}
foreach inst [$block getInsts] {
  if { [[$inst getMaster] getName] eq $::env(TAP_CELL_NAME) } {
    lappend taps [$inst getBBox]
  }
}
set blocked 0
foreach row [$block getRows] {
  set rb [$row getBBox]
  set ylo [$rb yMin]
  set yhi [$rb yMax]
  set crossed 0
  foreach s $stripes {
    if { [lindex $s 1] > $ylo && [lindex $s 0] < $yhi } { set crossed 1; break }
  }
  if { !$crossed } { continue }
  # Leave the row's tap cells outside the blockages
  set edges {}
  foreach tap $taps {
    if { [$tap yMin] < $yhi && [$tap yMax] > $ylo } {
      lappend edges [list [$tap xMin] [$tap xMax]]
    }
  }
  set x [$rb xMin]
  foreach e [lsort -integer -index 0 $edges] {
    if { [lindex $e 0] > $x } {
      odb::dbBlockage_create $block $x $ylo [lindex $e 0] $yhi
    }
    set x [expr {max($x, [lindex $e 1])}]
  }
  if { [$rb xMax] > $x } {
    odb::dbBlockage_create $block $x $ylo [$rb xMax] $yhi
  }
  incr blocked
}
puts "all_free_pdks: blocked placement in $blocked rows crossed by M2 PDN stripes"
