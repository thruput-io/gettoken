#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "$(dirname "$0")/common.sh"

report=${1:?inventory.sh: name the report to check}

files=$(wc -l < "$report" | tr -d ' ')
unlinted=$(stat 'unlinted files')
echo "inventory: $unlinted of $files files have no linter (max $UNLINTED_MAX)"
[ "$unlinted" -le "$UNLINTED_MAX" ]
