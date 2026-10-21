#!/usr/bin/env bash
# Run the ALU from RTL to GDS on one PDK.
# Needs librelane (fab PDKs) or openroad/yosys/klayout (others) on PATH,
# e.g. inside LibreLane's nix-shell.
#   examples/PPA-opt-32b-alu-bekiryy/run.sh <pdk>
#   pdk: sky130A gf180mcuD ihp-sg13g2 icsprout55 nangate45 asap7 gt2n osu025
set -euo pipefail
pdk="${1:?usage: $0 sky130A|gf180mcuD|ihp-sg13g2|icsprout55|nangate45|asap7|gt2n|osu025}"
shift
alu="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$alu/../.." && pwd)"

case "$pdk" in
  sky130A|gf180mcuD|ihp-sg13g2|icsprout55)
    "$repo/scripts/run_librelane.sh" "$alu/librelane/config.yaml" --pdk "$pdk" "$@"
    gds=$(ls -t "$alu"/librelane/runs/*/final/gds/*.gds | head -1)
    ;;
  nangate45|asap7|gt2n|osu025)
    source "$repo/env.sh" >/dev/null
    config="$alu/orfs/$pdk/config.mk"
    cd "$ORFS_FLOW"
    make DESIGN_CONFIG="$config" clean_all >/dev/null
    make DESIGN_CONFIG="$config" "$@"
    gds="$ORFS_FLOW/results/$pdk/alu/base/6_final.gds"
    ;;
  *) echo "error: unknown PDK $pdk" >&2; exit 1 ;;
esac
test -s "$gds" && echo "PASS: $gds"
