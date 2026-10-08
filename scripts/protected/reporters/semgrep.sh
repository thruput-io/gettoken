#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "$(dirname "$0")/common.sh"

report=${2:?semgrep.sh: name the report to write}
mapfile -t files < <(files_of shell)
semgrep-bash --json-output="$report" "${files[@]}"
