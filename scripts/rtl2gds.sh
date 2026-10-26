#!/usr/bin/env bash
# RTL -> GDS on any PDK in this repo with one command. Writes the flow config
# for the PDK (LibreLane for fab PDKs, ORFS for the others) and runs it.
#
#   scripts/rtl2gds.sh --pdk <pdk> --top <module> --clock <port> --period <ns> \
#       [--sdc <file>] [--util <percent>] [--out <dir>] [--set KEY=VALUE ...] \
#       <rtl files...>
#
#   pdk: sky130A gf180mcuD ihp-sg13g2 icsprout55 nangate45 asap7 gt2n osu025
#
# --period is always in ns; it is converted for platforms that use ps. Without
# --sdc, a default SDC is used: the clock plus 20% input/output delays. Your own
# SDC is passed as-is, so it must use the PDK's time unit (ps on asap7 and
# gt2n, ns elsewhere). --util is the target core utilization (default 50).
# --set adds any LibreLane or ORFS variable. Needs LibreLane's tools on PATH
# (e.g. inside LibreLane's nix-shell).
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
usage() { sed -n '2,16s/^# \{0,1\}//p' "$0"; exit "${1:-1}"; }

pdk="" top="" clock="" period="" sdc="" util=50 out="" sets=() rtl=()
while [ $# -gt 0 ]; do
  case "$1" in
    --pdk) pdk="$2"; shift 2 ;;
    --top) top="$2"; shift 2 ;;
    --clock) clock="$2"; shift 2 ;;
    --period) period="$2"; shift 2 ;;
    --sdc) sdc="$(realpath "$2")"; shift 2 ;;
    --util) util="$2"; shift 2 ;;
    --out) out="$2"; shift 2 ;;
    --set) sets+=("$2"); shift 2 ;;
    -h|--help) usage 0 ;;
    -*) echo "error: unknown option $1" >&2; usage ;;
    *) rtl+=("$(realpath "$1")"); shift ;;
  esac
done
[ -n "$pdk" ] && [ -n "$top" ] && [ -n "$clock" ] && [ -n "$period" ] && [ ${#rtl[@]} -gt 0 ] || usage
for f in "${rtl[@]}" ${sdc:+"$sdc"}; do test -f "$f" || { echo "error: no file $f" >&2; exit 1; }; done
out="$(realpath -m "${out:-$here/work/rtl2gds/$top-$pdk}")"
mkdir -p "$out"

case "$pdk" in
  sky130A|sky130B|gf180mcu[A-D]|ihp-sg13g2|icsprout55)
    case "$pdk" in
      sky130*) lib=sky130_fd_sc_hd ;;
      gf180mcu*) lib=gf180mcu_fd_sc_mcu7t5v0 ;;
      ihp-sg13g2) lib=sg13g2_stdcell ;;
      icsprout55) lib=ics55_LLSC_H7CR ;;
    esac
    python3 - "$out/config.json" "$top" "$clock" "$period" "$util" "$lib" "$sdc" "${sets[@]}" -- "${rtl[@]}" <<'PY'
import json, sys
path, top, clock, period, util, lib, sdc, *rest = sys.argv[1:]
sep = rest.index("--")
cfg = {"DESIGN_NAME": top, "VERILOG_FILES": rest[sep + 1:], "CLOCK_PORT": clock,
       "CLOCK_PERIOD": float(period), "FP_CORE_UTIL": float(util),
       "PL_TARGET_DENSITY_PCT": min(float(util) + 10, 95), "STD_CELL_LIBRARY": lib}
if sdc:
    cfg["PNR_SDC_FILE"] = cfg["SIGNOFF_SDC_FILE"] = sdc
for kv in rest[:sep]:
    k, v = kv.split("=", 1)
    try:
        cfg[k] = json.loads(v)
    except ValueError:
        cfg[k] = v
json.dump(cfg, open(path, "w"), indent=2)
PY
    rm -rf "$out/runs/rtl2gds"
    "$here/scripts/run_librelane.sh" "$out/config.json" --pdk "$pdk" --run-tag rtl2gds
    gds=$(ls "$out"/runs/rtl2gds/final/gds/*.gds | head -1)
    ;;
  nangate45|asap7|gt2n|osu025)
    source "$here/env.sh" >/dev/null
    case "$pdk" in
      asap7|gt2n) clk_period=$(python3 -c "print(round($period * 1000, 3))") ;;
      *) clk_period="$period" ;;
    esac
    if [ -z "$sdc" ]; then
      sdc="$out/constraint.sdc"
      cat > "$sdc" <<EOF
# Default constraints from rtl2gds.sh (period in the platform's time unit)
create_clock -name clk -period $clk_period [get_ports {$clock}]
set inputs [delete_from_list [all_inputs] [get_ports {$clock}]]
set_input_delay [expr {0.2 * $clk_period}] -clock clk \$inputs
set_output_delay [expr {0.2 * $clk_period}] -clock clk [all_outputs]
EOF
    fi
    {
      echo "# Written by rtl2gds.sh"
      echo "export DESIGN_NICKNAME = $top"
      echo "export DESIGN_NAME = $top"
      echo "export PLATFORM = $pdk"
      echo "export VERILOG_FILES = ${rtl[*]}"
      echo "export SDC_FILE = $sdc"
      echo "export CORE_UTILIZATION = $util"
      echo "export PLACE_DENSITY ?= $(python3 -c "print(round(min($util / 100 + 0.1, 0.95), 2))")"
      if [ "$pdk" = gt2n ]; then
        # GT2N's PDN straps need a core at least ~40 um wide; small designs
        # need a low --util (see tests/orfs/gt2n).
        echo "export CORE_ASPECT_RATIO = 1"
        echo "export CORE_MARGIN = 5.04"
      fi
      for kv in "${sets[@]}"; do echo "export ${kv%%=*} = ${kv#*=}"; done
      if [ "$pdk" = gt2n ]; then
        echo "include \$(dir \$(firstword \$(MAKEFILE_LIST)))platforms/gt2n/all_free_pdks_w31_svtlvt.mk"
      fi
    } > "$out/config.mk"
    cd "$ORFS_FLOW"
    make DESIGN_CONFIG="$out/config.mk" clean_all >/dev/null
    make DESIGN_CONFIG="$out/config.mk"
    gds="$ORFS_FLOW/results/$pdk/$top/base/6_final.gds"
    ;;
  *) echo "error: unknown PDK $pdk" >&2; usage ;;
esac
test -s "$gds" && echo "PASS: $gds"
