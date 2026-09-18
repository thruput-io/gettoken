#!/bin/bash
set -euo pipefail

root=$1
format=$2

candidates=$(mktemp)
selected=$(mktemp)
trap 'rm -f "$candidates" "$selected"' EXIT

find "$root" -path "$root/.git" -prune -o -path "$root/build" -prune -o -type f -print > "$candidates"

declares_bash_on_its_first_line() {
  case $(head -n 1 "$1") in
    '#!/bin/bash'|'# shellcheck shell=bash') return 0 ;;
  esac
  return 1
}

while IFS= read -r file; do
  if declares_bash_on_its_first_line "$file"; then printf '%s\n' "$file"; fi
done < "$candidates" > "$selected"

test -s "$selected"

shell_files=()
while IFS= read -r shell_file; do
  shell_files+=("$shell_file")
done < "$selected"

set +e
shellcheck -s bash -x "$format" "${shell_files[@]}"
reported=$?
set -e

if [ "$reported" -gt 1 ]; then
  echo "lint.sh: shellcheck could not run, exit $reported" >&2
  exit "$reported"
fi
