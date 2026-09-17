#!/bin/bash
set -euo pipefail

report=$1
thresholds=$2

files=$(xmlstarlet sel -t -v 'count(//file)' "$report")
errors=$(xmlstarlet sel -t -v 'count(//error[@severity="error"])' "$report")
warnings=$(xmlstarlet sel -t -v 'count(//error[@severity="warning"])' "$report")

allowed_errors=$(jq -r '.lint.errors' "$thresholds")
allowed_warnings=$(jq -r '.lint.warnings' "$thresholds")

echo "lint: $files files, $errors errors (allowed $allowed_errors), $warnings warnings (allowed $allowed_warnings)"

test "$files" -ge 1
test "$errors" -le "$allowed_errors"
test "$warnings" -le "$allowed_warnings"
