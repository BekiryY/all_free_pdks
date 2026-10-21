#!/usr/bin/env bash
# Report turbo and low-power timing/power of a finished ALU run (run.sh first).
# Same layout, two operating modes: low-power mode uses a clock 9.22x slower,
# the original design's 1.66 GHz / 180 MHz ratio. Needs openroad on PATH.
#   examples/PPA-opt-32b-alu-bekiryy/scripts/report_modes.sh <pdk>
set -euo pipefail
pdk="${1:?usage: $0 <pdk>}"
alu="$(cd "$(dirname "$0")/.." && pwd)"
repo="$(cd "$alu/../.." && pwd)"
source "$repo/env.sh" >/dev/null
out_dir="$repo/work/alu-modes"
mkdir -p "$out_dir"
export ALU_SDC="$alu/constraints/alu.sdc" ALU_RC_LAYER=""

case "$pdk" in
  sky130A|gf180mcuD|ihp-sg13g2|icsprout55)
    run=$(ls -td "$alu"/librelane/runs/*/ | head -1)
    eval "$(python3 - "$run" <<'PY'
import fnmatch, glob, json, sys
run = sys.argv[1]
c = json.load(open(run + "resolved.json"))
corner = c["DEFAULT_CORNER"]
libs = next(v for k, v in c["LIB"].items() if fnmatch.fnmatch(corner, k))
spef = sorted(glob.glob(run + "final/spef/nom*/*.spef") + glob.glob(run + "final/spef/*.spef"))
print(f'export ALU_LIBS="{" ".join(libs)}"')
print(f'export ALU_ODB="{glob.glob(run + "final/odb/*.odb")[0]}"')
print(f'export ALU_SPEF="{spef[0] if spef else ""}"')
print(f'period={c["CLOCK_PERIOD"]}')
print(f'export ALU_RC_LAYER="{c.get("DATA_WIRE_RC_LAYER") or ""}"')
PY
)"
    export CLOCK_PERIOD="$period"
    ;;
  nangate45|asap7|gt2n|osu025)
    base="$ORFS_FLOW/results/$pdk/alu/base"
    export ALU_LIBS="$(make -s -C "$ORFS_FLOW" DESIGN_CONFIG="$alu/orfs/$pdk/config.mk" print-LIB_FILES \
      | sed -n 's/^LIB_FILES *[:=] *//p')"
    export ALU_ODB="$base/6_final.odb" ALU_SPEF="$base/6_final.spef"
    [ -f "$ALU_SPEF" ] || ALU_SPEF=""
    period=$(sed -n 's/^export ALU_CLOCK_PERIOD = //p' "$alu/orfs/$pdk/config.mk")
    export ALU_CLOCK_PERIOD="$period"
    ;;
  *) echo "error: unknown PDK $pdk" >&2; exit 1 ;;
esac
export ALU_LP_CLOCK_PERIOD=$(python3 -c "print(round($period * 9.22, 4))")

for mode in turbo lowpower; do
  export ALU_MODE=$mode ALU_OUT="$out_dir/$pdk-$mode.json"
  openroad -no_splash -exit "$alu/scripts/mode_sta.tcl" > "$out_dir/$pdk-$mode.log" 2>&1 \
    || { echo "error: see $out_dir/$pdk-$mode.log" >&2; exit 1; }
  echo "$mode: $(tr -d '\n' < "$ALU_OUT")"
done
