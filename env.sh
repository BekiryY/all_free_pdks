# Source this file to point LibreLane and other tools at the installed PDKs:
#   source env.sh
_afp_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
export PDK_ROOT="$_afp_dir/pdks"
# PDK and standard cell library come from each design's config.
unset PDK STD_CELL_LIBRARY
unset _afp_dir
echo "PDK_ROOT=$PDK_ROOT"
