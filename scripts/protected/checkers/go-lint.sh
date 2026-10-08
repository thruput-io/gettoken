#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "$(dirname "$0")/common.sh"

report=${1:?go-lint.sh: name the report to check}

files=$(stat 'go source files')
issues=$(jq -s '[.[] | .[] | .[] | .[]] | length' "$report")
echo "go vet: $issues issues (max $GO_VET_MAX_ISSUES, $files go files scanned, min $GO_SOURCE_FILES_MIN)"
[ "$issues" -le "$GO_VET_MAX_ISSUES" ] && [ "$files" -ge "$GO_SOURCE_FILES_MIN" ]
