#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "${ROOT_DIR:?no-branching.sh: name the ROOT_DIR}/scripts/protected/checkers/common.sh"

report=${1:?no-branching.sh: name the report to check}

files=$(stat 'bats test files')
sites=$(wc -l < "$report" | tr -d ' ')
echo "no-branching: $sites sites branch or default in tests (max $BRANCHING_MAX_SITES, $files test files scanned, min $BATS_TEST_FILES_MIN)"
[ "$sites" -le "$BRANCHING_MAX_SITES" ] && [ "$files" -ge "$BATS_TEST_FILES_MIN" ]
