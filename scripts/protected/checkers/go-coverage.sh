#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "${ROOT_DIR:?go-coverage.sh: name the ROOT_DIR}/scripts/protected/checkers/common.sh"

report=${1:?go-coverage.sh: name the report to check}

sources=$(stat 'go source files')
percent=$(grep '^total:' "$report" | grep -oE '[0-9.]+%$' | tr -d '%')
files=$(grep -v '^total:' "$report" | cut -d: -f1 | sort -u | wc -l | tr -d ' ')
echo "go-coverage: $percent% covered (floor $GO_COVERAGE_FLOOR%), $files of $sources go sources measured"
[ "${percent%.*}" -ge "$GO_COVERAGE_FLOOR" ] && [ "$files" -eq "$sources" ]
