#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/reporters/common.sh
source "${ROOT_DIR:?shellcheck.sh: name the ROOT_DIR}/scripts/reporters/common.sh"

report=${1:?shellcheck.sh: name the report to write}
mapfile -t files < <(shell_files)
shellcheck -x -f json "${files[@]}" > "$report"
