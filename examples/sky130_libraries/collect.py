#!/usr/bin/env python3
"""Write libraries.csv (pdk_scoring/inputs.csv columns) from the finished ALU
runs on the sky130 libraries and their report_modes.sh turbo results.
Prints each run's slack, area and signoff counts on stderr. Used by run.sh."""
import json
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parents[2]
RUNS = REPO / "examples/PPA-opt-32b-alu-bekiryy/librelane/runs"
MODES = REPO / "work/alu-modes"
LIBS = ("hd", "hs", "ms", "ls", "hdll")
# Cell classes counted as logic: no fill, tap, decap or antenna cells
LOGIC = ("sequential_cell", "multi_input_combinational_cell", "inverter", "buffer",
         "clock_buffer", "clock_inverter", "timing_repair_buffer")

print("pdk,node_nm,flow,can_tape_out,clock_ns,power_mw,logic_um2,pitch_um,pitch_layer,vdd_v,leakage_uw")
for lib in LIBS:
    name = f"sky130_fd_sc_{lib}"
    tag = f"sky130A-{name}"
    m = json.loads((RUNS / tag / "final/metrics.json").read_text())
    t = json.loads((MODES / f"{tag}-turbo.json").read_text())
    area = sum(v for k, v in m.items()
               if k.startswith("design__instance__area__class:") and k.split("class:")[1] in LOGIC)
    period = t["clock_period_s"] * 1e9
    print(f"{name},130,LibreLane,yes,{period:.4g},{t['power_total_w'] * 1e3:.4f},{area:.1f},0.34,met1,1.8,"
          f"{t['power_leakage_w'] * 1e6:.3f}")
    ws = min(m[f"timing__setup__ws__corner:{c}_tt_025C_1v80"] for c in ("min", "nom", "max"))
    print(f"{name}: {period:g} ns, worst typical setup slack {ws * 1000:+.0f} ps, "
          f"core {m['design__core__area']:,.0f} um2, utilization {100 * area / m['design__core__area']:.1f}%, "
          f"route DRC {m['route__drc_errors']}, Magic {m.get('magic__drc_error__count')}, "
          f"KLayout {m.get('klayout__drc_error__count')}, LVS {m.get('design__lvs_error__count')}",
          file=sys.stderr)
