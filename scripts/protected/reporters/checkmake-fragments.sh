#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "${ROOT_DIR:?checkmake-fragments.sh: name the ROOT_DIR}/scripts/protected/reporters/common.sh"

report=${1:?checkmake-fragments.sh: name the report to write}
config=${2:?checkmake-fragments.sh: name the checkmake configuration}
mapfile -t files < <(tracked '*.mk')
checkmake --config="$config" -o json "${files[@]}" > "$report"
