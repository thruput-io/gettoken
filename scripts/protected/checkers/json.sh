#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/protected/checkers/common.sh
source "$(dirname "$0")/common.sh"

report=${1:?json.sh: name the report to check}

files=$(stat 'json files')
checked=$(wc -l < "$report" | tr -d ' ')
invalid=$(awk -F'\t' '$2 != "ok"' "$report" | wc -l | tr -d ' ')
echo "json: $invalid invalid (max $JSON_MAX_INVALID, $checked of $files json files checked)"
[ "$invalid" -le "$JSON_MAX_INVALID" ] && [ "$checked" -eq "$files" ]
