#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "${ROOT_DIR:?semgrep.sh: name the ROOT_DIR}/scripts/protected/checkers/common.sh"

report=${1:?semgrep.sh: name the report to check}

files=$(stat 'shell files')
findings=$(jq '.results | length' "$report")
unparsed=$(jq '.errors | length' "$report")
scanned=$(jq '.paths.scanned | length' "$report")
echo "semgrep: $findings findings, $unparsed files not fully parsed (max $SEMGREP_MAX_FINDINGS/$SEMGREP_MAX_UNPARSED, $scanned of $files shell files scanned)"
[ "$findings" -le "$SEMGREP_MAX_FINDINGS" ] && [ "$unparsed" -le "$SEMGREP_MAX_UNPARSED" ] && [ "$scanned" -eq "$files" ] && [ "$files" -ge "$SHELL_FILES_MIN" ]
