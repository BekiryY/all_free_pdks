#!/usr/bin/env bash
# Run the ALU from RTL to GDS on one PDK, optionally with another standard
# cell library. Needs librelane (fab PDKs) or openroad/yosys/klayout (others)
# on PATH, e.g. inside LibreLane's nix-shell.
#   examples/PPA-opt-32b-alu-bekiryy/run.sh <pdk>[/<library>]
#   pdk: sky130A gf180mcuD ihp-sg13g2 icsprout55 nangate45 asap7 gt2n osu025
#   library (fab PDKs): a full name, or a short one: sky130A/hs is
#   sky130_fd_sc_hs, gf180mcuD/9t5v0 is gf180mcu_fd_sc_mcu9t5v0
# Several at once, sized to the machine: scripts/batch.py (see its header).
set -euo pipefail
target="${1:?usage: $0 <pdk>[/<library>]}"
shift
pdk="${target%%/*}" lib=""
[ "$target" = "$pdk" ] || lib="${target#*/}"
alu="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$alu/../.." && pwd)"

case "$pdk" in
  sky130A|gf180mcuD|ihp-sg13g2|icsprout55)
    tag="$pdk" scl=()
    if [ -n "$lib" ]; then
      case "$pdk:$lib" in
        *_*) ;;
        sky130*) lib="sky130_fd_sc_$lib" ;;
        gf180mcu*) lib="gf180mcu_fd_sc_mcu$lib" ;;
        icsprout55:*) lib="ics55_LLSC_$lib" ;;
      esac
      tag="$pdk-$lib" scl=(--scl "$lib")
    fi
    "$repo/scripts/run_librelane.sh" "$alu/librelane/config.yaml" --pdk "$pdk" "${scl[@]}" \
      --run-tag "$tag" --overwrite "$@"
    gds=$(ls "$alu"/librelane/runs/"$tag"/final/gds/*.gds | head -1)
    ;;
  nangate45|asap7|gt2n|osu025)
    [ -z "$lib" ] || { echo "error: $pdk: library choice is not supported for ORFS PDKs" >&2; exit 1; }
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
