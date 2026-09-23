#!/usr/bin/env bash
set -euo pipefail

report=$1
allowed_errors=${2:-0}
allowed_warnings=${3:-0}

files=$(xmlstarlet sel -t -v 'count(//file)' "$report")
errors=$(xmlstarlet sel -t -v 'count(//error[@severity="error"])' "$report")
warnings=$(xmlstarlet sel -t -v 'count(//error[@severity="warning"])' "$report")

echo "lint: $files files, $errors errors (allowed $allowed_errors), $warnings warnings (allowed $allowed_warnings)"

test "$files" -ge 1
test "$errors" -le "$allowed_errors"
test "$warnings" -le "$allowed_warnings"
