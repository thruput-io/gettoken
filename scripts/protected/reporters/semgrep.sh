#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "${ROOT_DIR:?semgrep.sh: name the ROOT_DIR}/scripts/protected/reporters/common.sh"

report=${1:?semgrep.sh: name the report to write}
mapfile -t files < <(shell_files)
semgrep-bash --json-output="$report" "${files[@]}"
