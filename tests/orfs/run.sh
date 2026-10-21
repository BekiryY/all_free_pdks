#!/usr/bin/env bash
# Run an example design through ORFS for one platform (default design: gcd).
# Needs openroad, yosys and klayout on PATH (e.g. inside LibreLane's nix-shell).
#   tests/orfs/run.sh asap7|nangate45|gt2n|osu025 [gcd|aes]
set -euo pipefail
platform="${1:?usage: $0 asap7|nangate45|gt2n|osu025 [design]}"
design="${2:-gcd}"
here="$(cd "$(dirname "$0")/../.." && pwd)"
source "$here/env.sh" >/dev/null
for t in openroad yosys klayout; do
  command -v "$t" >/dev/null || { echo "error: $t not on PATH" >&2; exit 1; }
done
cd "$ORFS_FLOW"
config="./designs/$platform/$design/config.mk"
test -f "$config" || { echo "error: no $config" >&2; exit 1; }
make DESIGN_CONFIG="$config" clean_all >/dev/null
make DESIGN_CONFIG="$config"
gds="results/$platform/$design/base/6_final.gds"
test -s "$gds" && echo "PASS: $ORFS_FLOW/$gds"
