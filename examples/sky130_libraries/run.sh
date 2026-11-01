#!/usr/bin/env bash
# The ALU on sky130's five cell libraries in parallel, each at its own edge
# clock (the scl:: blocks of the ALU's librelane/config.yaml), then the power
# reports, libraries.csv and the PPA chart (ppa.svg).
# Needs the extra libraries (install_pdks.py --only sky130 --extra-libs) and
# LibreLane's tools on PATH. Arguments go to scripts/batch.py, e.g. --threads 8.
#   examples/sky130_libraries/run.sh [batch.py options]
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
alu="$repo/examples/PPA-opt-32b-alu-bekiryy"
targets=(sky130A/hd sky130A/hs sky130A/ms sky130A/ls sky130A/hdll)

python3 "$repo/scripts/batch.py" "$@" "$alu/run.sh" ::: "${targets[@]}"
for t in "${targets[@]}"; do
  "$alu/scripts/report_modes.sh" "$t" >/dev/null
done
python3 "$here/collect.py" > "$here/libraries.csv"
python3 "$repo/pdk_scoring/score.py" --libraries "$here/libraries.csv"
