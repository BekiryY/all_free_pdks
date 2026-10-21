#!/usr/bin/env bash
# Smoke test: run LibreLane's bundled spm example on one fab PDK.
# Needs `librelane` on PATH (e.g. inside LibreLane's nix-shell).
#   tests/librelane/run_spm.sh sky130A|gf180mcuD|ihp-sg13g2|icsprout55
set -euo pipefail
pdk="${1:?usage: $0 sky130A|gf180mcuD|ihp-sg13g2|icsprout55}"
here="$(cd "$(dirname "$0")/../.." && pwd)"
command -v librelane >/dev/null || { echo "error: librelane not on PATH" >&2; exit 1; }

src="$(python3 -c 'import librelane, os; print(os.path.dirname(librelane.__file__))')/examples/spm"
work="$here/work/spm-$pdk"
rm -rf "$work"
mkdir -p "$here/work"
cp -r "$src" "$work"

extra=(--pdk "$pdk")
case "$pdk" in
  icsprout55) extra+=(-c STD_CELL_LIBRARY=ics55_LLSC_H7CR -c CLOCK_PERIOD=10) ;;
esac

"$here/scripts/run_librelane.sh" "$work/config.yaml" "${extra[@]}"
gds=$(ls "$work"/runs/*/final/gds/*.gds | tail -1)
test -s "$gds" && echo "PASS: $gds"
