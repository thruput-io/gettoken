#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "$(dirname "$0")/common.sh"

report=${2:?shellcheck.sh: name the report to write}
mapfile -t files < <(files_of shell)
shellcheck --norc -x -f json "${files[@]}" > "$report"
