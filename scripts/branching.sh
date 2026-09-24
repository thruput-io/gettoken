#!/usr/bin/env bash
set -euo pipefail

root=${1:?branching.sh: name the tree to scan}

find "$root/src" "$root/scripts" -name '*.bats' -print0 \
  | xargs -0 awk '
  /^[[:space:]]*(if|elif|case)[[:space:]]/          { print FILENAME ": branches" }
  /\$\{[A-Za-z_][A-Za-z0-9_]*:[-=+?]/               { print FILENAME ": defaults a variable" }
' | sort -u
