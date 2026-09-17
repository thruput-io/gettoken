#!/bin/bash
set -euo pipefail

root=$1
thresholds=$2

branching=$(mktemp)
trap 'rm -f "$branching"' EXIT

find "$root/src" "$root/scripts" -name '*.bats' -print0 \
  > "$branching.files"
find "$root" -maxdepth 1 \( -name 'config*.sh' -o -name 'config*.example' \) -print0 \
  >> "$branching.files"
trap 'rm -f "$branching" "$branching.files"' EXIT

xargs -0 awk '
  /^[[:space:]]*(if|elif|case)[[:space:]]/          { print FILENAME ": branches" }
  /\$\{[A-Za-z_][A-Za-z0-9_]*:[-=+?]/               { print FILENAME ": defaults a variable" }
' < "$branching.files" | sort -u > "$branching"

found=$(wc -l < "$branching" | tr -d ' ')
allowed=$(jq -r '."no-branching".sites' "$thresholds")

cat "$branching"
echo "no-branching: $found sites branch or default in tests or configuration (allowed $allowed)"

test "$found" -le "$allowed"
