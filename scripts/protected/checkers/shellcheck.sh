#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "$(dirname "$0")/common.sh"

report=${1:?shellcheck.sh: name the report to check}

files=$(stat 'shell files')
findings=$(jq 'length' "$report")
echo "shellcheck: $findings findings (max $SHELLCHECK_MAX_FINDINGS, $files shell files scanned, min $SHELL_FILES_MIN)"
[ "$findings" -le "$SHELLCHECK_MAX_FINDINGS" ] && [ "$files" -ge "$SHELL_FILES_MIN" ]
