#!/usr/bin/env bash
set -euo pipefail

root=${1:?check-branching.sh: name the tree to scan}
allowed=${2:?check-branching.sh: name the number of sites allowed}

branching=$(mktemp)
trap 'rm -f "$branching"' EXIT

find "$root/src" "$root/scripts" -name '*.bats' -print0 \
  | xargs -0 awk '
  /^[[:space:]]*(if|elif|case)[[:space:]]/          { print FILENAME ": branches" }
  /\$\{[A-Za-z_][A-Za-z0-9_]*:[-=+?]/               { print FILENAME ": defaults a variable" }
' | sort -u > "$branching"

found=$(wc -l < "$branching" | tr -d ' ')

cat "$branching"
echo "no-branching: $found sites branch or default in tests (allowed $allowed)"

test "$found" -le "$allowed"
