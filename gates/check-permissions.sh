#!/usr/bin/env bash
set -euo pipefail

umask 002

: "${1:?check-permissions.sh: name the roots to scan}"
roots=("$@")

candidates=$(mktemp)
trap 'rm -f "$candidates"' EXIT

find "${roots[@]}" -path "*/.git" -prune -o -path "*/build" -prune -o -path "*/.idea" -prune -o -path "*/.claude" -prune -o -type f -print > "$candidates"

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
