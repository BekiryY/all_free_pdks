# Magic DRC of a GDS (env GDS, TOP); writes "count<TAB>rule<TAB>first boxes" lines to env OUT.
# Used by scripts/drc.sh.
crashbackups stop
drc off
gds readonly true
gds read $::env(GDS)
load $::env(TOP)
select top cell
drc euclidean on
drc on
drc check
drc catchup
puts "DRC_COUNT [drc list count total]"
set f [open $::env(OUT) w]
foreach {why boxes} [drc listall why] { puts $f "[llength $boxes]\t$why\t[lrange $boxes 0 2]" }
close $f
quit -noprompt
