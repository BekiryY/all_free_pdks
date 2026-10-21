#!/usr/bin/env bash
# Run LibreLane on your own design with this repo's PDKs.
#   scripts/run_librelane.sh path/to/config.{json,yaml} [extra librelane args]
# Needs `librelane` on PATH (e.g. inside LibreLane's nix-shell). The PDK comes
# from the config's "PDK" key, or from `--pdk <name>` among the extra args.
set -euo pipefail
config="${1:?usage: $0 <config.json|yaml> [librelane args]}"
shift
here="$(cd "$(dirname "$0")/.." && pwd)"
source "$here/env.sh" >/dev/null
command -v librelane >/dev/null || { echo "error: librelane not on PATH" >&2; exit 1; }

pdk=""
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[$i]}" in
    -p|--pdk) pdk="${args[$((i + 1))]:-}" ;;
    --pdk=*) pdk="${args[$i]#--pdk=}" ;;
  esac
done
if [ -z "$pdk" ]; then
  pdk=$(grep -oE '"?PDK"?[[:space:]]*:[[:space:]]*"?[A-Za-z0-9_-]+' "$config" | head -1 | sed -E 's/.*:[[:space:]]*"?//')
fi

extra=()
case "$pdk" in
  icsprout55)
    # Not managed by ciel. The PDK ships no Magic tech, Netgen setup, RC
    # extraction rules or LEF antenna data, so those steps are skipped.
    extra=(--manual-pdk
      -S OpenROAD.RCX -S OpenROAD.STAPostPNR
      -S Magic.StreamOut -S Magic.WriteLEF -S Magic.DRC -S Magic.SpiceExtraction
      -S Netgen.LVS -S Odb.CheckDesignAntennaProperties)
    ;;
esac

cd "$(dirname "$config")"
exec librelane --pdk-root "$PDK_ROOT" "${extra[@]}" "$@" "$(basename "$config")"
