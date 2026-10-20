# Source this file to point LibreLane, ORFS and other tools at the installed PDKs:
#   source env.sh
_afp_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
export PDK_ROOT="$_afp_dir/pdks"
# PDK and standard cell library come from each design's config.
unset PDK STD_CELL_LIBRARY

# OpenROAD-flow-scripts (asap7, nangate45, gt2n, osu025): run `make` in
# $ORFS_FLOW with openroad/yosys/klayout on PATH (e.g. inside LibreLane's
# nix-shell). LEC needs ORFS's own kepler-formal build, and headless runs
# need an offscreen Qt platform for the final images.
export ORFS_FLOW="$PDK_ROOT/orfs/flow"
export LEC_CHECK=0
export QT_QPA_PLATFORM=offscreen
command -v openroad >/dev/null && export OPENROAD_EXE="$(command -v openroad)"
command -v yosys >/dev/null && export YOSYS_EXE="$(command -v yosys)"
command -v klayout >/dev/null && export KLAYOUT_CMD="$(command -v klayout)"

unset _afp_dir
echo "PDK_ROOT=$PDK_ROOT"
