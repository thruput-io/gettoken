#!/usr/bin/env bash
set -euo pipefail

umask 002

inventory=${1:?permissions.sh: name the inventory to scan}

candidates=$(mktemp)
trap 'rm -f "$candidates"' EXIT

cut -f2 "$inventory" > "$candidates"

errors=0

while IFS= read -r file; do
  first_line=$(head -n 1 "$file")
  
  if [[ "$first_line" =~ ^#! ]]; then
    if [ ! -x "$file" ]; then
      echo "check-permissions: $file has shebang but is not executable" >&2
      errors=$((errors + 1))
    fi
  else
    if [ -x "$file" ]; then
      echo "check-permissions: $file does not have shebang but is executable" >&2
      errors=$((errors + 1))
    fi
  fi
done < "$candidates"

if [ "$errors" -ne 0 ]; then
  echo "check-permissions: $errors issue(s) found" >&2
  exit 1
fi

echo "check-permissions: 0 issues"
