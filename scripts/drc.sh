#!/usr/bin/env bash
# Optional signoff DRC for the PDKs whose flow does not run a full deck:
#
#   scripts/drc.sh <pdk> <gds> [top cell]
#
#   icsprout55  KLayout, this repo's metal/via deck translated from the
#               foundry's Calibre deck (front-end rules are not covered)
#   gf180mcuD   KLayout, the PDK's full deck (LibreLane 3.0.6 skips it)
#   osu025      Magic, with upstream's MOSIS SCMOS tech file
#
# The others are checked by their flow: LibreLane runs Magic and KLayout DRC
# on sky130A and ihp-sg13g2, and ORFS has `make drc` for nangate45, asap7 and
# gt2n. Writes the report next to the GDS and prints the violation count.
# Needs LibreLane's tools on PATH (e.g. inside LibreLane's nix-shell).
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
usage() { sed -n '2,15s/^# \{0,1\}//p' "$0"; exit 1; }
[ $# -ge 2 ] || usage
pdk="$1" gds="$(realpath "$2")" top="${3:-}"
test -f "$gds" || { echo "error: no file $gds" >&2; exit 1; }
pdk_root="${PDK_ROOT:-$here/pdks}"
base="${gds%.gds}"
threads="$(nproc)"

count_lyrdb() {
  python3 - "$1" <<'PY'
import sys, collections, xml.etree.ElementTree as ET
c = collections.Counter(i.findtext("category").strip("'") for i in ET.parse(sys.argv[1]).getroot().iter("item"))
for k, n in c.most_common():
    print(f"  {n:8}  {k}")
print(f"DRC violations: {sum(c.values())}")
PY
}

case "$pdk" in
  icsprout55)
    report="$base.drc.lyrdb"
    klayout -b -r "$pdk_root/icsprout55/libs.tech/klayout/drc/icsprout55_beol.drc" \
      -rd input="$gds" ${top:+-rd topcell="$top"} -rd report="$report" -rd thr="$threads" >"$base.drc.log"
    count_lyrdb "$report" ;;
  gf180mcuD)
    # The switches run_drc.py sets for variant D (5 metals, 11K top metal, MIM option B)
    report="$base.drc.lyrdb"
    klayout -b -r "$pdk_root/gf180mcuD/libs.tech/klayout/tech/drc/gf180mcu.drc" \
      -rd input="$gds" ${top:+-rd topcell="$top"} -rd report="$report" -rd thr="$threads" \
      -rd run_mode=deep -rd metal_top=11K -rd mim_option=B -rd metal_level=5LM \
      -rd feol=true -rd beol=true -rd offgrid=true -rd conn_drc=true -rd density=false \
      -rd split_deep=false -rd slow_via=false -rd verbose=false >"$base.drc.log"
    count_lyrdb "$report" ;;
  osu025)
    report="$base.drc.txt"
    [ -n "$top" ] || top="$(python3 -c 'import sys, klayout.db as db; l = db.Layout(); l.read(sys.argv[1]); print(l.top_cell().name)' "$gds")"
    test -f "$pdk_root/osu025/tsmc025.tech" || { echo "error: no $pdk_root/osu025/tsmc025.tech; rerun install_pdks.py" >&2; exit 1; }
    GDS="$gds" TOP="$top" OUT="$report" magic -dnull -noconsole -T "$pdk_root/osu025/tsmc025.tech" \
      "$here/scripts/magic_drc.tcl" >"$base.drc.log"
    if ! grep -q DRC_COUNT "$base.drc.log" || grep -q "couldn't be read" "$base.drc.log"; then
      echo "error: Magic could not check $gds, see $base.drc.log" >&2; exit 1
    fi
    sort -rn "$report" | cut -f1,2 | sed 's/^/  /'
    grep DRC_COUNT "$base.drc.log" | sed 's/DRC_COUNT/DRC violations:/' ;;
  *) echo "error: $pdk: no optional DRC here (see the header of $0)" >&2; exit 1 ;;
esac
