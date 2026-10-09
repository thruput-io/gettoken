#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "${ROOT_DIR:?bash-coverage.sh: name the ROOT_DIR}/scripts/protected/checkers/common.sh"

report=${1:?bash-coverage.sh: name the report to check}

sources=$(stat 'bash coverage sources')
percent=$(jq -r '.percent_covered' "$report")
files=$(jq -r '.files | length' "$report")
echo "bash-coverage: $percent% covered (floor $BASH_COVERAGE_FLOOR%), $files of $sources bash sources under src/ measured"
[ "${percent%.*}" -ge "$BASH_COVERAGE_FLOOR" ] && [ "$files" -eq "$sources" ]
