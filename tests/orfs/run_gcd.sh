#!/usr/bin/env bash
# Smoke test: run the gcd example through ORFS for one platform.
# Needs openroad, yosys and klayout on PATH (e.g. inside LibreLane's nix-shell).
#   tests/orfs/run_gcd.sh asap7|nangate45|gt2n|osu025
set -euo pipefail
platform="${1:?usage: $0 asap7|nangate45|gt2n|osu025}"
here="$(cd "$(dirname "$0")/../.." && pwd)"
source "$here/env.sh" >/dev/null
for t in openroad yosys klayout; do
  command -v "$t" >/dev/null || { echo "error: $t not on PATH" >&2; exit 1; }
done
cd "$ORFS_FLOW"
config="./designs/$platform/gcd/config.mk"
make DESIGN_CONFIG="$config" clean_all >/dev/null
make DESIGN_CONFIG="$config"
gds="results/$platform/gcd/base/6_final.gds"
test -s "$gds" && echo "PASS: $ORFS_FLOW/$gds"
