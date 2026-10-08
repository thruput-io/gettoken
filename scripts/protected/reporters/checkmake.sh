#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/reporters/common.sh
source "$(dirname "$0")/common.sh"

report=${2:?checkmake.sh: name the report to write}
linter=${3:?checkmake.sh: name the make linter class to check}
config=${4:?checkmake.sh: name the checkmake configuration}
mapfile -t files < <(files_of "$linter")
checkmake --config="$config" -o json "${files[@]}" > "$report"
