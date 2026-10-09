#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "${ROOT_DIR:?shellcheck.sh: name the ROOT_DIR}/scripts/protected/reporters/common.sh"

report=${1:?shellcheck.sh: name the report to write}
mapfile -t files < <(shell_files)
shellcheck --norc -x -f json "${files[@]}" > "$report"
