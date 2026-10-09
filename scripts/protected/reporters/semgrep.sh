#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "${ROOT_DIR:?semgrep.sh: name the ROOT_DIR}/scripts/protected/reporters/common.sh"

report=${2:?semgrep.sh: name the report to write}
mapfile -t files < <(files_of shell)
semgrep-bash --json-output="$report" "${files[@]}"
